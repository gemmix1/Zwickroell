// ============================================================
//  Messprogramm v4 — Kontakt-Mikrometer, EIN DC-Motor + Servo
//  ------------------------------------------------------------
//  Prinzip: DC-Motor + Encoder + M8-Spindel = Mikrometerschraube
//           (1.25 mm / 4200 Counts = 0.298 um/Count).
//           Federgelagerter Taststift + MIKROSCHALTER taste't die
//           Probe von oben an; Encoder liest die Kontaktposition.
//           SERVO dreht die Probe -> dieselbe Achse misst Dicke UND Breite.
//
//  Messung (zentrierungs-unempfindlich, Sum-of-two-touches):
//     Dicke  t = |2C - (Z0   + Z180)| * k
//     Breite w = |2C - (Z90  + Z270)| * k        (270-Grad-Servo)
//  2C wird EINMAL mit einem Endmass bekannter Dicke kalibriert ('k').
//
//  180-Grad-Servo (z.B. SG90): kein 270 moeglich -> Breite ueber
//     zentrierte Probe: w = |2C - 2*Z90| * k  (USE_270_SERVO = 0).
//
//  Serielle Befehle:
//     m -> messen (N Paesse) -> DICKE/BREITE als Mittelwert +/- Stdabw.
//     k -> 2C kalibrieren: Endmass (KNOWN_GAUGE) einspannen, 'k' senden
//     t -> Einzel-Antastung testen (Debug)
//     s -> Servo die 4 (bzw. 3) Positionen abfahren (Justage/Detent)
//     ? -> Hilfe / Kalibrierwert
// ============================================================

#include <Servo.h>
#include <EEPROM.h>
#include <limits.h>
#include "DualMAX14870MotorShield.h"

DualMAX14870MotorShield motoren;
Servo dreher;

// ---------- PINS ----------
const int encoderA = 2;    // Interrupt
const int encoderB = 3;    // Interrupt
const int TASTER    = A0;  // Mikroschalter -> GND (INPUT_PULLUP, LOW = Kontakt)
const int SERVO_PIN = 6;   // frei (Shield belegt 4,7,8,9,10,12)

// ---------- KONFIG ----------
#define USE_270_SERVO 0    // 0 = SG90 180-Grad (Breite ueber zentrierte Klemme)

// ---------- MECHANIK / ENCODER ----------
const long   CPR          = 4200;              // 7 PPR x 4 x 150
// ============================================================================
// SPINDELSTEIGUNG mm/Umdrehung — MUSS zur eingebauten Spindel passen,
// sonst sind ALLE Masse um diesen Faktor falsch!
//   1.0  = deine M8-Feingewinde-Stange (M8x1)
//   1.25 = normale M8-Gewindestange (Standard-Steigung! pruefen!)
//   2.0  = bestellte T8x2-Trapezspindel  |  8.0 = T8x8
// PRUEFTEST: Spindel exakt 10 Umdrehungen drehen und Weg messen:
//   10 mm -> 1.0 | 12,5 mm -> 1.25 | 20 mm -> 2.0
// ============================================================================
const float  STEIGUNG     = 2.0;               // = bestellte T8x2 (1mm-Spindeln
                                               //   liefern erst im August!)
const float  MM_PRO_COUNT = STEIGUNG / CPR;    // bei 2.0: ~0.00048 mm/Count
const int    DIM_SIGN     = +1;                // falls Mass negativ: auf -1 setzen

// ---------- ANTASTEN ----------
const int    SPEED_FAST   = 130;               // schnelle Anfahrt (Richtung Probe)
const int    SPEED_SLOW   = 45;                // langsame Feinantastung
const long   BACKOFF      = (long)(0.8 / MM_PRO_COUNT);  // Rueckzug vor Feinantastung
const long   RETRACT      = (long)(5.0 / MM_PRO_COUNT);  // Rueckzug nach Kontakt
                                                          // (>= 5mm: Probe muss beim
                                                          //  Drehen frei schwenken!)
