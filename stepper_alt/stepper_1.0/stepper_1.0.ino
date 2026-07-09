// ============================================================
//  Stepper Motor - Allgemeine Zyklus-Steuerung
//  Plattform : Arduino (Uno / Nano / Mega)
//
//  Unterstuetzte Treiber-Modi:
//    STEP_DIR   -> A4988, DRV8825, TMC2208  (2-Pin)
//    VIER_DRAHT -> ULN2003, L298N, L293D    (4-Pin)
// ============================================================

#include <Stepper.h>

// ── Treiber-Modus Konstanten (NICHT veraendern) ──────────────
#define STEP_DIR    1
#define VIER_DRAHT  2

// ── Treiber-Modus waehlen ───────────────────────────────────
#define TREIBER_MODUS  STEP_DIR   // <-- hier aendern

// ── Gemeinsame Parameter ────────────────────────────────────
#define SCHRITTE_PRO_UMDREHUNG  200   // Vollschritt = 200
#define PAUSEN_MS               300   // Pause zwischen Phasen (ms)

// ── STEP_DIR Parameter ──────────────────────────────────────
#if TREIBER_MODUS == STEP_DIR
  #define STEP_PIN          3
  #define DIR_PIN           4
  #define ENA_PIN           5     // auf 255 setzen wenn nicht verwendet
  #define SCHRITT_DELAY_US  1000  // Puls-Breite in Mikrosekunden
#endif

// ── VIER_DRAHT Parameter ────────────────────────────────────
#if TREIBER_MODUS == VIER_DRAHT
  #define IN1 8
  #define IN2 9
  #define IN3 10
  #define IN4 11
  #define UMDREHUNGEN_PRO_MIN 15
#endif

// ============================================================
//  ZYKLUS-DEFINITION
//  { Schritte, Richtung }   Richtung: +1 vorwaerts, -1 rueckwaerts
// ============================================================
struct Phase {
  uint16_t schritte;
  int8_t   richtung;
};

const Phase ZYKLUS[] = {
  { 400, +1 },   // Phase 1 - 2 Umdrehungen vorwaerts
  { 200, -1 },   // Phase 2 - 1 Umdrehung rueckwaerts
  { 100, +1 },   // Phase 3 - 0.5 Umdrehung vorwaerts
  { 300, -1 },   // Phase 4 - 1.5 Umdrehungen rueckwaerts
};

const uint8_t ANZAHL_PHASEN = sizeof(ZYKLUS) / sizeof(ZYKLUS[0]);

// ============================================================
//  INTERNE VARIABLEN
// ============================================================
#if TREIBER_MODUS == VIER_DRAHT
  Stepper motor(SCHRITTE_PRO_UMDREHUNG, IN1, IN3, IN2, IN4);
#endif

struct Protokolleintrag {
  uint16_t schritte;
  int8_t   richtung;
};

Protokolleintrag protokoll[8];  // max. 8 Phasen

// ============================================================
//  TREIBER-ABSTRAKTION
// ============================================================

void motorSetup() {
#if TREIBER_MODUS == STEP_DIR
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN,  OUTPUT);
  #if ENA_PIN != 255
    pinMode(ENA_PIN, OUTPUT);
    digitalWrite(ENA_PIN, LOW);  // LOW = aktiv beim A4988
  #endif
#endif
#if TREIBER_MODUS == VIER_DRAHT
  motor.setSpeed(UMDREHUNGEN_PRO_MIN);
#endif
}

void motorDeaktivieren() {
#if TREIBER_MODUS == STEP_DIR
  #if ENA_PIN != 255
    digitalWrite(ENA_PIN, HIGH);
  #endif
#endif
#if TREIBER_MODUS == VIER_DRAHT
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
#endif
}

void schritteAusfuehren(uint16_t anzahl, int8_t richtung) {
#if TREIBER_MODUS == STEP_DIR
  digitalWrite(DIR_PIN, richtung > 0 ? HIGH : LOW);
  delayMicroseconds(2);
  for (uint16_t i = 0; i < anzahl; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(SCHRITT_DELAY_US);
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(SCHRITT_DELAY_US);
  }
#endif
#if TREIBER_MODUS == VIER_DRAHT
  motor.step((int32_t)anzahl * richtung);
#endif
}

// ============================================================
//  PROTOKOLL-AUSGABE
// ============================================================

void protokollAusgeben() {
  int32_t  netto   = 0;
  uint32_t gesamt  = 0;

  Serial.println();
  Serial.println(F("===================================="));
  Serial.println(F(" SCHRITT-PROTOKOLL - ZYKLUS ENDE   "));
  Serial.println(F("===================================="));

  for (uint8_t i = 0; i < ANZAHL_PHASEN; i++) {
    Serial.print(F("Phase "));
    Serial.print(i + 1);
    Serial.print(F(": "));
    Serial.print(protokoll[i].schritte);
    Serial.print(F(" Schritte  ->  "));
    Serial.println(protokoll[i].richtung > 0 ? F("VORWAERTS") : F("RUECKWAERTS"));

    gesamt += protokoll[i].schritte;
    netto  += (int32_t)protokoll[i].schritte * protokoll[i].richtung;
  }

  Serial.println(F("------------------------------------"));
  Serial.print(F("Gesamt     : "));
  Serial.print(gesamt);
  Serial.println(F(" Schritte"));

  Serial.print(F("Netto-Pos. : "));
  if (netto >= 0) Serial.print('+');
  Serial.print(netto);
  Serial.print(F(" Schritte ("));
  Serial.print((float)netto / SCHRITTE_PRO_UMDREHUNG, 2);
  Serial.println(F(" Umdrehungen)"));

  Serial.println(F("------------------------------------"));
#if TREIBER_MODUS == STEP_DIR
  Serial.println(F("Treiber : STEP/DIR"));
#else
  Serial.println(F("Treiber : 4-Draht"));
#endif
  Serial.println(F("===================================="));
  Serial.println();
  Serial.println(F(">> 'r' senden = erneut starten"));
}

// ============================================================
//  ZYKLUS
// ============================================================

void zyklusStarten() {
  Serial.println(F("Zyklus laeuft ..."));
  Serial.println();

  for (uint8_t i = 0; i < ANZAHL_PHASEN; i++) {
    Serial.print(F("  Phase "));
    Serial.print(i + 1);
    Serial.print(F("/"));
    Serial.print(ANZAHL_PHASEN);
    Serial.print(F(" ... "));

    schritteAusfuehren(ZYKLUS[i].schritte, ZYKLUS[i].richtung);
    protokoll[i] = { ZYKLUS[i].schritte, ZYKLUS[i].richtung };

    Serial.println(F("OK"));
    delay(PAUSEN_MS);
  }

  motorDeaktivieren();
  protokollAusgeben();
}

// ============================================================
//  SETUP & LOOP
// ============================================================

void setup() {
  Serial.begin(9600);
  motorSetup();

  delay(2000);  // Zeit zum Oeffnen des Serial Monitors

  Serial.println(F("====================================="));
  Serial.println(F("  Stepper Motor - Zyklus-Steuerung   "));
  Serial.println(F("====================================="));
  Serial.println();

  zyklusStarten();
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'r' || c == 'R') {
      Serial.println(F("Neustart..."));
      motorSetup();
      zyklusStarten();
    }
  }
}
