# Motor-Servo-Halterung: Grundkörper + Taschen
# WICHTIG: AddAsTwoPointRectangle schlägt fehl wenn BEIDE X-Koord. negativ (Inventor-Bug)
# Workaround: Teil-Design mit positiven X-Koordinaten (Servo rechts X=[2,25], Motor X=[28,48])
$ErrorActionPreference = "Stop"
$f=0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry
$doc=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart))
try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3); $XZ=$cd.WorkPlanes.Item(2)
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }

# ---- Layout: X=[0..50], Y=[-12..12], Z=[0..40] ----
#   Servo-Bereich:  X=[2..25]    (Breite 23mm)
#   Motor-Bereich:  X=[28..48]   (Breite 20mm)
#   Kupplung-Mitte: X=[25..28]

Write-Host "1) Grundkoerper 50x24x40mm (alles positiv)..."
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P 0 -12),(P 50 12)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),40*$f,$kPos,$kJoin) | Out-Null
$top40=$cd.WorkPlanes.AddByPlaneAndOffset($XY,40*$f); $top40.Visible=$false

Write-Host "2a) Motor-Hoehlung (12x10mm, 28mm tief von oben)..."
$s=$cd.Sketches.Add($top40)
$s.SketchLines.AddAsTwoPointRectangle((P 29 -5),(P 47 5)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),28*$f,$kNeg,$kCut) | Out-Null

Write-Host "2b) Servo-Schlitz (23x12.5mm, 25mm tief von oben)..."
$s=$cd.Sketches.Add($top40)
$s.SketchLines.AddAsTwoPointRectangle((P 2 -6.3),(P 24 6.3)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),25*$f,$kNeg,$kCut) | Out-Null

Write-Host "2c) Motor-Wellen-Bohrung Ø4mm (Y-sym, Turm-Mitte X=38, Z=20)..."
$s=$cd.Sketches.Add($XZ)
$s.SketchCircles.AddByCenterRadius((P 38 20),2*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),30*$f,$kSym,$kCut) | Out-Null

Write-Host "2d) Servo-Wellen-Bohrung Ø5mm (5mm von oben, Servo-Mitte X=13)..."
$s=$cd.Sketches.Add($top40)
$s.SketchCircles.AddByCenterRadius((P 13 0),2.5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),5*$f,$kNeg,$kCut) | Out-Null

Write-Host "2e) Rahmen-Befestigungsloecher 4x M4 an Ecken..."
$s=$cd.Sketches.Add($XY)
foreach($sx in 4,46){ foreach($sy in -8,8){
    $s.SketchCircles.AddByCenterRadius((P $sx $sy),2.1*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(),5*$f,$kPos,$kCut) | Out-Null

Write-Host "3) Speichern..."
$out="H:\ZwickRoell Projekt\Motorhalterung"
if(Test-Path "$out.ipt"){Remove-Item "$out.ipt" -Force}
$doc.SaveAs("$out.ipt",$false)
$a=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName="$out.stl"
if($a.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
$a.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
Write-Host ("FERTIG: Motorhalterung.ipt ({0:N0} KB)" -f ((Get-Item "$out.ipt").Length/1KB))
