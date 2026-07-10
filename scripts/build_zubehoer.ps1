# ============================================================
#  Zubehoer-/Repraesentationsteile fuer die Baugruppe Messstand_v4.
#  (Kauf-/Norm-/Bewegungsteile - nur zur Darstellung, werden nicht gedruckt.)
#   Taststift, Feder, Index_Pin, Servo_SG90, Motor_N20_ph, Kupplung_ph
#  Nur .ipt (kein STL). Inventor-API in cm -> Faktor 0.1.
# ============================================================
$ErrorActionPreference = "Stop"
$f=0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $mmU=11811
$dir=Join-Path $PSScriptRoot "..\cad"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function NewPart(){ $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart)); try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d }
function SaveIpt($doc,$name){ $p=Join-Path $dir ($name+".ipt"); if(Test-Path $p){Remove-Item $p -Force}; $doc.SaveAs($p,$false); $doc.Close($true); Write-Host ("  + {0}" -f $name) }
function Circle($sk,$cx,$cy,$dia){ $sk.SketchCircles.AddByCenterRadius((P $cx $cy),($dia/2)*$f)|Out-Null }
function Rect($sk,$x1,$y1,$x2,$y2){ $sk.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2))|Out-Null }
function ExtZ($cd,$sk,$h,$dir,$op){ $cd.Features.ExtrudeFeatures.AddByDistanceExtent($sk.Profiles.AddForSolid(), $h*$f, $dir, $op)|Out-Null }

# 1) Taststift Ã˜4 x 35 + Kragen Ã˜9 (Schalter-Flag) bei z=25
Write-Host "Teile..."
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circle $s 0 0 4.0; ExtZ $cd $s 35 $kPos $kJoin
$pl=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 25*$f); $pl.Visible=$false
$s=$cd.Sketches.Add($pl); Circle $s 0 0 9.0; ExtZ $cd $s 3 $kPos $kJoin
SaveIpt $doc "Taststift"

# 2) Feder (Platzhalter): Rohr OD8 / ID5 x 12
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circle $s 0 0 8.0; ExtZ $cd $s 12 $kPos $kJoin
$s=$cd.Sketches.Add($XY); Circle $s 0 0 5.0; ExtZ $cd $s 13 $kPos $kCut
SaveIpt $doc "Feder"

# 3) Index_Pin Ã˜3 x 20
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circle $s 0 0 3.0; ExtZ $cd $s 20 $kPos $kJoin
SaveIpt $doc "Index_Pin"

# 4) Servo_SG90: Body 23x12x22 + Welle Ã˜4.8 x 14 (oben)
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -11.5 -6 11.5 6; ExtZ $cd $s 22 $kPos $kJoin
$pl=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 22*$f); $pl.Visible=$false
$s=$cd.Sketches.Add($pl); Circle $s 0 0 4.8; ExtZ $cd $s 14 $kPos $kJoin
SaveIpt $doc "Servo_SG90"

# 5) Motor_N20_ph: Body 12x12x28 + Welle Ã˜3 x 12 (oben)
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -6 -6 6 6; ExtZ $cd $s 28 $kPos $kJoin
$pl=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 28*$f); $pl.Visible=$false
$s=$cd.Sketches.Add($pl); Circle $s 0 0 3.0; ExtZ $cd $s 12 $kPos $kJoin
SaveIpt $doc "Motor_N20_ph"

# 6) Kupplung_ph Ã˜12 x 18
$doc=NewPart; $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circle $s 0 0 12.0; ExtZ $cd $s 18 $kPos $kJoin
SaveIpt $doc "Kupplung_ph"

Write-Host "Zubehoer fertig."



