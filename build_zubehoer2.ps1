# Weitere Kaufteil-Platzhalter fuer die Baugruppe (nur Darstellung):
#  Lager_608ZZ (22/8x7), T8_Mutter (Flansch 22 + Koerper 10.2), Mikroschalter_ph (21x6x11)
$ErrorActionPreference="Stop"; $f=0.1
$kPart=12290;$kJoin=20485;$kCut=20482;$kPos=20993;$mmU=11811; $dir=$PSScriptRoot
try{$inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application")}
catch{$inv=New-Object -ComObject Inventor.Application}
$inv.Visible=$false; $inv.SilentOperation=$true
while($inv.Documents.Count -gt 0){$inv.Documents.Item(1).Close($true)}
$tg=$inv.TransientGeometry
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function NewPart(){ $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart)); try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d }
function SaveIpt($doc,$name){ $vol=$doc.ComponentDefinition.MassProperties.Volume; $p=Join-Path $dir ($name+".ipt"); if(Test-Path $p){Remove-Item $p -Force}; $doc.SaveAs($p,$false); $doc.Close($true); Write-Host ("  + {0} ({1:N2} cm3)" -f $name,$vol) }

# 608ZZ: Ring 22 aussen / 8 innen / 7 breit
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),11*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 7*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),4*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 7.2*$f, $kPos, $kCut)|Out-Null
SaveIpt $doc "Lager_608ZZ"

# T8-Flanschmutter: Flansch Ø22x3.5 + Koerper Ø10.2 bis 18.5, Bohrung Ø8
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),11*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3.5*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),5.1*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 18.5*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0),4*$f)|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 19*$f, $kPos, $kCut)|Out-Null
SaveIpt $doc "T8_Mutter"

# Mikroschalter 21x6x11 (Body)
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchLines.AddAsTwoPointRectangle((P 0 0),(P 21 6))|Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 11*$f, $kPos, $kJoin)|Out-Null
SaveIpt $doc "Mikroschalter_ph"

Write-Host "Zubehoer2 fertig."