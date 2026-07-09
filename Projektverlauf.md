# Projektverlauf — Messstand für Zugproben

Chronologische Doku der Entscheidungen und Dateien. Stand: 2026-06-16.

## Ziel
Ein Messstand, der eine **flache Zugprobe (Dogbone, 166 × 20/12 × 6 mm)** fest
einspannt und mit einem **Distanzsensor** zwei Maße erfasst: **Breite** und **Dicke**.
Bewegung über **Motor + Encoder + Gewindestangen**, so genau wie möglich.

## Verlauf / Entscheidungen
1. **Motor:** Yunir 1218-N20 (12 V, 27 U/min) — laut Amazon „mit Encoder", real aber
   nur 2 Anschlüsse → **kein Encoder**. Empfehlung: N20 **mit echtem 6-Pin-Encoder**
   (Waveshare, 7 PPR) → mit 4× Quadratur + Getriebe hohe Auflösung.
2. **Antrieb:** Motortreiber **Pololu Dual MAX14870 Shield** (vorhanden).
3. **Lineartechnik:** statt M8-Gewindestange präzisere **T8-Spindel + Anti-Backlash-Mutter**
   empfohlen (Spindelspiel ist der Genauigkeits-Flaschenhals). Reale Vorrichtung nutzt
   nun **2 M8-Gewindestangen als 2 Achsen**.
4. **Messprinzip:** ToF (VL53L1X) ist für 6 mm/12 mm grenzwertig genau (±1 mm). Echte
   Genauigkeit kommt über **Encoder-Position beim Querscan** (Kantenerkennung) bzw.
   einen Laser-Triangulationssensor. Aktuell: Konzept A — **ein Querscan** liefert
   Breite (Kanten) + Dicke (Höhenstufe), 2-Achs-Aufbau für beide Maße.
5. **Einspannung:** Dogbone-Mulde lokalisiert die Probe; **offenes Mess-Fenster** unter
   dem Messbereich erzeugt scharfe ToF-Kanten.

## Dateien
**Mechanik (3D-Druck):**
- `Grundplatte_v2.ipt/.stl` — Platte mit Dogbone-Mulde + ToF-Fenster + Klemmlöcher
- `Sensorarm.ipt/.stl` — M8-angetrieben, abnehmbare Sensorhalterung
- `wellenkupplung_3mm_8mm.ipt/.stl` — Motor (3 mm) ↔ Spindel (8 mm)
- `Gewindestange_M8.ipt`, `Motor_N20.ipt`, `Stuetze.ipt`, `Sensor_VL53L1X.ipt` — Repräsentationsteile
- `Messstand_Komplett.iam` — **Gesamt-Baugruppe** (Positionen sind ein Konzept-Layout, anpassbar)

**Steuerung:**
- `linearantrieb.ino` — Motor + Encoder + ToF (Motor läuft bei Distanz < Schwelle, stoppt sofort)

**Build-Skripte (parametrisch, erzeugen die Teile neu):**
- `build_grundplatte_v2.ps1`, `build_sensorarm.ps1`, `build_kupplung_stl.ps1`,
  `build_einzelteile.ps1`, `build_baugruppe.ps1`
