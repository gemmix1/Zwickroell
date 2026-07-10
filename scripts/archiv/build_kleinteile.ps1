# ============================================================
#  Kleinteile fuer das Kontakt-Mikrometer (v4):
#   - Fuehrungswelle Ø8 x 150 (glatte Linearwelle, 2x im Aufbau)
#   - Idler_Klemme: Gegenlager-Klemme (Zentriertasche 20x6 + Ø8-Zapfen im Journal)
#  Inventor-API in cm -> Faktor 0.1. Ausgabe via $PSScriptRoot.
# ============================================================
$ErrorActionPreference = "Stop"
$f = 0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function NewPart(){ $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart)); try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d }
function SaveDoc($doc,$name){
  $ipt=Join-Path $PSScriptRoot ($name+".ipt"); $stlP=Join-Path $PSScriptRoot ($name+".stl")
  if(Test-Path $ipt){Remove-Item $ipt -Force}
  $doc.SaveAs($ipt,$false)
  $stl=$inv.ApplicationAddIns.ItemById($STLID)
  $ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
  $opts=$inv.TransientObjects.CreateNameValueMap()
  $data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$stlP
  if($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
  $stl.SaveCopyAs($doc,$ctx,$opts,$data)
  $doc.Close($true)
  Write-Host ("FERTIG: {0}" -f $name)
}

# ===== Fuehrungswelle Ø8 x 150 =====
Write-Host "1) Fuehrungswelle Ø8x150..."
$doc=NewPart; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0), 4.0*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 150*$f, $kPos, $kJoin) | Out-Null
SaveDoc $doc "Fuehrungswelle_8x150"

# ===== Idler_Klemme =====
Write-Host "2) Idler_Klemme..."
$bx=28.0; $by=16.0; $bz=34.0; $pkt_x=20.2; $pkt_y=6.2; $pkt_d=24.0; $stub_d=8.0; $stub_h=14.0
$doc=NewPart; $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures; $XY=$cd.WorkPlanes.Item(3)
# Koerper
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P (-$bx/2) (-$by/2)),(P ($bx/2) ($by/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $bz*$f, $kPos, $kJoin) | Out-Null
# Zentrier-Tasche (oben) - Material dahinter -> Cut ok
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $bz*$f); $top.Visible=$false
$s=$cd.Sketches.Add($top)
$s.SketchLines.AddAsTwoPointRectangle((P (-$pkt_x/2) (-$pkt_y/2)),(P ($pkt_x/2) ($pkt_y/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $pkt_d*$f, $kNeg, $kCut) | Out-Null
# Ø8-Zapfen nach unten (Journal) - Einzelkreis Join
$s=$cd.Sketches.Add($XY); $s.SketchCircles.AddByCenterRadius((P 0 0), ($stub_d/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $stub_h*$f, $kNeg, $kJoin) | Out-Null
SaveDoc $doc "Idler_Klemme"

Write-Host "Kleinteile fertig."