# Baut die 3 rechteck-Platzhalter (Probe/Servo/Motor) sauber neu und prueft Volumen.
$ErrorActionPreference="Stop"; $f=0.1
$kPart=12290; $kJoin=20485; $kPos=20993; $mmU=11811; $dir=Join-Path $PSScriptRoot "..\cad"
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

function BuildBox($name,$wx,$wy,$hz,$shaftDia,$shaftLen){
  $doc=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart))
  try{$doc.UnitsOfMeasure.LengthUnits=$mmU}catch{}
  $cd=$doc.ComponentDefinition; $XY=$cd.WorkPlanes.Item(3); $ef=$cd.Features.ExtrudeFeatures
  $s=$cd.Sketches.Add($XY)
  $p1=$tg.CreatePoint2d((-$wx/2)*$f,(-$wy/2)*$f); $p2=$tg.CreatePoint2d(($wx/2)*$f,($wy/2)*$f)
  $s.SketchLines.AddAsTwoPointRectangle($p1,$p2) | Out-Null
  $prof=$s.Profiles.AddForSolid()
  $ex=$ef.AddByDistanceExtent($prof,$hz*$f,$kPos,$kJoin)
  if($shaftDia -gt 0){
    $pl=$cd.WorkPlanes.AddByPlaneAndOffset($XY,$hz*$f); $pl.Visible=$false
    $s2=$cd.Sketches.Add($pl); $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0),($shaftDia/2)*$f)|Out-Null
    $ef.AddByDistanceExtent($s2.Profiles.AddForSolid(),$shaftLen*$f,$kPos,$kJoin)|Out-Null
  }
  $vol=$cd.MassProperties.Volume
  $pp=Join-Path $dir ($name+".ipt"); if(Test-Path $pp){Remove-Item $pp -Force}
  $doc.SaveAs($pp,$false); $doc.Close($true)
  Write-Host ("{0,-16} Vol_cm3={1:N3}" -f $name,$vol)
}

BuildBox "Probe_Platzhalter" 20 166 6  0 0
BuildBox "Servo_SG90"        23 12  22 4.8 14
BuildBox "Motor_N20_ph"      12 12  28 3.0 12


