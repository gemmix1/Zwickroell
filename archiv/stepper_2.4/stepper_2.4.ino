

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
//    IN1 -> Pin 8  |  IN2 -> Pin 9
//    IN3 -> Pin 10 |  IN4 -> Pin 11
//
//  Verkabelung LCD (I2C):
//    SDA -> Mega Pin 20  |  SCL -> Mega Pin 21
//    VCC -> 5V           |  GND -> GND
//    Schritte Pro 50ms = 37 1ms = 0,74
// ============================================================

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <VL53L0X.h>

VL53L0X sensor;


// ── Motor Pins ──────────────────────────────────────────────
#define IN1  8
#define IN2  9
#define IN3  10
#define IN4  11

// ── Motor Parameter ─────────────────────────────────────────
#define SCHRITTE_PRO_UMDREHUNG  4096
#define SCHRITT_DELAY_MS        1
#define LCD_UPDATE_SCHRITTE     128   // LCD alle 128 Schritte aktualisieren

// ── LCD Konfiguration ───────────────────────────────────────
#define LCD_SPALTEN  16
#define LCD_ZEILEN    2

// ── Bool ───────────────────────────────────────
bool Fahre = false;
LiquidCrystal_I2C lcd(0x27, LCD_SPALTEN, LCD_ZEILEN);  // Adresse wird im Setup gesetzt

// ── Halbschritt-Sequenz ─────────────────────────────────────
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
long    gesamtSchritte = 0;
int8_t  richtung       = +1;
int     sequenzIndex   = 0;
uint8_t lcdAdresse     = 0x27;
bool    lcdGefunden    = false;
volatile bool stopMotor = false;


// ============================================================
//  I2C SCANNER
// ============================================================

uint8_t i2cScannen() {
  Serial.println(F("I2C Scanner laeuft..."));
  uint8_t gefunden = 0;

  for (uint8_t adresse = 1; adresse < 127; adresse++) {
    Wire.beginTransmission(adresse);
    uint8_t fehler = Wire.endTransmission();

    if (fehler == 0) {
      Serial.print(F("  Geraet gefunden: 0x"));
      if (adresse < 16) Serial.print('0');
      Serial.println(adresse, HEX);
      gefunden = adresse;   // letzte gefundene Adresse merken
    }
  }

  if (gefunden == 0) {
    Serial.println(F("  Kein I2C Geraet gefunden!"));
    Serial.println(F("  -> SDA/SCL Verkabelung pruefen (Pin 20/21)"));
  }
  return gefunden;
}

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
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}

// ============================================================
//  LCD ANZEIGE
// ============================================================

void lcdAnzeige() {
  if (!lcdGefunden) return;

  float umdrehungen = (float)gesamtSchritte / SCHRITTE_PRO_UMDREHUNG;

  lcd.setCursor(0, 0);
  lcd.print("Umdrehungen:    ");

  lcd.setCursor(0, 1);
  char buf[17];
  dtostrf(umdrehungen, 7, 4, buf);
  lcd.print(buf);

  lcd.setCursor(13, 1);
  lcd.print(richtung > 0 ? ">>" : "<<");
}

// ============================================================
//  SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  spulenAus();

attachInterrupt(
  digitalPinToInterrupt(tofIntPin),
  tofInterrupt,
  FALLING
  );
  
  // I2C starten und LCD-Adresse suchen
  Wire.begin();
  lcdAdresse = i2cScannen();

  if (lcdAdresse != 0) {
    lcdGefunden = true;
    lcd = LiquidCrystal_I2C(lcdAdresse, LCD_SPALTEN, LCD_ZEILEN);
    lcd.init();
    lcd.backlight();
    lcd.setCursor(0, 0);
    lcd.print("  Stepper v1.0  ");
    lcd.setCursor(0, 1);
    lcd.print(" Addr: 0x");
    lcd.print(lcdAdresse, HEX);
    lcd.print("      ");
    Serial.print(F("LCD initialisiert auf Adresse 0x"));
    Serial.println(lcdAdresse, HEX);
    delay(2000);
    lcd.clear();
    lcdAnzeige();
  }

  Serial.println(F("====================================="));
  Serial.println(F("  Stepper - Halbschritt 4096 Schritte"));
  Serial.println(F("====================================="));
  Serial.println(F("'r' senden = Richtung wechseln"));
  Serial.println();

  sensor.init();
  sensor.setTimeout(500);
  
  // Start continuous back-to-back mode (take readings as
  // fast as possible).  To use continuous timed mode
  // instead, provide a desired inter-measurement period in
  // ms (e.g. sensor.startContinuous(100)).
  sensor.startContinuous();

  
}


// ============================================================
//  LOOP
// ============================================================

void loop() {
  // Richtungswechsel pruefen
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'r' || c == 'R') {
      richtung = -richtung;
      Serial.print(F(">> Richtung: "));
      Serial.println(richtung > 0 ? F("VORWAERTS") : F("RUECKWAERTS"));
    }
  }
 
 do{
  // Einen Schritt ausfuehren
  sequenzIndex = (sequenzIndex + richtung + 8) % 8;
  spulenSetzen(sequenzIndex);
  delay(SCHRITT_DELAY_MS);
  gesamtSchritte += richtung;
 }
 while (Fahre == true);
  // Serial: Schrittzahl 1-4096 ausgeben (reset nach jeder Umdrehung)
  long schrittAnzeige = ((abs(gesamtSchritte) - 1) % SCHRITTE_PRO_UMDREHUNG) + 1;
  Serial.print(F("Schritt: "));
  Serial.println(schrittAnzeige);

  // LCD: alle 128 Schritte aktualisieren
  if (abs(gesamtSchritte) % LCD_UPDATE_SCHRITTE == 0) {
    lcdAnzeige();
  }

   Serial.print(sensor.readRangeContinuousMillimeters());
  if (sensor.timeoutOccurred()) { Serial.print(" TIMEOUT"); }
  Serial.println();
}
