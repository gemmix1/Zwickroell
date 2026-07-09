# Kupplungsscheibe v2: auf Motor-Welle gepresst, 2 Mitnehmer-Stifte (90° versetzt)
# Servo dreht Scheibe 90° -> Stift A koppelt Y-Stange, Stift B koppelt X-Stange
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
$XY=$cd.WorkPlanes.Item(3)
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }

Write-Host "1) Haupt-Scheibe Ø52mm, 12mm dick..."
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 26*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kPos, $kJoin) | Out-Null
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY,12*$f); $top.Visible=$false

Write-Host "2) Motor-Wellen-Presspassung Ø3mm..."
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 1.5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 13*$f, $kPos, $kCut) | Out-Null

Write-Host "3) Mitnehmer-Stift A (Y-Stange, 0°): Zylinder Ø6x8 bei X=+20mm..."
$s=$cd.Sketches.Add($top)
$s.SketchCircles.AddByCenterRadius((P 20 0), 3*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null

Write-Host "4) Mitnehmer-Stift B (X-Stange, 90°): Zylinder Ø6x8 bei Y=+20mm..."
$s=$cd.Sketches.Add($top)
$s.SketchCircles.AddByCenterRadius((P 0 20), 3*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null

Write-Host "5) Servo-Verbindungsbohrung Ø4mm bei Y=+20mm (Seite)..."
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 20 0), 2*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kPos, $kCut) | Out-Null

Write-Host "6) Leichtbau: 4x Ø10mm Tasche diagonal..."
$s=$cd.Sketches.Add($XY)
foreach($ang in 45,135,225,315){
    $rx=[Math]::Cos($ang*[Math]::PI/180)*13
    $ry=[Math]::Sin($ang*[Math]::PI/180)*13
    $s.SketchCircles.AddByCenterRadius((P $rx $ry), 5*$f) | Out-Null
}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut) | Out-Null

Write-Host "7) Speichern..."
$out="H:\ZwickRoell Projekt\Kupplungsscheibe_v2"
if(Test-Path "$out.ipt"){Remove-Item "$out.ipt" -Force}
$doc.SaveAs("$out.ipt",$false)
$a=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName="$out.stl"
if($a.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
$a.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
Write-Host ("FERTIG: Kupplungsscheibe_v2.ipt ({0:N0} KB)" -f ((Get-Item "$out.ipt").Length/1KB))
