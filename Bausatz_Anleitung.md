# Bausatz – Messstand v4 (autonom, Kontakt-Taster)

Komplettpaket: bestellen → drucken → verdrahten → montieren → kalibrieren.

## 1) Bestellliste v5 (Amazon.de, ~76–84 €, Budget 70–80)

Präzisions-Aufbau: echte Linearführung + spielfreie Spindel + Kugellager.

| Teil | ~€ | Amazon.de |
|------|---:|-----------|
| **Encoder-Motor Waveshare N20 — 12V / 1:150 wählen!** | 15 | B0CW1TCCTL (kritisch: MIT Encoder, 6 Kabel) |
| **T8-Trapezspindel 200 mm + Anti-Backlash-POM-Mutter** (T8x2 bevorzugt, T8x8 ok) | 13 | Suche „T8 Spindel 200mm Anti Backlash" |
| **2× Linearwelle Ø8 × 150 mm glatt** (nicht Gewinde!) | 7 | Suche „linearwelle 8mm 150" |
| **LM8UU Linearlager** (12er, brauchst 2) | 8 | B08Y6LZQZ1 |
| **608ZZ Kugellager** 8×22×7 (10er, brauchst 1) | 5 | Suche „608ZZ Kugellager" |
| **Metallkupplung 3→8 mm** (2er) | 7 | B08G555R9Y |
| Mikroschalter Hebel SPDT (10er, brauchst 1) | 7 | B08736V215 |
| Druckfeder-Sortiment (brauchst 2: Taster + Rastbolzen) | 7 | B0GDFK7CX8 |
| Zylinderstift 4 mm gehärtet (brauchst 2: Tastspitze + Raststift) | 7 | B09JJXLM1Z |
| *falls nicht da:* Schrauben-Sortiment M2/M2.5/M3 (+M1.6) | 8 | Suche „Schrauben Sortiment" |

**Summe: 76 € (84 € mit Schrauben-Set).** Vorhanden: SG90, Arduino,
MAX14870-Shield, 12-V-Netzteil. Deine M8-Gewindestangen werden nicht mehr
gebraucht (T8 ersetzt die Spindel — spielfrei und gerade).
Motor-Seite: **12 V** und **1:150 (200 RPM)** auswählen, sonst stimmt CPR nicht.
**Firmware:** `STEIGUNG` auf die Spindel setzen (T8x2 → 2.0, T8x8 → 8.0).

**Hast du schon:** Servo SG90, Arduino Uno, Pololu Dual MAX14870 Shield, M8-Gewindestange (= Spindel), 12 V Netzteil.
**Nicht mehr nötig:** ToF (nur bei der ungenauen Variante).

## 2) Drucken — v4b (KORRIGIERTER SATZ, 10 Teile)
Siehe `Druckteile_v4\00_ANLEITUNG.txt`. PETG/PLA+, 4 Wände, 0,15–0,2 mm.
**Alte `Rahmen_v4.stl` NICHT drucken** (Konstruktionsfehler, ersetzt durch
Grundplatte_v4 + 2 verschraubte Türme).

| Teil | Zweck |
|------|-------|
| Grundplatte_v4 (210×140, Bett ≥210!) | Basis mit Wellen-Bossen, allen Schraublöchern |
| Turm_Servo / Turm_Idler | Endwände, verschraubt (druckbett-freundlich) |
| Motorblock_N20 | hält Motor + Kupplungskammer mit Zugangsfenstern |
| Taster_Schlitten | Mikrometer-Schlitten (Feder-Pin von unten, Schalter-Boss oben) |
| Dreh_Klemme / Idler_Klemme | Probenaufnahme (Tasche 16 tief) |
| Taststift + Taststift_Kappe | federnder Taster (Ø4-Stahlstift als Spitze einkleben) |
| Rast_Halter | federnder **Rastbolzen** → exakte 0/90/180° (Genauigkeits-Kernstück!) |

Zusätzlich nötig: Schrauben-Sortiment M1.6/M2/M2.5/M3 (falls nicht vorhanden, ~8 €).
Zuerst 20-mm-Testwürfel → Passungen prüfen (Ø15, Ø8, M8-Mutter, Ø4-Stifte).

## 3) Verdrahtung

Shield auf den Arduino Uno stecken. Dann:

| Von | Nach |
|-----|------|
| Motor (2 dicke Leitungen) | M1A / M1B (Shield) |
| Encoder A | Pin 2 |
| Encoder B | Pin 3 |
| Encoder VCC / GND | 5V / GND |
| Mikroschalter COM | GND |
| Mikroschalter NO | A0 |
| Servo Signal / VCC / GND | Pin 6 / 5V / GND |
| 12 V Netzteil + / − | Shield VIN / GND |

Shield belegt Pin 4,7,8,9,10,12 → keine Kollision. Frei genutzt: 2,3 (Encoder), 6 (Servo), A0 (Schalter).
Wenn der Servo den Arduino „browned out" (Reset beim Drehen): Servo-5V aus separatem 5 V-Regler/BEC speisen, **GND gemeinsam**.

## 4) Montage-Reihenfolge

1. **Schlitten:** 2× LM8UU in `Taster_Schlitten` pressen, M8-Mutter in die Tasche, Taststift Ø4 + Feder in die vordere Bohrung, Mikroschalter davor schrauben (Stift drückt bei Kontakt auf den Hebel).
2. **Rahmen:** 2 glatte Ø8-Wellen senkrecht in die Bosse pressen. M8-Gewindestange (Spindel) mittig einsetzen.
3. **Antrieb:** Motor unter die Platte, Welle durch das Spindelloch, mit der Kupplung an die M8-Stange. Motor fixieren.
4. **Schlitten auf** die 2 Wellen (LM8UU) + M8-Mutter auf die Spindel fädeln.
5. **Servo** an die Servo-Wand (−Y), `Dreh_Klemme` auf das SG90-Ritzel. `Idler_Klemme`-Zapfen in das Journal der anderen Wand.
6. **Index-Pin** durch das Wand-Loch in eines der 4 Flansch-Löcher → definiert exakt 0/90/180°.
7. **Probe** mit beiden Grip-Enden in die zwei Klemmen (Zentriertaschen) stecken.

## 5) Kalibrieren (in dieser Reihenfolge)

1. **CPR setzen:** aus dem Motor-Datenblatt `CPR = PPR × 4 × 150`. Falls unklar → **counts/mm messen** (Spindel bekannte Strecke fahren, Ticks zählen) und `MM_PRO_COUNT` direkt setzen. *(Wichtig für die Skala!)*
2. **Servo-Winkel:** `s` senden → SG90 fährt 0/90/180. `SERVO_0/90/180` (µs) so anpassen, dass der Index-Pin sauber in die Löcher fällt (Rechtwinkligkeit!).
3. **Vorzeichen:** einmal `m`; kommt Dicke negativ → `DIM_SIGN = -1`.
4. **Nullen:** Endmaß bekannter Dicke einspannen → `k`. Setzt `2C` (EEPROM).
5. **Messen:** `m` → Dicke + Breite als Mittelwert ± Standardabweichung.

`?` = Hilfe/aktuelle Werte · `t` = Antasten testen.

## Zeitplan bis Dienstag
- **Heute:** Motor + Kleinteile bestellen (Prime), 4 Teile drucken.
- **Sa/So:** Montage + Verdrahtung.
- **Mo:** Servo-Winkel + Kalibrierung, Messungen.