const long   MAX_TRAVEL   = (long)(25.0/ MM_PRO_COUNT);  // Sicherheits-Grenze
// MESSVORGABE: jede Seite wird 3x angetastet, verwendet wird der MITTELWERT.
const int    N_TOUCH      = 3;
// Komplette Wiederholungen des Gesamtablaufs (1 = eine Messung mit je 3
// Antastungen pro Seite; hoeher stellen, wenn zusaetzlich die Streuung (+/-)
// ueber mehrere Durchlaeufe ermittelt werden soll)
const int    N_PASSES     = 1;

// ---------- SERVO-POSITIONEN (us) — SG90 180-Grad, an Detent justieren ----------
const int    SERVO_0   = 500;    // 0 Grad
const int    SERVO_90  = 1450;   // 90 Grad (SG90 ~500..2400 us)
const int    SERVO_180 = 2400;   // 180 Grad
const int    SERVO_270 = 2400;   // (bei SG90 ungenutzt)
const int    SERVO_SETTLE = 500;               // ms Beruhigung nach Drehung

// ---------- KALIBRIER-ENDMASSE ----------
const float  KNOWN_GAUGE  = 6.000;             // wahre Dicke  des Dicken-Endmasses  ('k')
const float  KNOWN_BREITE = 12.000;            // wahre Breite des Breiten-Endmasses ('w')

// ---------- EEPROM ----------
const int    EE_MAGIC_ADDR = 0;  const byte EE_MAGIC = 0x6D;
const int    EE_2C_ADDR    = 1;  // long (Counts)
const int    EE_BOFF_ADDR  = 5;  // float (mm)
long  twoC = 0;                   // Kalibrier-Konstante (Counts), via 'k'
float breiteOff = 0.0;            // Breiten-Offset (mm), via 'w' — kompensiert den
                                  // konstanten Klemm-Versatz (Klemmschraube!)

// ---------- ENCODER ----------
volatile long pulseCount = 0;
volatile uint8_t letzterZustand = 0;
const int8_t QUAD[16] = { 0,-1,1,0, 1,0,0,-1, -1,0,0,1, 0,1,-1,0 };
void encoderUpdate() {
  uint8_t a=digitalRead(encoderA), b=digitalRead(encoderB);
  uint8_t z=(a<<1)|b;
  pulseCount += QUAD[((letzterZustand<<2)|z) & 0x0F];
  letzterZustand=z;
}
long pos() { long c; noInterrupts(); c=pulseCount; interrupts(); return c; }

bool kontakt() { return digitalRead(TASTER)==LOW; }
void stop()    { motoren.setM1Speed(0); }

// ---------- Spindel um dCounts fahren (Vorzeichen = Richtung) ----------
void fahre(long dCounts, int speed) {
  long ziel = pos() + dCounts;
  if (dCounts >= 0) { motoren.setM1Speed(abs(speed));  while (pos() < ziel) {} }
  else              { motoren.setM1Speed(-abs(speed)); while (pos() > ziel) {} }
  stop();
}

// ---------- EINE Antastung: nach unten bis Kontakt, Position zurueck ----------
// Rueckgabe: Encoder-Count bei Kontakt. Immer aus derselben Richtung -> Backlash konsistent.
// Konvention: +SPEED bewegt den Taster RICHTUNG Probe.
long tasteEinmal() {
  long start = pos();
  // 1) schnelle Anfahrt bis Grobkontakt
  motoren.setM1Speed(SPEED_FAST);
  while (!kontakt() && (pos()-start) < MAX_TRAVEL) {}
  stop();
  if (!kontakt()) { return LONG_MIN; }          // nichts getroffen
  // 2) zurueck und langsam final antasten (praezise, kraftarm)
  fahre(-BACKOFF, SPEED_FAST);
  motoren.setM1Speed(SPEED_SLOW);
  while (!kontakt() && (pos()) < start+MAX_TRAVEL) {}
  long p = pos();
  stop();
  // 3) freifahren
  fahre(-RETRACT, SPEED_FAST);
  return p;
}

