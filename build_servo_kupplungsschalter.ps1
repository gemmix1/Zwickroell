# Servo-Kupplungsschalter
# Ein SG90-Servo dreht eine Scheibe die den Motor-Koppler von der Y-Stange
# auf die X-Stange umschaltet (90-Grad-Drehung = Achswechsel).
# Besteht aus: Servo-Halterung + Kupplungsscheibe mit 2 Aufnahmen
$ErrorActionPreference = "Stop"

$f = 0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

function NewDoc(){
    $d=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
    try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}
    return $d
}
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function SaveDoc($doc,$path){
    if(Test-Path $path){Remove-Item $path -Force}
    $doc.SaveAs($path,$false)
    $stl=$inv.ApplicationAddIns.ItemById($STLID)
    $ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=13059
    $opts=$inv.TransientObjects.CreateNameValueMap()
    $data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=($path -replace '\.ipt$','.stl')
    if($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
    $stl.SaveCopyAs($doc,$ctx,$opts,$data)
    $doc.Close($true)
    Write-Host ("FERTIG: {0}" -f (Split-Path $path -Leaf))
}

# ===== TEIL 1: Servo-Halterung (SG90 23x12.5x22mm) =====
Write-Host "1) Servo-Halterung..."
$doc=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)

# Gehaeuse-Block
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P -14 -8),(P 14 8)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 26*$f, $kPos, $kJoin) | Out-Null
# Ausschnitt fuer Servo-Koerper
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY,4*$f); $top.Visible=$false
$s=$cd.Sketches.Add($top)
$s.SketchLines.AddAsTwoPointRectangle((P -11.5 -6.25),(P 11.5 6.25)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 22*$f, $kNeg, $kCut) | Out-Null
# Servo-Achsen-Bohrung oben
$top2=$cd.WorkPlanes.AddByPlaneAndOffset($XY,26*$f); $top2.Visible=$false
$s=$cd.Sketches.Add($top2)
$s.SketchCircles.AddByCenterRadius((P 0 0), 2.5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kNeg, $kCut) | Out-Null
# Montage-Loecher (2x M2 Servo-Flansch)
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P -14 0), 1.0*$f) | Out-Null
$s.SketchCircles.AddByCenterRadius((P 14 0), 1.0*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kPos, $kCut) | Out-Null
SaveDoc $doc "H:\ZwickRoell Projekt\Servo_Halterung.ipt"

# ===== TEIL 2: Kupplungsscheibe (dreht 90 grad, koppelt Motor an X oder Y) =====
Write-Host "2) Kupplungsscheibe..."
$doc=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)
$XZ=$cd.WorkPlanes.Item(2)

# Haupt-Scheibe Ø50mm, 8mm dick
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 25*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null
# Servo-Achsen-Bohrung zentral (Ø5mm, SG90-Achse mit Rillen -> leicht enger)
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 2.4*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 9*$f, $kPos, $kCut) | Out-Null
# Kupplung-Aufnahme A (Y-Achse, bei 0 Grad): Halbkreis-Schlitz Ø10mm bei X=+18mm
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 18 0), 5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut) | Out-Null
# Kupplung-Aufnahme B (X-Achse, bei 90 Grad): Schlitz bei Y=+18mm
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 18), 5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut) | Out-Null
# Verstaerkungs-Stege zwischen Aufnahmen (optisch + mechanisch)
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P -2 0),(P 2 20)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P 0 -2),(P 20 2)) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null
SaveDoc $doc "H:\ZwickRoell Projekt\Kupplungsscheibe.ipt"

Write-Host "Servo-Teile fertig."
