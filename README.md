# Messstand für Zugproben — N20-Motor + Encoder + 2 M8-Achsen + ToF

Eine flache **Zugprobe (Dogbone)** wird in der Grundplatte fest eingespannt. Ein
**ToF-Sensor** auf einem motorisierten Arm fährt über die Probe und misst
**Breite** (Kantenerkennung) und **Dicke** (Höhenstufe). Der **Encoder** liefert die
Position, der Arduino rechnet daraus die Maße.

> Vollständige Doku/Historie: siehe `Projektverlauf.md`.

---

## 🛒 Einkaufsliste

| # | Teil | Empfehlung / Link | Preis |
|---|------|-------------------|-------|
| 1 | **Motor mit Encoder** | [Waveshare N20 12V, Hall-Encoder, 1:150 — BerryBase](https://www.berrybase.de/waveshare-n20-dc-getriebemotor-hall-encoder-vollmetallgetriebe-200-u-min-1-150-6-pin-12v) | ~15 € |
| 2 | **2× M8-Gewindestange** + Muttern | Baumarkt | ~5 € |
| 3 | Motortreiber **Pololu Dual MAX14870 Shield** | *vorhanden* | — |
| 4 | **Arduino Uno** | *vorhanden* | — |
| 5 | **ToF-Sensor VL53L0X** | Breakout (GY-530 o.ä.) | ~5 € |
| 6 | Netzteil/Akku 12V | Reichelt/Amazon o. 3S LiPo | ~10 € |

---

## 📁 Dateien

**Druckteile (.stl) + editierbar (.ipt):**
| Teil | Zweck |
|------|-------|
| `Grundplatte_v3` | **aktuell** – Dogbone-Mulde + schmales ToF-Fenster + **Referenz-Boss (+5 mm)** + Klemm-/Montagelöcher |
| `Grundplatte_v2` | Vorgänger (Fenster breit, ohne Referenz-Boss) |
| `Sensorarm` | trägt den Sensor, M8-angetrieben |
| `wellenkupplung_3mm_8mm` | Motor (3 mm) ↔ Stange (8 mm) |
| `Stuetze` | Stützblock für die Stangen |
| `Gewindestange_M8`, `Motor_N20`, `Sensor_VL53L1X` | Repräsentation (nicht drucken) |
| `Messstand_Komplett.iam` | **Gesamt-Baugruppe** |

**Code:** `messprogramm.ino` · **Build-Skripte:** `build_*.ps1` · **Inspektion:** Ordner `inspect\`

> Alle Teile als STL neu erzeugen: `& "H:\ZwickRoell Projekt\export_alle_stl.ps1"`

---

## 🔌 Verkabelung

```
Pololu Dual MAX14870 Shield  ->  auf Arduino Uno stecken
  M1A/M1B -> Motor Scan-Achse   [mit Encoder]   (EINZIGER Motor)
  VIN/GND -> 12V Versorgung

Encoder (Scan-Achse):  A->Pin2  B->Pin3  VCC->5V  GND->GND
ToF VL53L0X (I2C):     SDA->A4  SCL->A5  VCC->5V  GND->GND
```

> **Ein-Motor-Konzept:** Ein einziger Querscan liefert beide Maße. M2 wird nicht
> benutzt. Shield belegt Pin 4,7,8,9,10,12. Frei: Encoder 2/3, I2C A4/A5.

**Bibliotheken:** `DualMAX14870MotorShield` (Pololu) und `VL53L0X` (Pololu — liegt als
`vl53l0x-arduino-master.zip` im Ordner; in der IDE über *Sketch → Bibliothek einbinden → .ZIP* hinzufügen).

---

## ⚙️ Kalibrier-Werte (oben in `messprogramm.ino`)

```cpp
const long   CPR      = 4200;   // 7 PPR x 4 x 150 (Getriebe)
const float  STEIGUNG = 1.25;   // mm/Umdrehung der M8-Stange
const float  H_BOSS   = 5.00;   // Ist-Höhe des Referenz-Bosses (Messschieber!)
const float  KNOWN_DICKE  = 6.00;   // Endmaß für 'z' (Dicke nullen)
const float  KNOWN_BREITE = 12.00;  // Endmaß für 'w' (Breite kalibrieren)
```

**Messprinzip (ein Motor, ein Scan):** Der ToF zeigt nach unten und fährt quer
über die Probe. Profil in Scanrichtung:
`Platte(Ref 0) | Fenster | Probe | Fenster | Boss(Ref +5 mm)`.
- **BREITE** = Encoder-Weg zwischen den zwei Probenkanten (interpoliert) → encoder-genau.
- **DICKE** = Probenhöhe, **live 2-Punkt-kalibriert** an Platte (0,00) und Boss (+5,00),
  statisch mit langem Timing-Budget gemittelt → Sensor-Offset/Drift fallen raus.

**Serielle Befehle:**
| Cmd | Funktion |
|-----|----------|
| `m` | messen (N Pässe) → BREITE / DICKE als Mittelwert ± Stdabw. |
| `z` | Dicke nullen: `KNOWN_DICKE`-Endmaß einlegen, `z` senden (Offset → EEPROM) |
| `w` | Breite kalibrieren: `KNOWN_BREITE`-Endmaß einlegen, `w` senden |
| `r` | Kalibrierung zurücksetzen · `?` = Hilfe/aktuelle Werte |

**Genauigkeits-Maßnahmen im Code:** unidirektionaler Scan (kein Umkehrspiel),
Kanten per Interpolation, Mehrfach-Pässe mit Statistik, statische Präzisions-
messung (200 ms Budget) je Plateau, Backlash-freies Anfahren von unten,
persistente Artefakt-Kalibrierung im EEPROM.

**Erst-Inbetriebnahme:** Startposition so einstellen, dass der Sensor ~8 mm
**außerhalb** der Fensterkante über der Platte steht (−Y-Seite), dann `w`
(Breiten-Endmaß) und `z` (Dicken-Endmaß) einmal kalibrieren.

---

## ⚠️ Genauigkeit (ehrlich) & größter Hebel
- Der **VL53L0X** hat einen breiten Sichtkegel (~25°): bei großem Abstand ist der
  Messfleck größer als die 12-mm-Probe → verfälschte Distanz. **Wichtigster Hebel:
  Sensor niedrig montieren (~15–20 mm über der Probe)** → kleiner Fleck, saubere
  Rückgabe. Dafür `Sensorarm` entsprechend flach über der Platte führen.
- **BREITE** ist encoder-getragen und damit gut (~±0,05 mm nach Mittelung + `w`-Cal).
- **DICKE** bleibt ToF-limitiert; 2-Punkt-Cal + statische Mittelung holen das Maximum
  raus (~±0,1–0,2 mm realistisch). Für echte Präzision:
  **VL53L1X mit schmalem ROI** (programmierbares Sichtfeld) statt VL53L0X, oder ein
  **Laser-Triangulationssensor** am selben Arm.

---

## 🖨️ Druck-Einstellungen
PETG/PLA+, 3+ Wände, 30–50 % Infill, 0,2 mm Schicht. Sensorarm stehend drucken
(Schichten quer zur Last).
