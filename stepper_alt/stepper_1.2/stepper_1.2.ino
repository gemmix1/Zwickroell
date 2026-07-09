// ============================================================
//  Stepper Motor - Drehzahl-Anzeige auf LCD
//  Plattform : Arduino MEGA 2560
//  Display   : LCD 16x2 oder 20x4 via I2C
//
//  Arduino IDE:
//    Tools -> Board -> "Arduino Mega or Mega 2560"
//    Bibliothek: "LiquidCrystal I2C" von Frank de Brabander
//                (Sketch -> Bibliotheken -> Bibliotheken verwalten)
//
//  Verkabelung LCD (I2C):
//    VCC -> 5V
//    GND -> GND
//    SDA -> Mega Pin 20
//    SCL -> Mega Pin 21
//
//  Verkabelung A4988 (STEP/DIR):
//    STEP -> Mega Pin 22
//    DIR  -> Mega Pin 23
//    ENA  -> Mega Pin 24
// ============================================================

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ── LCD Konfiguration ───────────────────────────────────────
#define LCD_ADRESSE  0x27   // haeufigste Adresse; falls kein Bild: 0x3F probieren
#define LCD_SPALTEN  16     // 16 oder 20
#define LCD_ZEILEN    2     // 2 oder 4

// ── Motor Pins (Mega) ───────────────────────────────────────
#define STEP_PIN  22
#define DIR_PIN   23
#define ENA_PIN   24        // 255 = nicht verwendet

// ── Motor Parameter ─────────────────────────────────────────
#define SCHRITTE_PRO_UMDREHUNG  200    // Vollschritt = 200
#define SCHRITT_DELAY_US        1000   // Pause je Schritt in us (kleiner = schneller)

// ── Richtung ────────────────────────────────────────────────
//  Serial Monitor: 'r' senden um Richtung umzukehren
int8_t richtung = +1;   // +1 vorwaerts, -1 rueckwaerts

// ── Interne Variablen ───────────────────────────────────────
long    gesamtSchritte    = 0;
long    letzteAnzeige     = 0;   // Schrittzahl beim letzten LCD-Update

LiquidCrystal_I2C lcd(LCD_ADRESSE, LCD_SPALTEN, LCD_ZEILEN);

// ============================================================
//  HILFSFUNKTIONEN
// ============================================================

void lcdAnzeige() {
  float umdrehungen = (float)gesamtSchritte / SCHRITTE_PRO_UMDREHUNG;

  // Zeile 1: Umdrehungszahl
  lcd.setCursor(0, 0);
  lcd.print("Umdrehungen:    ");
  lcd.setCursor(0, 1);

  // Vorzeichen + Wert
  char puffer[17];
  dtostrf(umdrehungen, 7, 2, puffer);   // z.B. "   2.50"
  lcd.print(puffer);

  // Richtungspfeil rechts
  lcd.setCursor(LCD_SPALTEN - 5, 1);
  if (richtung > 0) {
    lcd.print("[>>] ");
  } else {
    lcd.print("[<<] ");
  }
}

void motorSchritt() {
  digitalWrite(STEP_PIN, HIGH);
  delayMicroseconds(SCHRITT_DELAY_US);
  digitalWrite(STEP_PIN, LOW);
  delayMicroseconds(SCHRITT_DELAY_US);
  gesamtSchritte += richtung;
}

void serialVerarbeiten() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'r' || c == 'R') {
      richtung = -richtung;
      Serial.print(F("Richtung geaendert: "));
      Serial.println(richtung > 0 ? F("VORWAERTS") : F("RUECKWAERTS"));
    }
  }
}

// ============================================================
//  SETUP
// ============================================================

void setup() {
  Serial.begin(9600);

  // Motor
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN,  OUTPUT);
  #if ENA_PIN != 255
    pinMode(ENA_PIN, OUTPUT);
    digitalWrite(ENA_PIN, LOW);  // LOW = Motor aktiv
  #endif
  digitalWrite(DIR_PIN, HIGH);

  // LCD
  Wire.begin();
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("  Stepper v1.0  ");
  lcd.setCursor(0, 1);
  lcd.print("  Initialisiert ");
  delay(2000);
  lcd.clear();

  // Serial Info
  Serial.println(F("====================================="));
  Serial.println(F("  Stepper Motor - Umdrehungsanzeige  "));
  Serial.println(F("====================================="));
  Serial.println(F("Motor laeuft. 'r' senden = Richtung wechseln."));
  Serial.println();
}

// ============================================================
//  LOOP
// ============================================================

void loop() {
  // Richtung setzen
  digitalWrite(DIR_PIN, richtung > 0 ? HIGH : LOW);

  // Einen Schritt ausfuehren
  motorSchritt();

  // LCD + Serial alle 200 Schritte (= 1 Umdrehung) aktualisieren
  if (abs(gesamtSchritte - letzteAnzeige) >= SCHRITTE_PRO_UMDREHUNG) {
    letzteAnzeige = gesamtSchritte;

    float umdrehungen = (float)gesamtSchritte / SCHRITTE_PRO_UMDREHUNG;
    lcdAnzeige();

    Serial.print(F("Umdrehungen: "));
    if (umdrehungen >= 0) Serial.print('+');
    Serial.print(umdrehungen, 2);
    Serial.print(F("  Richtung: "));
    Serial.println(richtung > 0 ? F("VORWAERTS") : F("RUECKWAERTS"));
  }

  // Serial lesen (Richtungswechsel)
  serialVerarbeiten();
}