// N Antastungen mitteln
long tasteGemittelt(bool &ok) {
  long summe=0; int n=0;
  for (int i=0;i<N_TOUCH;i++){ long p=tasteEinmal(); if(p!=LONG_MIN){summe+=p; n++;} }
  ok = (n>0); return ok ? summe/n : 0;
}

// Servo bewegen; fuer die Antastung wird der Servo ABGESCHALTET (detach):
// der federnde RASTBOLZEN zieht den Klemmen-Flansch exakt ins 0/90/180-Loch.
// (Servo-Winkelfehler geht sonst LINEAR in das Mass ein - Kantenkontakt!)
void servoZu(int us) {
  if (!dreher.attached()) dreher.attach(SERVO_PIN);
  dreher.writeMicroseconds(us);
  delay(SERVO_SETTLE);
}
long messePos(int us, bool &ok) {
  servoZu(us);
  dreher.detach();            // schlaff -> Rastbolzen definiert den Winkel
  delay(300);
  return tasteGemittelt(ok);
}

// ---------- EIN PASS: Dicke + Breite ----------
bool einPass(float &dicke, float &breite) {
  bool o1,o2,o3,o4;
  long z0   = messePos(SERVO_0,   o1);
  long z180 = messePos(SERVO_180, o2);
#if USE_270_SERVO
  long z90  = messePos(SERVO_90,  o3);
  long z270 = messePos(SERVO_270, o4);
  if(!(o1&&o2&&o3&&o4)) return false;
  long rawT = z0 + z180;
  long rawW = z90 + z270;
  dicke  = DIM_SIGN * (twoC - rawT) * MM_PRO_COUNT;
  breite = DIM_SIGN * (twoC - rawW) * MM_PRO_COUNT;
#else
  long z90  = messePos(SERVO_90,  o3); o4=true;
  if(!(o1&&o2&&o3)) return false;
  long rawT = z0 + z180;
  dicke  = DIM_SIGN * (twoC - rawT)      * MM_PRO_COUNT;   // 0+180 (versatz-frei)
  breite = DIM_SIGN * (twoC - 2L*z90)    * MM_PRO_COUNT + breiteOff;  // 'w'-kalibriert
#endif
  servoZu(SERVO_0); dreher.detach();
  if (dicke<0)  dicke=-dicke;
  if (breite<0) breite=-breite;
  return true;
}

// ---------- MESSEN mit Statistik ----------
void messen(float &dMw,float &dSd,float &bMw,float &bSd,int &ok){
  float ds[8], bs[8]; ok=0;
  for(int p=0;p<N_PASSES;p++){ float d,b; if(einPass(d,b)){ds[ok]=d;bs[ok]=b;ok++;} }
  dMw=dSd=bMw=bSd=0; if(!ok) return;
  for(int i=0;i<ok;i++){dMw+=ds[i];bMw+=bs[i];} dMw/=ok;bMw/=ok;
  for(int i=0;i<ok;i++){dSd+=sq(ds[i]-dMw);bSd+=sq(bs[i]-bMw);}
  dSd=sqrt(dSd/ok); bSd=sqrt(bSd/ok);
}

// ---------- KALIBRIERUNG 2C ----------
// Endmass bekannter Dicke einspannen. 2C so setzen, dass |2C-rawT|*k = KNOWN_GAUGE.
void kalibriere(){
  bool o1,o2; long z0=messePos(SERVO_0,o1); long z180=messePos(SERVO_180,o2);
  servoZu(SERVO_0); dreher.detach();
  if(!(o1&&o2)){ Serial.println(F("Kalibrieren fehlgeschlagen (kein Kontakt).")); return; }
  long rawT = z0+z180;
  twoC = rawT + (long)(DIM_SIGN * KNOWN_GAUGE / MM_PRO_COUNT);
  EEPROM.update(EE_MAGIC_ADDR, EE_MAGIC); EEPROM.put(EE_2C_ADDR, twoC);
  Serial.print(F("Kalibriert. 2C=")); Serial.println(twoC);
}

