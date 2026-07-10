# Stuetze v2 fuer 2-Achs-Aufbau (X und Y Stangen)
# Lagert eine horizontale M8-Stange auf Hoehe 70mm
# Breiter Fuss mit 4 Befestigungslöchern, seitliche Rippen fuer Stabilitaet
$ErrorActionPreference = "Stop"

$fuss_L   = 50.0   # Fuss-Laenge (X)
$fuss_W   = 30.0   # Fuss-Breite (Y)
$fuss_T   = 4.0    # Fuss-Dicke  (Z, Auflageplatte)
$steg_W   = 14.0   # Steg-Breite  (Y)
$steg_T   = 8.0    # Steg-Dicke   (X)
$hoehe    = 72.0   # Gesamthoehe (Z) bis Stangen-Mitte
$m8_bore  = 8.5    # Durchgang M8-Stange
$lager_R  = 7.0    # Lagerblock-Radius (Zylindrisch um M8-Bohrung)
$rippe_T  = 3.0    # Rippen-Dicke
$mnt_dia  = 3.5    # Fuss-Schrauben M3.5
$mnt_dx   = 18.0   # Schrauben-Abstand X vom Fuss-Zentrum
$mnt_dy   = 10.0   # Schrauben-Abstand Y vom Fuss-Zentrum

$f = 0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"
$outIpt = "H:\ZwickRoell Projekt\Stuetze_v2.ipt"
$outStl = "H:\ZwickRoell Projekt\Stuetze_v2.stl"

Write-Host "Verbinde mit Inventor..."
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }

$tg=$inv.TransientGeometry
$doc=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
try { $doc.UnitsOfMeasure.LengthUnits=$mmU } catch {}
$cd=$doc.ComponentDefinition
$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)
$XZ=$cd.WorkPlanes.Item(2)
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function JoinRect($x1,$y1,$x2,$y2,$h){
    $s=$cd.Sketches.Add($XY)
    $s.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2)) | Out-Null
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $h*$f, $kPos, $kJoin) | Out-Null
}

Write-Host "1) Fussplatte..."
JoinRect (-$fuss_L/2) (-$fuss_W/2) ($fuss_L/2) ($fuss_W/2) $fuss_T

Write-Host "2) Vertikaler Steg..."
JoinRect (-$steg_T/2) (-$steg_W/2) ($steg_T/2) ($steg_W/2) ($hoehe - $lager_R)

Write-Host "3) Lagerblock (Zylinder oben)..."
$lager_plane=$cd.WorkPlanes.AddByPlaneAndOffset($XY, ($hoehe-$lager_R)*$f); $lager_plane.Visible=$false
$s=$cd.Sketches.Add($lager_plane)
$s.SketchCircles.AddByCenterRadius((P 0 0), $lager_R*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($lager_R*2)*$f, $kPos, $kJoin) | Out-Null

Write-Host "4) Seitliche Verstaerungs-Rippen..."
# Rippe links
$s=$cd.Sketches.Add($XZ)  # XZ-Ebene, U=X, V=Z
# Dreieck-Rippe: (steg_T/2, fuss_T) -> (steg_T/2+rippe_T, fuss_T) -> (steg_T/2, hoehe-lager_R-5)
$rp1=$tg.CreatePoint2d(($steg_T/2)*$f, $fuss_T*$f)
$rp2=$tg.CreatePoint2d(($steg_T/2+8)*$f, $fuss_T*$f)
$rp3=$tg.CreatePoint2d(($steg_T/2)*$f, ($hoehe-$lager_R-10)*$f)
$s.SketchLines.AddByTwoPoints($rp1,$rp2) | Out-Null
$s.SketchLines.AddByTwoPoints($rp2,$rp3) | Out-Null
$s.SketchLines.AddByTwoPoints($rp3,$rp1) | Out-Null
try { $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $rippe_T*$f, $kSym, $kJoin) | Out-Null } catch {}

# Rippe rechts (gespiegelt)
$s2=$cd.Sketches.Add($XZ)
$rp4=$tg.CreatePoint2d((-$steg_T/2)*$f, $fuss_T*$f)
$rp5=$tg.CreatePoint2d((-$steg_T/2-8)*$f, $fuss_T*$f)
$rp6=$tg.CreatePoint2d((-$steg_T/2)*$f, ($hoehe-$lager_R-10)*$f)
$s2.SketchLines.AddByTwoPoints($rp4,$rp5) | Out-Null
$s2.SketchLines.AddByTwoPoints($rp5,$rp6) | Out-Null
$s2.SketchLines.AddByTwoPoints($rp6,$rp4) | Out-Null
try { $ef.AddByDistanceExtent($s2.Profiles.AddForSolid(), $rippe_T*$f, $kSym, $kJoin) | Out-Null } catch {}

Write-Host "5) M8-Bohrung (horizontal, in Y durch Lagerblock)..."
$YZ=$cd.WorkPlanes.Item(1)  # YZ-Ebene, U=Y, V=Z
$s=$cd.Sketches.Add($YZ)
$s.SketchCircles.AddByCenterRadius((P 0 $hoehe), ($m8_bore/2)*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($fuss_L+1)*$f, $kSym, $kCut) | Out-Null

Write-Host "6) Fuss-Befestigungsloecher (4x M3.5)..."
$s=$cd.Sketches.Add($XY)
foreach ($sx in -1,1) { foreach ($sy in -1,1) {
    $s.SketchCircles.AddByCenterRadius((P ($sx*$mnt_dx) ($sy*$mnt_dy)), ($mnt_dia/2)*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($fuss_T+1)*$f, $kPos, $kCut) | Out-Null

Write-Host "7) Speichern..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=13059
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
foreach($file in @($outIpt,$outStl)){
    if(Test-Path $file){ Write-Host ("FERTIG: {0} ({1:N0} KB)" -f $file,((Get-Item $file).Length/1KB)) }
}
