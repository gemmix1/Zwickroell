// ============================================================
//  Stepper Motor - Umdrehungsanzeige auf LCD
//  Plattform : Arduino MEGA 2560
//  Motor     : 28BYJ-48 mit ULN2003 Treiber
//  Modus     : Halbschritt (4096 Schritte/Umdrehung)
//  Display   : LCD 16x2 / 20x4 via I2C
//
//  Arduino IDE:
//    Tools -> Board -> "Arduino Mega or Mega 2560"
//    Bibliothek: "LiquidCrystal I2C" von Frank de Brabander
//
//  Verkabelung ULN2003:
//    IN1 -> Pin 8
//    IN2 -> Pin 9
//    IN3 -> Pin 10
//    IN4 -> Pin 11
//
//  Verkabelung LCD (I2C):
//    SDA -> Mega Pin 20
//    SCL -> Mega Pin 21
//    VCC -> 5V  |  GND -> GND
// ============================================================

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ── Motor Pins ──────────────────────────────────────────────
#define IN1  8
#define IN2  9
#define IN3  10
#define IN4  11

// ── Motor Parameter ─────────────────────────────────────────
// Halbschritt: 4096 Schritte pro Umdrehung (doppelte Praezision)
#define SCHRITTE_PRO_UMDREHUNG  4096
#define SCHRITT_DELAY_MS        1     // Pause je Halbschritt (min. 1ms)

// ── LCD Konfiguration ───────────────────────────────────────
#define LCD_ADRESSE  0x27   // falls kein Bild: 0x3F probieren
#define LCD_SPALTEN  16
#define LCD_ZEILEN    2

LiquidCrystal_I2C lcd(LCD_ADRESSE, LCD_SPALTEN, LCD_ZEILEN);

// ── Halbschritt-Sequenz (8 Schritte) ───────────────────────
//  Jede Zeile = eine Spulenkombination: IN1, IN2, IN3, IN4
const bool HALBSCHRITT[8][4] = {
  {1, 0, 0, 0},
  {1, 1, 0, 0},
  {0, 1, 0, 0},
  {0, 1, 1, 0},
  {0, 0, 1, 0},
  {0, 0, 1, 1},
  {0, 0, 0, 1},
  {1, 0, 0, 1}
};

// ── Laufvariablen ───────────────────────────────────────────
long   gesamtSchritte = 0;
int8_t richtung       = +1;   // +1 vorwaerts, -1 rueckwaerts
int    sequenzIndex   = 0;    // aktueller Schritt in der 8er-Sequenz

// ============================================================
//  MOTOR STEUERUNG
// ============================================================

void spulenSetzen(int idx) {
  digitalWrite(IN1, HALBSCHRITT[idx][0]);
  digitalWrite(IN2, HALBSCHRITT[idx][1]);
  digitalWrite(IN3, HALBSCHRITT[idx][2]);
  digitalWrite(IN4, HALBSCHRITT[idx][3]);
}

void spulenAus() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void einSchrittAusfuehren() {
  sequenzIndex = (sequenzIndex + richtung + 8) % 8;
  spulenSetzen(sequenzIndex);
  delay(SCHRITT_DELAY_MS);
  gesamtSchritte += richtung;

  // Jeden Schritt auf Serial ausgeben
  float umdrehungen = (float)gesamtSchritte / SCHRITTE_PRO_UMDREHUNG;
  Serial.print(F("Umdrehung: "));
  if (umdrehungen >= 0) Serial.print('+');
  Serial.println(umdrehungen, 4);
}

void umdrehungAusfuehren() {
  for (int i = 0; i < SCHRITTE_PRO_UMDREHUNG; i++) {
    einSchrittAusfuehren();

    // Richtungswechsel waehrend der Umdrehung pruefen
    if (Serial.available() > 0) {
      char c = Serial.read();
      if (c == 'r' || c == 'R') {
        richtung = -richtung;
        Serial.print(F(">> Richtung: "));
        Serial.println(richtung > 0 ? F("VORWAERTS") : F("RUECKWAERTS"));
      }
    }
  }
}

// ============================================================
//  LCD ANZEIGE
// ============================================================

void lcdAnzeige() {
  float umdrehungen = (float)gesamtSchritte / SCHRITTE_PRO_UMDREHUNG;

  lcd.setCursor(0, 0);
  lcd.print("Umdrehungen:    ");

  lcd.setCursor(0, 1);
  char buf[17];
  dtostrf(umdrehungen, 6, 2, buf);
  lcd.print(buf);

  lcd.setCursor(10, 1);
  lcd.print(richtung > 0 ? "  [>>]" : "  [<<]");
}

// ============================================================
//  SETUP
// ============================================================

void setup() {
  Serial.begin(115200);  // Hoch fuer schnelle Schritt-Ausgabe

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  spulenAus();

  Wire.begin();
  lcd.init();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("  Stepper v1.0  ");
  lcd.setCursor(0, 1);
  lcd.print(" Halbschritt 4k ");
  delay(2000);
  lcd.clear();
  lcdAnzeige();

  Serial.println(F("====================================="));
  Serial.println(F("  Stepper - Halbschritt 4096 Schritte"));
  Serial.println(F("====================================="));
  Serial.println(F("'r' senden = Richtung wechseln"));
  Serial.println();
}

// ============================================================
//  LOOP
// ============================================================

void loop() {
  // Eine Umdrehung ausfuehren
  umdrehungAusfuehren();

  // Spulen nach Umdrehung stromlos
  spulenAus();

  // LCD aktualisieren (jede Umdrehung)
  lcdAnzeige();
}