- Inspektions-/Render-Skripte liegen im Ordner `inspect\`

**Eingaben des Nutzers (nicht verändert):** `Grundfläche Neu.ipt`, `12x6_Probestück.ipt`

## Ein-Motor-Ausbau (2026-07-01)
Festgelegt: **nur EIN Motor**, ein einziger Querscan misst Breite UND Dicke.
- `Grundplatte_v3.ipt/.stl` (via `build_grundplatte_v3.ps1`): schmales Fenster
  (scharfe Kanten) + **Referenz-Boss (+5 mm)** neben der Probe für Live-2-Punkt-
  Kalibrierung des ToF. Profil im Scan: Platte(0) | Fenster | Probe | Fenster | Boss(+5).
- `messprogramm/messprogramm.ino` komplett auf Genauigkeit neu geschrieben:
  unidirektionaler Scan (kein Umkehrspiel), interpolierte Kanten (Breite),
  statische 3-Plateau-Nachmessung mit 200 ms-Budget + 2-Punkt-Cal (Dicke),
  N Pässe mit Statistik, Backlash-Anfahrt von unten, EEPROM-Kalibrierung (`z`/`w`).
  Sensor korrekt auf **VL53L0X** (Pololu-Lib aus dem Zip) umgestellt.

## Richtungswechsel v4 — Kontakt-Mikrometer (2026-07-01)
Entscheidung: **berührungslos verworfen**, weil der ToF die Dicke prinzipiell auf
~±0,1 mm begrenzt. Stattdessen **Kontakt-Antastung nach Mikrometer-Prinzip** —
gleichzeitig genauer UND günstiger (Genauigkeit aus Encoder + Mechanik):
- DC-Motor + Encoder + M8-Spindel = Mikrometerschraube (0,298 µm/Count).
- Federgelagerter Taststift + **Mikroschalter** (Probe ist Kunststoff/Composite →
  kein elektrischer Kontakt) meldet Berührung; Encoder liest Position.
- **Servo dreht die Probe** (0/90/180/270°) → dieselbe Achse misst Dicke UND Breite.
- Messung zentrierungs-unempfindlich: `Maß = |2C − (Z_a+Z_b)|·k` (Summe zweier
  gegenüberliegender Antastungen; Drehachse fällt raus). 1× Endmaß-Kalibrierung (`k`).

Entschieden: **vorhandener SG90 (180°)** wird genutzt → `USE_270_SERVO 0`, Breite
über zentrierte Klemme. Wellenlänge 150 mm.

Erzeugt & verifiziert (Volumen-Check + Render):
- `Taster_Schlitten.ipt/.stl` (`build_taster_schlitten.ps1`) — läuft auf 2
  LM8UU-Führungsstangen, M8-Spindelmutter mittig, Taststift + D2F-Mikroschalter vorne.
- `Dreh_Klemme.ipt/.stl` (`build_dreh_klemme.ps1`) — Zentriertasche 20×6 auf der
  Drehachse, SG90-Ritzelaufnahme Ø4.8 + M2 axial, Ø44-Flansch mit 4 Index-Löchern
  (90°) für exakte Rechtwinkligkeit (Index-Pin vom Rahmen).
- `messprogramm.ino` — Kontakt-Mikrometer (Antast-Routine, Servo 0/90/180,
  2C-Kalibrierung im EEPROM).

### Einkaufsliste (Amazon, ~36 € < 50 €) — Servo vorhanden
| Teil | ca. € | Zweck |
|------|------:|-------|
| 2× Linearwelle 8 mm glatt (150 mm) | 9 | Führung des Taster-Schlittens (glatt, nicht M8!) |
| 4× LM8UU Linearlager | 7 | Schlitten auf den Wellen |
| Mikroschalter D2F/Subminiatur (5er) | 6 | Kontaktmelder am Taststift |
| Druckfeder-Sortiment | 6 | Taststift-Vorspannung |
| M8-Messing-/POM-Mutter (Anti-Backlash) | 3 | Spindelmutter im Schlitten |
| Härtestift/Kugel 4 mm (Taststift) | 5 | verschleißfeste Tastspitze |
| **Summe** | **~36** | Servo (SG90) + M8-Stange schon vorhanden |

### Baugruppe & restliche Teile (2026-07-01)
Erzeugt: `Rahmen_v4` (Grundplatte + 2 Wellenaufnahmen bei x=−14/y=±22 + Spindelloch
x=−14 + Servo-Wand mit Index-Pin-Loch + Idler-Wand-Journal), `Idler_Klemme`
(Zentriertasche + Ø8-Zapfen), `Fuehrungswelle_8x150`, `Probe_Platzhalter`.
**`Messstand_v4.iam`** = Konzept-Layout aller Teile (Matrix-Platzierung, keine
Constraints) + `Messstand_v4_Konzept.png`. Spindel/Wellen bewusst um 14 mm in X
versetzt, damit die Spindel die Probe (x=0, längs Y) nicht durchdringt; Schlitten
90° gedreht, sodass der Taststift trotzdem über x=0/y=0 (Probenmitte) sitzt.

Druckteile (STL fertig): `Rahmen_v4`, `Taster_Schlitten`, `Dreh_Klemme`, `Idler_Klemme`.
Kaufteil/Referenz (nicht drucken): `Fuehrungswelle_8x150` (glatte Welle), `Probe_Platzhalter`.

## v4b — Design-Review & Komplettkorrektur (2026-07-03)
Systematische Prüfung vor dem Druck fand **schwere Fehler in v4**, alle behoben:
1. **Rahmen_v4 war unbrauchbar**: Wände schwebten 17 mm neben der Platte (Platte
   ±70, Wände bei ±91) → STL aus 3 losen Körpern. UND: Probenspannweite passte
   nicht (Probe ±83, Taschen-Spannweite nur ~100 mm). → Ersetzt durch
   **Grundplatte_v4 (210×140)** + **2 verschraubte Türme** (Maßkette: Taschenboden
   ±83 = Klemme T=∓91, Flansch bis ∓95, Turmwand innen ∓95,5/91,5).
2. **Servo unmontierbar** (keine Löcher, SG90-Welle zu kurz für 8-mm-Wand) →
   Durchsteck-Ausschnitt 24×13 + Flanschvertiefung außen + 2 Schraublöcher.
3. **Motor hing in der Luft** → `Motorblock_N20`: Kupplungskammer Ø22×28,
   Seitenfenster für Madenschrauben, 4×M1.6-Flanschlöcher, 2×M3 an Platte.
4. **Taststift-Mechanik unstimmig** (Kragen Ø9 > Senkung Ø8, Federrichtung falsch,
   Schalter-Tasche passte nicht zur Bauform) → Feder-Pin von UNTEN (Ø13-Senkung,
   Kragen Ø12, `Taststift_Kappe` hält), Pin-Oberende drückt Mikroschalter auf
   Boss oben; Ø4-Stahlstift als Spitze eingeklebt.
5. **Messphysik**: Antasten einer verkippten Fläche = Kantenkontakt → Fehler
   LINEAR im Servo-Winkelfehler (SG90 ±1–2° ≈ ±0,1–0,2 mm — hätte den Taster-
   Vorteil zerstört!). → **Rastbolzen** (`Rast_Halter` + Ø4-Stift + Feder) rastet
   in die 4 Flanschlöcher; Firmware macht `servo.detach()` beim Antasten →
   die Raste definiert den Winkel, nicht der Servo. RETRACT 3→5 mm (Schwenkfreiheit).
6. Kleinkram: Mutterntasche 13,4×15,6 (Ecken!), Spline Ø4,9, Indexlöcher Ø4,2
   (passend zu Ø4-Stiften aus der Bestellung), `limits.h`-Include.
Alle 10 Teile mit Volumen-Check verifiziert; Baugruppe + Renders neu.
Druckordner (`Druckteile_v4\`, Desktop) auf v4b aktualisiert, alte Rahmen-STL entfernt.

## v5 — Präzisions-Upgrade (2026-07-03, Budget 70–80 €)
Budget erhöht → die zwei limitierenden Sparlösungen ersetzt:
- **Spindel: T8-Trapezspindel + Anti-Backlash-POM-Flanschmutter** statt M8-Stange
  (Schlitten: Ø10,5-Durchgang, Ø22,4-Flanschsenkung von unten, 4×M3 auf Ø16-
  Lochkreis bei 45°; Firmware `STEIGUNG` = 2.0 für T8x2 / 8.0 für T8x8).
- **Führung: glatte Ø8-Wellen + LM8UU** statt Gleitbuchsen auf Gewinde
  (Schlitten wieder Ø15-Presssitze; Platte Ø7,8-Presssitze).
- **Idler-Lager: 608ZZ** (8×22×7) im Idler-Turm (Sitz Ø22,3×7,2 von innen,
  Ø18-Lippe außen) statt gedrucktem Gleitloch.
Alle Teile neu generiert + volumen-verifiziert, Druckordner aktualisiert.
Bestellliste v5: ~76–84 € (siehe Bausatz_Anleitung.md).

## Offene Punkte / nächste Schritte
- v5-Teile bestellen (Motor + T8 + Wellen + Lager + Kleinteile) — Deadline Dienstag!
- Nach Motorerhalt: `STEIGUNG` + CPR setzen, Servo-µs justieren (`s`), `k` mit Endmaß.
- Baugruppe ist Layout, keine Constraints — Positionen bei Bedarf feinjustieren.
- Echtes Material in den .ipt zuweisen (aktuell „Generisch").

## (Verworfen) v3 — ToF-Scan
`Grundplatte_v3` + ToF-Firmware bleiben als Referenz im Ordner, sind aber durch v4
ersetzt. Nur relevant, falls doch berührungslos gemessen werden soll.
