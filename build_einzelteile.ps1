# Baut einfache Repraesentations-Teile: M8-Stange, N20-Motor, Stuetze, Sensor.
$ErrorActionPreference = "Stop"
$f=0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$dir="H:\ZwickRoell Projekt"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

function NewPart(){ return $inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart)) }
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function SavePart($doc,$name){ $p="$dir\$name"; if(Test-Path $p){Remove-Item $p -Force}; $doc.SaveAs($p,$false); $doc.Close($true); Write-Host "OK: $name" }

# 1) M8-Gewindestange (Zylinder Ø8 x 180)
$doc=NewPart; try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),4*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),180*$f,$kPos,$kJoin)|Out-Null
SavePart $doc "Gewindestange_M8.ipt"

# 2) N20-Motor (Block 12x10x26 + Welle Ø3 x10)
$doc=NewPart; try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchLines.AddAsTwoPointRectangle((P -6 -5),(P 6 5))|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),26*$f,$kPos,$kJoin)|Out-Null
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY,26*$f); $top.Visible=$false
$s=$cd.Sketches.Add($top); $s.SketchCircles.AddByCenterRadius((P 0 0),1.5*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),10*$f,$kPos,$kJoin)|Out-Null
SavePart $doc "Motor_N20.ipt"

# 3) Stuetze (Block 24x16x80 + Ø8.5 Bohrung quer bei Z=70)
$doc=NewPart; try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3); $XZ=$cd.WorkPlanes.Item(2)
$s=$cd.Sketches.Add($XY); $s.SketchLines.AddAsTwoPointRectangle((P -12 -8),(P 12 8))|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),80*$f,$kPos,$kJoin)|Out-Null
$s=$cd.Sketches.Add($XZ); $s.SketchCircles.AddByCenterRadius((P 0 70),4.25*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),20*$f,$kSym,$kCut)|Out-Null
SavePart $doc "Stuetze.ipt"

# 4) Sensor VL53L1X (Block 13x25x3 + Linse Ø4 x2)
$doc=NewPart; try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchLines.AddAsTwoPointRectangle((P -6.5 -12.5),(P 6.5 12.5))|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),3*$f,$kPos,$kJoin)|Out-Null
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY,3*$f); $top.Visible=$false
$s=$cd.Sketches.Add($top); $s.SketchCircles.AddByCenterRadius((P 0 0),2*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),2*$f,$kPos,$kJoin)|Out-Null
SavePart $doc "Sensor_VL53L1X.ipt"

Write-Host "Alle Einzelteile gebaut."
