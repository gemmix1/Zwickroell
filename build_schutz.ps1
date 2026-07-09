# Schutzteile v5:
#  - Kopf_Bruecke: verbindet die beiden Wellen-Enden oben (Presssitz Ø7.8),
#    Spindel-Durchlass Ø10.5 mittig -> Fingerschutz + versteift die Fuehrung.
#  - Motor_Fensterdeckel (2x): Einsteck-Deckel fuer die Motorblock-Fenster
#    (rotierende Kupplung abgedeckt; zum Einstellen abziehbar).
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
function NewPart(){ $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart)); try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d }
function SaveDoc($doc,$name){
  $vol=$doc.ComponentDefinition.MassProperties.Volume
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
  Write-Host ("FERTIG {0,-22} Vol={1,6:N2} cm3" -f $name,$vol)
}

# ---- Kopf_Bruecke: 60(Y) x 20(X) x 14, Wellenbohrungen (0,+-22) Ø7.8 x 10 blind,
#      Spindel-Durchlass Ø10.5 durch ----
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -10 -30 10 30
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 14*$f, $kPos, $kJoin)|Out-Null
foreach($sy in -1,1){                             # Wellen-Presssitze von unten
  $s=$cd.Sketches.Add($XY); Circ $s 0 ($sy*22) 7.8
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 10*$f, $kPos, $kCut)|Out-Null
}
$topB=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 14*$f); $topB.Visible=$false
$s=$cd.Sketches.Add($topB); Circ $s 0 0 10.5      # Spindel-Durchlass
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 14.2*$f, $kNeg, $kCut)|Out-Null
SaveDoc $doc "Kopf_Bruecke"

# ---- Motor_Fensterdeckel: Platte 22x28x2 + Einsteck-Lippe 15.5x21.5x3 ----
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -11 -14 11 14
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 2*$f, $kPos, $kJoin)|Out-Null
$topD=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 2*$f); $topD.Visible=$false
$s=$cd.Sketches.Add($topD); Rect $s -7.75 -10.75 7.75 10.75
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3*$f, $kPos, $kJoin)|Out-Null
SaveDoc $doc "Motor_Fensterdeckel"

Write-Host "Schutzteile fertig."