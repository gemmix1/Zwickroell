# M8-Gewindestange mit sichtbarem Gewinde (Ringnut-Pattern, M8x1.25)
# Methode: 1 Ringnut (Annular-Cut) auf XY-paralleler Ebene, dann Rectangular-Pattern
# -> kompatibel mit allen Inventor-Versionen via COM-API
$ErrorActionPreference = "Stop"

$length    = 180.0
$major_r   = 4.0
$minor_r   = 3.25     # Kern-Radius
$pitch     = 1.25
$groove_w  = 0.75     # Nutbreite (Zahnbreite = pitch - groove_w = 0.5mm)
$num_turns = [int]($length / $pitch)   # 144 Gaenge

$f = 0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"
$outIpt = "H:\ZwickRoell Projekt\Gewindestange_M8.ipt"
$outStl = "H:\ZwickRoell Projekt\Gewindestange_M8.stl"

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
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }

Write-Host "1) Basis-Zylinder Ø$($major_r*2) x $($length)mm..."
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), $major_r*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $length*$f, $kPos, $kJoin) | Out-Null

Write-Host "2) Erste Ringnut bei Z=$($pitch/2)mm..."
$ring_z = $pitch / 2
$rp=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $ring_z*$f); $rp.Visible=$false
$rs=$cd.Sketches.Add($rp)
$rs.SketchCircles.AddByCenterRadius((P 0 0), $major_r*$f) | Out-Null
$rs.SketchCircles.AddByCenterRadius((P 0 0), $minor_r*$f) | Out-Null
$ring_profile=$rs.Profiles.AddForSolid()
Write-Host "   Ring-Profil-Regionen: $($rs.Profiles.Count)"
$ring_cut=$ef.AddByDistanceExtent($ring_profile, $groove_w*$f, $kSym, $kCut)
Write-Host "   Erste Nut OK"

Write-Host "3) Rectangular-Pattern: $num_turns Gaenge, Abstand=$pitch mm..."
try {
    $feat_coll=$inv.TransientObjects.CreateObjectCollection()
    $feat_coll.Add($ring_cut)
    $rpf=$cd.Features.RectangularPatternFeatures
    $rpIn=$rpf.CreateRectangularPatternInput($feat_coll, $cd.WorkAxes.Item(3))
    $rpIn.SetCountAndSpacing($num_turns, $pitch*$f, $kPos)
    $rpf.Add($rpIn) | Out-Null
    Write-Host "   Pattern OK ($num_turns Ringnuten)"
} catch {
    Write-Host "   Pattern nicht verfuegbar, erstelle Nuten manuell (30 Gaenge)..."
    for ($i=1; $i -lt 30; $i++) {
        $z=$i*$pitch + $ring_z
        if ($z -ge $length) { break }
        $wp2=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $z*$f); $wp2.Visible=$false
        $sk2=$cd.Sketches.Add($wp2)
        $sk2.SketchCircles.AddByCenterRadius((P 0 0), $major_r*$f) | Out-Null
        $sk2.SketchCircles.AddByCenterRadius((P 0 0), $minor_r*$f) | Out-Null
        $ef.AddByDistanceExtent($sk2.Profiles.AddForSolid(), $groove_w*$f, $kSym, $kCut) | Out-Null
    }
    Write-Host "   Manuell 30 Gaenge erstellt"
}

Write-Host "4) Speichern..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=13059
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=2}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
foreach($file in @($outIpt,$outStl)){
    if(Test-Path $file){ Write-Host ("FERTIG: {0} ({1:N0} KB)" -f $file,((Get-Item $file).Length/1KB)) }
}
