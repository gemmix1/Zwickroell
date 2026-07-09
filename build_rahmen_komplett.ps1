# Baut alle Rahmen- und Halterungs-Teile:
#   1) Aluprofil 20x20 (4 Laengen) — jede Nut als eigene Skizze (kein shared-edge Problem)
#   2) Eckverbinder L-Winkel
#   3) Motor-Servo-Halterung (Motor N20 + SG90 an Rahmenecke)
#   4) Kupplungsscheibe v2 (2 Mitnehmer-Stifte, 90° versetzt)
$ErrorActionPreference = "Stop"

$f=0.1
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

function NewDoc {
    $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart))
    try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d
}
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function SkRect($cd,$plane,$x1,$y1,$x2,$y2){
    $s=$cd.Sketches.Add($plane)
    $s.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2)) | Out-Null
    return $s
}
function Save($doc,$base){
    $ipt="H:\ZwickRoell Projekt\$base.ipt"
    $stl="H:\ZwickRoell Projekt\$base.stl"
    if(Test-Path $ipt){Remove-Item $ipt -Force}
    $doc.SaveAs($ipt,$false)
    $a=$inv.ApplicationAddIns.ItemById($STLID)
    $ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
    $opts=$inv.TransientObjects.CreateNameValueMap()
    $data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$stl
    if($a.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
    $a.SaveCopyAs($doc,$ctx,$opts,$data)
    $doc.Close($true)
    if(Test-Path $ipt){ Write-Host ("  OK: {0} ({1:N0} KB)" -f $base,((Get-Item $ipt).Length/1KB)) }
}

# ============================================================
# 1) ALUPROFIL 20x20 — jedes Feature hat eigene Skizze
# ============================================================
Write-Host "--- Aluprofil 20x20 ---"
foreach ($cfg in @(
    @{name="Aluprofil_20x20_L300"; L=300},
    @{name="Aluprofil_20x20_L180"; L=180},
    @{name="Aluprofil_20x20_H100"; L=100},
    @{name="Aluprofil_20x20_L260"; L=260}
)) {
    $doc=NewDoc
    $cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
    $XY=$cd.WorkPlanes.Item(3)
    # --- Solid 20x20 ---
    $s=(SkRect $cd $XY -10 -10 10 10)
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $cfg.L*$f, $kPos, $kJoin) | Out-Null
    # --- Inner hollow 8x8 ---
    $s=(SkRect $cd $XY -4 -4 4 4)
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $cfg.L*$f, $kPos, $kCut) | Out-Null
    # --- T-Nuten: jede einzeln (keine shared edges) ---
    foreach ($slot in @(
        @{x1=-3;y1= 6;x2= 3;y2=10},  # oben
        @{x1=-3;y1=-10;x2= 3;y2=-6},  # unten
        @{x1=-10;y1=-3;x2=-6;y2=3},   # links
        @{x1= 6;y1=-3;x2=10;y2=3}     # rechts
    )) {
        $s=(SkRect $cd $XY $slot.x1 $slot.y1 $slot.x2 $slot.y2)
        try{ $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $cfg.L*$f, $kPos, $kCut) | Out-Null } catch{}
    }
    # --- M5-Stirnbohrungen (beide Enden) ---
    $endPlane=$cd.WorkPlanes.AddByPlaneAndOffset($XY,$cfg.L*$f); $endPlane.Visible=$false
    foreach ($pl in @($XY,$endPlane)){
        $sh=$cd.Sketches.Add($pl)
        $sh.SketchCircles.AddByCenterRadius((P 0 0), 2.5*$f) | Out-Null
        $ef.AddByDistanceExtent($sh.Profiles.AddForSolid(), 10*$f, $kPos, $kCut) | Out-Null
    }
    Save $doc $cfg.name
}

# ============================================================
# 2) ECKVERBINDER L-Winkel 20x20x3mm
# ============================================================
Write-Host "--- Eckverbinder ---"
$doc=NewDoc
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)
# Sockel-Platte 20x20x3
$s=(SkRect $cd $XY -10 -10 10 10)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3*$f, $kPos, $kJoin) | Out-Null
# Senkrechter Schenkel (20x3x17) nach oben
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 3*$f); $top.Visible=$false
$s=(SkRect $cd $top -10 7 10 10)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 17*$f, $kPos, $kJoin) | Out-Null
# Bohrungen waagrecht (M5 Durchgang)
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 -5), 2.7*$f) | Out-Null
$s.SketchCircles.AddByCenterRadius((P 0 5), 2.7*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3*$f, $kPos, $kCut) | Out-Null
# Bohrung senkrecht
$XZ=$cd.WorkPlanes.Item(2)
$s=$cd.Sketches.Add($XZ)
$s.SketchCircles.AddByCenterRadius((P 0 3), 2.7*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 20*$f, $kSym, $kCut) | Out-Null
Save $doc "Eckverbinder_20x20"

