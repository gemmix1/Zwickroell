# Sensorarm v2 - zwei Sensorpositionen:
#   Pocket UNTEN  (Sensor zeigt -Z) -> Top-Scan  -> Breite  via Encoder Y
#   Pocket SEITE  (Sensor zeigt +Y) -> Seiten-Scan -> Dicke via Encoder Z
# Gleicher VL53L0X, wird umgesteckt. Genauigkeit kommt aus Encoder, nicht ToF.
# Inventor-API in cm -> Faktor 0.1
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$arm_H     = 14.0    # Armdicke (Z) - 14mm damit Seiten-Pocket (9.5mm Board) sauber passt
$block     = 28.0    # Nutblock quadratisch
$m8_bore   = 8.5     # M8-Stangen-Durchgang
$hex_af    = 13.0    # SW13 M8-Mutter
$hex_depth = 6.5     # Mutter-Pocket-Tiefe
$arm_reach = 100.0   # Arm-Ausladung (X, Blockkante bis Pad-Anfang)
$arm_w     = 14.0    # Armbreite (Y)
$pad_w     = 32.0    # Sensorpad Breite (Y)
$pad_len   = 30.0    # Sensorpad Laenge (X)

# VL53L0X Board ca. 8.5 x 14.5 mm
$sens_L    = 9.5     # Pocket kurze Seite (Board-Breite + Spiel)
$sens_W    = 15.5    # Pocket lange Seite (Board-Laenge + Spiel)
$sens_d    = 3.0     # Pocket-Tiefe
$beam_d    = 6.0     # Strahldurchgang
$screw_d   = 2.2     # M2-Schrauben
$screw_dx  = 10.0    # M2-Loch-Abstand X vom Pad-Zentrum

$f = 0.1
$outIpt = "H:\ZwickRoell Projekt\Sensorarm_v2.ipt"
$outStl = "H:\ZwickRoell Projekt\Sensorarm_v2.stl"
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
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
$XY=$cd.WorkPlanes.Item(3)   # normal in Z
$XZ=$cd.WorkPlanes.Item(2)   # normal in Y
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }

$cx = $arm_reach + $pad_len/2   # Pad-Zentrum X = 100 + 15 = 115

# ---- Koerper ----
Write-Host "1) Koerper (Nutblock + Arm + Sensorpad)..."
function JoinRect($x1,$y1,$x2,$y2){
    $s=$cd.Sketches.Add($XY)
    $s.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2)) | Out-Null
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $arm_H*$f, $kPos, $kJoin) | Out-Null
}
JoinRect (-$block/2) (-$block/2) ($block/2) ($block/2)
JoinRect ($block/2)  (-$arm_w/2) $arm_reach ($arm_w/2)
JoinRect $arm_reach  (-$pad_w/2) ($arm_reach+$pad_len) ($pad_w/2)

# ---- M8-Bohrung + Mutter-Pocket ----
Write-Host "2) M8-Bohrung..."
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), ($m8_bore/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($arm_H+1)*$f, $kPos, $kCut) | Out-Null

Write-Host "3) Mutter-Pocket (oben)..."
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $arm_H*$f); $top.Visible=$false
$nut_ac = 15.5
$s=$cd.Sketches.Add($top)
$s.SketchLines.AddAsTwoPointRectangle((P (-$nut_ac/2) (-($hex_af+0.2)/2)),(P ($nut_ac/2) (($hex_af+0.2)/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $hex_depth*$f, $kNeg, $kCut) | Out-Null

# ---- POSITION A: Sensor nach UNTEN (Top-Scan -> Breite) ----
Write-Host "4) Pocket UNTEN (Sensor zeigt -Z, Top-Scan Breite)..."
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P ($cx-$sens_L/2) (-$sens_W/2)),(P ($cx+$sens_L/2) ($sens_W/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $sens_d*$f, $kPos, $kCut) | Out-Null

# Strahldurchgang unten (Z-Richtung)
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P $cx 0), ($beam_d/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($arm_H+1)*$f, $kPos, $kCut) | Out-Null

# M2-Loecher fuer unten-Pocket (auf XY-Ebene, Abstand in X)
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P ($cx-$screw_dx) 0), ($screw_d/2)*$f) | Out-Null
$s.SketchCircles.AddByCenterRadius((P ($cx+$screw_dx) 0), ($screw_d/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($arm_H+1)*$f, $kPos, $kCut) | Out-Null

# ---- POSITION B: Sensor nach SEITE (+Y, Seiten-Scan -> Dicke) ----
# Pocket auf der +Y-Flaeche des Pads. Board liegt in XZ-Ebene:
#   X-Richtung: sens_W = 15.5mm (Board-Laenge)
#   Z-Richtung: sens_L =  9.5mm (Board-Breite), zentriert bei arm_H/2
Write-Host "5) Pocket SEITE (+Y-Flaeche, Sensor zeigt +Y, Seiten-Scan Dicke)..."
$side_plane=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, ($pad_w/2)*$f); $side_plane.Visible=$false
$s=$cd.Sketches.Add($side_plane)
# In XZ-Sketch: X->X, Y->Z des Bauteils
$zc = $arm_H / 2   # Z-Mitte des Arms
$s.SketchLines.AddAsTwoPointRectangle(
    (P ($cx-$sens_W/2) ($zc-$sens_L/2)),
    (P ($cx+$sens_W/2) ($zc+$sens_L/2))
) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $sens_d*$f, $kNeg, $kCut) | Out-Null

# Strahldurchgang seite (Y-Richtung, symmetrisch durch ganzen Pad)
$s=$cd.Sketches.Add($side_plane)
$s.SketchCircles.AddByCenterRadius((P $cx $zc), ($beam_d/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($pad_w+1)*$f, $kSym, $kCut) | Out-Null

# M2-Loecher fuer Seiten-Pocket (auf der +Y-Flaeche, Abstand in X)
$s=$cd.Sketches.Add($side_plane)
$s.SketchCircles.AddByCenterRadius((P ($cx-$screw_dx) $zc), ($screw_d/2)*$f) | Out-Null
$s.SketchCircles.AddByCenterRadius((P ($cx+$screw_dx) $zc), ($screw_d/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($pad_w+1)*$f, $kSym, $kCut) | Out-Null

# ---- Speichern ----
Write-Host "6) Speichern .ipt + .stl..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
foreach($file in @($outIpt,$outStl)){
    if(Test-Path $file){ Write-Host ("FERTIG: {0} ({1:N1} KB)" -f $file,((Get-Item $file).Length/1KB)) }
}
