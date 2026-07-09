# ============================================================
#  Rahmen_v4 — Traeger fuer das Kontakt-Mikrometer.
#  Weltachsen (= Baugruppe):
#   Z = senkrecht (Spindel/Taster-Hub).  Probenachse (Servo-Drehachse) = Y.
#   Grundplatte oben bei z=8. Probenachse-Hoehe world z = 60.
#  Enthaelt: Grundplatte, 2 Wellenaufnahmen (Ø8, bei x=+-22, y=-14),
#            Spindel-/Motorloch (x=0,y=-14), Servo-Wand (-Y) mit Wellenloch +
#            Index-Pin-Loch, Idler-Wand (+Y) mit Journal.
#  Inventor-API in cm -> Faktor 0.1. Ausgabe via $PSScriptRoot.
# ============================================================
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$plate_L=220.0; $plate_W=140.0; $plate_T=8.0     # Grundplatte (X,Y,Z), Oberseite z=8
# Wellen bei x=-14, y=+-22 (versetzt, damit Spindel die Probe bei x=0 NICHT trifft)
$rod_cx=-14.0; $rod_cy=22.0
$boss_d=16.0; $boss_h=20.0; $rod_bore=7.8; $rod_depth=16.0
$spin_x=-14.0; $spin_y=0.0; $spin_bore=9.0        # Spindel/Motor-Durchgang (x=-14)
$axis_z=60.0                                      # Probenachse-Hoehe (world z)
$wall_t=8.0; $wall_w=80.0; $wall_top=80.0          # Endwaende (Dicke Y, Breite X, Hoehe z)
$servo_y=-91.0; $idler_y=91.0                      # Wand-Mitten (Y)
$shaft_d=14.0; $idx_d=3.0; $idx_r=16.0; $journal_d=8.3

$f = 0.1
$outIpt = Join-Path $PSScriptRoot "Rahmen_v4.ipt"
$outStl = Join-Path $PSScriptRoot "Rahmen_v4.stl"
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $kSym=20995; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

Write-Host "Verbinde mit Inventor..."
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }

$tg=$inv.TransientGeometry
$doc=$inv.Documents.Add($kPart, $inv.FileManager.GetTemplateFile($kPart))
try { $doc.UnitsOfMeasure.LengthUnits=$mmU } catch {}
$cd=$doc.ComponentDefinition; $ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)   # normal Z
$XZ=$cd.WorkPlanes.Item(2)   # normal Y
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function Circ($sk,$cx,$cy,$dia){ $sk.SketchCircles.AddByCenterRadius((P $cx $cy),($dia/2)*$f)|Out-Null }
function Rect($sk,$x1,$y1,$x2,$y2){ $sk.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2))|Out-Null }

Write-Host "1) Grundplatte (z 0..8)..."
$s=$cd.Sketches.Add($XY); Rect $s (-$plate_L/2) (-$plate_W/2) ($plate_L/2) ($plate_W/2)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $plate_T*$f, $kPos, $kJoin) | Out-Null

Write-Host "2) Wellenaufnahmen (Bosse Ø16, z 0..20)..."
foreach ($sy in -1,1){
  $s=$cd.Sketches.Add($XY); Circ $s $rod_cx ($sy*$rod_cy) $boss_d
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $boss_h*$f, $kPos, $kJoin) | Out-Null
}

Write-Host "3) Endwaende Servo (-Y) + Idler (+Y), z 0..80..."
$s=$cd.Sketches.Add($XY); Rect $s (-$wall_w/2) ($servo_y-$wall_t/2) ($wall_w/2) ($servo_y+$wall_t/2)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $wall_top*$f, $kPos, $kJoin) | Out-Null
$s=$cd.Sketches.Add($XY); Rect $s (-$wall_w/2) ($idler_y-$wall_t/2) ($wall_w/2) ($idler_y+$wall_t/2)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $wall_top*$f, $kPos, $kJoin) | Out-Null

# ---- Loecher ----
$topB=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $boss_h*$f); $topB.Visible=$false
$topP=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $plate_T*$f); $topP.Visible=$false

Write-Host "4) Wellen-Bohrungen (Ø7.8, blind von oben)..."
foreach ($sy in -1,1){
  $s=$cd.Sketches.Add($topB); Circ $s $rod_cx ($sy*$rod_cy) $rod_bore
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $rod_depth*$f, $kNeg, $kCut) | Out-Null
}

Write-Host "5) Spindel-/Motorloch (Ø9 durch Platte)..."
$s=$cd.Sketches.Add($topP); Circ $s $spin_x $spin_y $spin_bore
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($plate_T+1)*$f, $kNeg, $kCut) | Out-Null

Write-Host "6) Servo-Wand: Wellenloch Ø14 + Index-Pin Ø3 (Ebene in Wand + kSym)..."
$psv=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, $servo_y*$f); $psv.Visible=$false
$s=$cd.Sketches.Add($psv); Circ $s 0 $axis_z $shaft_d          # in XZ: x->X, y->Z
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($wall_t+4)*$f, $kSym, $kCut) | Out-Null
$s=$cd.Sketches.Add($psv); Circ $s $idx_r $axis_z $idx_d
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($wall_t+4)*$f, $kSym, $kCut) | Out-Null

Write-Host "7) Idler-Wand: Journal Ø8.3..."
$pIdl=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, $idler_y*$f); $pIdl.Visible=$false
$s=$cd.Sketches.Add($pIdl); Circ $s 0 $axis_z $journal_d
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($wall_t+4)*$f, $kSym, $kCut) | Out-Null

Write-Host "8) Speichern .ipt + .stl..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$mp=$cd.MassProperties; Write-Host ("Volumen_cm3={0:N2}" -f $mp.Volume)
$doc.Close($true)
Write-Host "FERTIG: Rahmen_v4"