// Breite kalibrieren: Endmass bekannter Breite (KNOWN_BREITE) einspannen -> 'w'.
// Kompensiert den konstanten Versatz der Klemmung (Klemmschraube muss dabei
// genauso angezogen sein wie bei echten Messungen!).
void kalibriereBreite(){
  if(twoC==0){ Serial.println(F("Erst 'k' kalibrieren.")); return; }
  float dMw,dSd,bMw,bSd; int ok; messen(dMw,dSd,bMw,bSd,ok);
  if(!ok){ Serial.println(F("Breiten-Kalibrierung fehlgeschlagen.")); return; }
  breiteOff += (KNOWN_BREITE - bMw);
  EEPROM.put(EE_BOFF_ADDR, breiteOff);
  Serial.print(F("Breite kalibriert. Offset=")); Serial.println(breiteOff,4);
}

void setup(){
  Serial.begin(9600);
  pinMode(encoderA,INPUT_PULLUP); pinMode(encoderB,INPUT_PULLUP);
  pinMode(TASTER,INPUT_PULLUP);
  letzterZustand=(digitalRead(encoderA)<<1)|digitalRead(encoderB);
  attachInterrupt(digitalPinToInterrupt(encoderA),encoderUpdate,CHANGE);
  attachInterrupt(digitalPinToInterrupt(encoderB),encoderUpdate,CHANGE);
  dreher.attach(SERVO_PIN); dreher.writeMicroseconds(SERVO_0);
  motoren.enableDrivers(); stop();
  if(EEPROM.read(EE_MAGIC_ADDR)==EE_MAGIC){ EEPROM.get(EE_2C_ADDR,twoC); EEPROM.get(EE_BOFF_ADDR,breiteOff); }
  Serial.println(F("Bereit (v5 Kontakt-Mikrometer). '?' = Hilfe."));
  if(twoC==0) Serial.println(F("WARNUNG: unkalibriert -> 'k' (Dicke) + 'w' (Breite)."));
}

void loop(){
  if(!Serial.available()) return;
  char c=Serial.read();
  if(c=='m'){
    if(twoC==0){ Serial.println(F("Erst 'k' kalibrieren.")); return; }
    Serial.println(F("--- Messung ---"));
    float dMw,dSd,bMw,bSd; int ok; messen(dMw,dSd,bMw,bSd,ok);
    if(!ok){ Serial.println(F("Keine gueltige Messung.")); return; }
    Serial.print(F("DICKE:  ")); Serial.print(dMw,3); Serial.print(F(" +/- ")); Serial.print(dSd,3); Serial.println(F(" mm"));
    Serial.print(F("BREITE: ")); Serial.print(bMw,3); Serial.print(F(" +/- ")); Serial.print(bSd,3); Serial.println(F(" mm"));
    Serial.print(F("(")); Serial.print(ok); Serial.print('/'); Serial.print(N_PASSES); Serial.println(F(" Paesse)"));
  }
  else if(c=='k'){ kalibriere(); }
  else if(c=='w'){ kalibriereBreite(); }
  else if(c=='t'){ bool o; long p=tasteGemittelt(o); Serial.print(F("Kontakt @ ")); Serial.print(p); Serial.println(o?F(" ok"):F(" FEHLER")); }
  else if(c=='s'){
    int arr[4]={SERVO_0,SERVO_90,SERVO_180,SERVO_270};
    int n = USE_270_SERVO?4:3;
    for(int i=0;i<n;i++){ servoZu(arr[i]); Serial.print(F("Servo ")); Serial.println(arr[i]); delay(800); }
    servoZu(SERVO_0); dreher.detach();
  }
  else if(c=='?'){
    Serial.println(F("m=messen k=Dicke-Kal w=Breite-Kal t=antasten s=servo-test"));
    Serial.print(F("2C=")); Serial.print(twoC);
    Serial.print(F("  breiteOff=")); Serial.print(breiteOff,4);
    Serial.print(F("  270-Servo=")); Serial.println(USE_270_SERVO);
  }
}