# ============================================================
# 3) MOTOR-SERVO-HALTERUNG (50x70x34mm Block)
# ============================================================
Write-Host "--- Motor-Servo-Halterung ---"
$doc=NewDoc
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3); $XZ=$cd.WorkPlanes.Item(2); $YZ=$cd.WorkPlanes.Item(1)

# Basis-Block 50x70x4
$s=(SkRect $cd $XY -25 -35 25 35)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kPos, $kJoin) | Out-Null
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 4*$f); $top.Visible=$false

# Motor-Block rechts: 14x12x30mm
$s=(SkRect $cd $top 10 -6 24 6)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 30*$f, $kPos, $kJoin) | Out-Null
# Motorhoehlung (12x10mm von oben, kPos = nach oben geht rein)
$mTop=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 34*$f); $mTop.Visible=$false
$s=(SkRect $cd $mTop 11 -5 23 5)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 26*$f, $kNeg, $kCut) | Out-Null
# Wellendurchgang Ø4mm (YZ-Ebene, Motor-Achse in Y-Richtung)
$s=$cd.Sketches.Add($YZ)
$s.SketchCircles.AddByCenterRadius((P 0 20), 2*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 55*$f, $kPos, $kCut) | Out-Null

# Servo-Block links: 23x16x28mm
$s=(SkRect $cd $top -25 -8 -2 8)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 28*$f, $kPos, $kJoin) | Out-Null
# Servo-Schlitz (23x12.5mm) von oben
$sTop=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 32*$f); $sTop.Visible=$false
$s=(SkRect $cd $sTop -24 -6.3 -2 6.3)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 22*$f, $kNeg, $kCut) | Out-Null
# Servo-Wellenbohrung Ø5mm oben
$s=$cd.Sketches.Add($top)
$s.SketchCircles.AddByCenterRadius((P -14 0), 2.5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kNeg, $kCut) | Out-Null

# 4x M4 Befestigung an Rahmen
$s=$cd.Sketches.Add($XY)
foreach($sx in -1,1){ foreach($sy in -1,1){
    $s.SketchCircles.AddByCenterRadius((P ($sx*18) ($sy*26)), 2*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 5*$f, $kPos, $kCut) | Out-Null
Save $doc "Motorhalterung"

# ============================================================
# 4) KUPPLUNGSSCHEIBE v2 (Ø52, 2 Stifte, Leichtbau-Ausfraesungen)
# ============================================================
Write-Host "--- Kupplungsscheibe v2 ---"
$doc=NewDoc
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)

# Haupt-Scheibe Ø52x12
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 26*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kPos, $kJoin) | Out-Null
$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 12*$f); $top.Visible=$false

# Motor-Wellen-Presspassung Ø3mm zentral
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 0), 1.5*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 13*$f, $kPos, $kCut) | Out-Null

# Mitnehmer-Stift A (Y-Stange, 0°): Zylinder Ø6x8 bei X=+20
$s=$cd.Sketches.Add($top)
$s.SketchCircles.AddByCenterRadius((P 20 0), 3*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null

# Mitnehmer-Stift B (X-Stange, 90°): Zylinder Ø6x8 bei Y=+20
$s=$cd.Sketches.Add($top)
$s.SketchCircles.AddByCenterRadius((P 0 20), 3*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin) | Out-Null

# Servo-Verbindungsbohrung Ø4 bei R=20, Winkel=45°
$s=$cd.Sketches.Add($XY)
$s.SketchCircles.AddByCenterRadius((P 0 20), 2*$f) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kPos, $kCut) | Out-Null

# Leichtbau: 4x Ø10 Ausfraesungen diagonal
$s=$cd.Sketches.Add($XY)
foreach($ang in 45,135,225,315){
    $rx=[Math]::Cos($ang*[Math]::PI/180)*13
    $ry=[Math]::Sin($ang*[Math]::PI/180)*13
    $s.SketchCircles.AddByCenterRadius((P $rx $ry), 5*$f) | Out-Null
}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut) | Out-Null
Save $doc "Kupplungsscheibe_v2"

Write-Host "`n=== Alle Rahmen-Teile fertig ==="
Get-ChildItem "H:\ZwickRoell Projekt\*.ipt" | Where-Object{ $_.Name -match "Aluprofil|Eckverb|Motorhalterung|Kupplungsscheibe_v2" } |
    Select-Object Name,@{N="KB";E={[int]($_.Length/1KB)}} | Format-Table -Auto
