# ============================================================
#  Baut Grundplatte v3 fuer das EIN-MOTOR-Konzept.
#  Ein einziger Querscan (ToF zeigt nach unten) liefert BEIDE Masse:
#    BREITE = Encoder-Weg zwischen den zwei Probenkanten (offene Fenster
#             erzeugen scharfe Distanzspruenge -> encoder-genau).
#    DICKE  = Hoehenstufe zur Probenoberkante, mit ZWEI bekannten
#             Referenzhoehen im selben Scan live 2-Punkt-kalibriert:
#               - Plattenoberkante  Z = plate_T        (Referenz 0.00)
#               - Referenz-Boss     Z = plate_T + ref_h (Referenz +5.00)
#             -> ToF-Massstab wird pro Scan nachgezogen, Dicke interpoliert.
#
#  Scanrichtung = Y (quer ueber die schmale Probenbreite).
#  Profil entlang Y:  Platte(15) | Fenster(weit) | Probe(19) | Fenster(weit) | Boss(20)
#
#  Inventor-API rechnet in cm -> Faktor 0.1. Ausgabe neben diesem Script.
# ============================================================
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$plate_L = 220.0    # Plattenlaenge  (X, entlang der Probe)
$plate_W = 80.0     # Plattenbreite  (Y, Scanrichtung)
$plate_T = 15.0     # Plattendicke   (Z)

$cl      = 0.25     # Spiel der Mulde pro Seite

# Dogbone (aus Probe: 166 lang, Enden 20 breit, Mitte 12 breit)
$grip_L  = 30.0     # Laenge je Einspannende
$grip_W  = 20.0     # Breite Einspannende
$gauge_L = 106.0    # Laenge Messbereich
$gauge_W = 12.0     # Breite Messbereich
$pocket_d = 2.0     # Muldentiefe: Probe (6mm) ragt 4mm raus, Boden Z=13

# Mess-Fenster (offen nach unten). SCHMAL gehalten (nur wenig breiter als
# die Probe) -> Referenz-Plattenkante liegt dicht neben der Probe, gleicher Scan.
$win_L = 70.0       # X-Laenge (Gauge-Spann, < gauge_L damit Enden aufliegen)
$win_W = 24.0       # Y-Breite: Probe 12mm mittig -> je 6mm offener Spalt bis Kante

# Referenz-Boss (+Y-Seite): bekannte Zusatzhoehe fuer 2-Punkt-ToF-Kalibrierung
$ref_h   = 5.0      # Bosshoehe ueber Plattenoberkante -> Top Z = 20.00
$ref_y0  = 13.0     # Boss-Start in Y (direkt hinter der Fensterkante bei 12)
$ref_y1  = 27.0     # Boss-Ende   in Y (14mm breit -> gut fuer ToF-Kegel)
$ref_x   = 25.0     # Boss halbe X-Laenge (Boss von -25..+25 im Scanbereich)

# Klemmloecher (Niederhalter ueber den Einspannenden)
$hole_d = 3.2
# Montageloecher fuer den Achsrahmen (Stuetzen/Motorbock), M4 -> 4.2mm
$mnt_d  = 4.2
$mnt_x  = 95.0      # nahe den kurzen Plattenenden
$mnt_y  = 33.0      # nahe den langen Plattenkanten

$f = 0.1
$outIpt = Join-Path $PSScriptRoot "Grundplatte_v3.ipt"
$outStl = Join-Path $PSScriptRoot "Grundplatte_v3.stl"

$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

Write-Host "Verbinde mit Inventor..."
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }

$tg=$inv.TransientGeometry
$doc=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
try { $doc.UnitsOfMeasure.LengthUnits=$mmU } catch {}
$cd=$doc.ComponentDefinition
$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }

Write-Host "1) Grundblock..."
$sk=$cd.Sketches.Add($XY)
$sk.SketchLines.AddAsTwoPointRectangle((P (-$plate_L/2) (-$plate_W/2)),(P ($plate_L/2) ($plate_W/2))) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $plate_T*$f, $kPos, $kJoin) | Out-Null

$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $plate_T*$f); $top.Visible=$false
function CutRect($x1,$y1,$x2,$y2,$depth){
  $s=$cd.Sketches.Add($top)
  $s.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2)) | Out-Null
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $depth*$f, $kNeg, $kCut) | Out-Null
}

Write-Host "2) Dogbone-Mulde..."
$gx = $gauge_L/2                      # 53
$ex = $gx + $grip_L                   # 83
CutRect (-$ex-$cl) (-$grip_W/2-$cl) (-$gx+$cl) ($grip_W/2+$cl) $pocket_d   # Ende A
CutRect ($gx-$cl) (-$grip_W/2-$cl) ($ex+$cl) ($grip_W/2+$cl) $pocket_d     # Ende B
CutRect (-$gx-$cl) (-$gauge_W/2-$cl) ($gx+$cl) ($gauge_W/2+$cl) $pocket_d   # Mitte

Write-Host "3) Mess-Fenster (durch, schmal fuer scharfe Kanten)..."
CutRect (-$win_L/2) (-$win_W/2) ($win_L/2) ($win_W/2) ($plate_T+1)

Write-Host "4) Referenz-Boss (+5.00mm, 2-Punkt-ToF-Kalibrierung)..."
$sb=$cd.Sketches.Add($top)
$sb.SketchLines.AddAsTwoPointRectangle((P (-$ref_x) $ref_y0),(P ($ref_x) $ref_y1)) | Out-Null
$ef.AddByDistanceExtent($sb.Profiles.AddForSolid(), $ref_h*$f, $kPos, $kJoin) | Out-Null

Write-Host "5) Klemmloecher..."
$s=$cd.Sketches.Add($top)
$hx = $gx + $grip_L/2     # 68
$hy = $grip_W/2 + 5       # 15
foreach ($sx in -1,1) { foreach ($sy in -1,1) {
  $s.SketchCircles.AddByCenterRadius((P ($sx*$hx) ($sy*$hy)), ($hole_d/2)*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($plate_T+1)*$f, $kNeg, $kCut) | Out-Null

Write-Host "6) Montageloecher Achsrahmen..."
$s=$cd.Sketches.Add($top)
foreach ($sx in -1,1) { foreach ($sy in -1,1) {
  $s.SketchCircles.AddByCenterRadius((P ($sx*$mnt_x) ($sy*$mnt_y)), ($mnt_d/2)*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($plate_T+1)*$f, $kNeg, $kCut) | Out-Null

Write-Host "7) Speichern .ipt + .stl..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)

$doc.Close($true)
foreach($file in @($outIpt,$outStl)){ if(Test-Path $file){Write-Host ("FERTIG: {0} ({1:N1} KB)" -f $file,((Get-Item $file).Length/1KB))} }
