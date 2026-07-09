# Taster_Schlitten_M8 — Variante fuer normale M8-Gewindestange als Spindel:
# Ø8.6-Spindelbohrung + Sechskantmutter-Tasche (13.4 x 15.6 x 7) von unten,
# statt T8-Flanschmutter-Aufnahme. Rest identisch zum Standard-Schlitten.
$ErrorActionPreference="Stop"; $f=0.1
$kPart=12290;$kJoin=20485;$kCut=20482;$kPos=20993;$kNeg=20994;$mmU=11811
$kBrowse=13059;$STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"
try{$inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application")}
catch{$inv=New-Object -ComObject Inventor.Application}
$inv.Visible=$false;$inv.SilentOperation=$true
while($inv.Documents.Count -gt 0){$inv.Documents.Item(1).Close($true)}
$tg=$inv.TransientGeometry
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function Circ($sk,$cx,$cy,$dia){ $sk.SketchCircles.AddByCenterRadius((P $cx $cy),($dia/2)*$f)|Out-Null }
function Rect($sk,$x1,$y1,$x2,$y2){
  $xa=[math]::Min($x1,$x2);$xb=[math]::Max($x1,$x2);$ya=[math]::Min($y1,$y2);$yb=[math]::Max($y1,$y2)
  $sk.SketchLines.AddAsTwoPointRectangle((P $xa $ya),(P $xb $yb))|Out-Null
}
$doc=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart))
try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}
$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3);$XZ=$cd.WorkPlanes.Item(2)
$s=$cd.Sketches.Add($XY); Rect $s -34 -20 34 20
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Rect $s 4 20 24 26
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$top24=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 24*$f); $top24.Visible=$false
$s=$cd.Sketches.Add($top24); Rect $s 4 16 24 26
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 16*$f, $kPos, $kJoin)|Out-Null
$choles=@( @(-22,0,15.0), @(22,0,15.0), @(0,0,8.6), @(0,14,6.4) )   # M8-Bohrung 8.6!
foreach($h in $choles){
  $s=$cd.Sketches.Add($top24); Circ $s $h[0] $h[1] $h[2]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24.2*$f, $kNeg, $kCut)|Out-Null
}
$s=$cd.Sketches.Add($XY); Rect $s -6.7 -7.8 6.7 7.8    # Sechskant-Tasche (SW13, Ecken 15.6)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 7*$f, $kPos, $kCut)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 14 13.0
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 14*$f, $kPos, $kCut)|Out-Null
foreach($hx in -9,9){
  $s=$cd.Sketches.Add($XY); Circ $s $hx 14 2.0
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut)|Out-Null
}
$pBoss=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, 16*$f); $pBoss.Visible=$false
foreach($hx in 9,18.5){
  $s=$cd.Sketches.Add($pBoss); Circ $s $hx 34 2.4
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 10.2*$f, $kPos, $kCut)|Out-Null
}
$vol=$cd.MassProperties.Volume
$ipt=Join-Path $PSScriptRoot "Taster_Schlitten_M8.ipt"; $stlP=Join-Path $PSScriptRoot "Taster_Schlitten_M8.stl"
if(Test-Path $ipt){Remove-Item $ipt -Force}
$doc.SaveAs($ipt,$false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$stlP
if($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
Write-Host ("FERTIG Taster_Schlitten_M8  Vol={0:N2} cm3" -f $vol)