# ============================================================
#  Taster-Schlitten fuer das Kontakt-Mikrometer (Messprogramm v4).
#  Laeuft auf 2 senkrechten Fuehrungsstangen (LM8UU), in der Mitte die
#  M8-Spindelmutter (vom DC-Motor gedreht -> Schlitten faehrt in Z).
#  Vorne: federgelagerter Taststift (Ø4) + Mikroschalter (D2F) als Kontaktmelder.
#  Inventor-API in cm -> Faktor 0.1. Ausgabe neben diesem Script ($PSScriptRoot).
# ============================================================
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$bx = 64.0   # Body X
$by = 40.0   # Body Y
$bz = 24.0   # Body Z (>= LM8UU-Laenge 24)

$rod_cc   = 44.0   # Stangenabstand (LM8UU-Zentren)
$lm_d     = 15.0   # LM8UU Aussen-Ø (Presssitz)

$nut_af   = 13.3   # M8-Mutter SW13 (+Spiel), quadratische Tasche (dreht nicht mit)
$nut_len  = 14.0
$nut_depth= 7.0
$m8_bore  = 8.6    # M8-Durchgang

$plunge_y = 14.0   # Taststift-Position (vorne, +Y)
$plunge_d = 4.2    # Taststift-Ø (gleitet)
$spring_d = 8.0    # Feder-Senkung (von oben)
$spring_h = 14.0

# Mikroschalter D2F (20 x 6.4 x ~11), 2x M2.3, Lochabstand 9.5
$sw_x0=6.0; $sw_x1=20.0; $sw_y0=10.5; $sw_y1=17.5; $sw_depth=11.0
$sw_hole=2.3; $sw_h1x=8.0; $sw_h2x=17.5; $sw_hy=14.0

$f = 0.1
$outIpt = Join-Path $PSScriptRoot "Taster_Schlitten.ipt"
$outStl = Join-Path $PSScriptRoot "Taster_Schlitten.stl"
$kPart=12290; $kJoin=20485; $kCut=20482; $kPos=20993; $kNeg=20994; $mmU=11811
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

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

Write-Host "1) Body..."
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P (-$bx/2) (-$by/2)),(P ($bx/2) ($by/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $bz*$f, $kPos, $kJoin) | Out-Null

$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $bz*$f); $top.Visible=$false
function CutFromTop($sketchAction,$depth){
  $s=$cd.Sketches.Add($top); & $sketchAction $s
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $depth*$f, $kNeg, $kCut) | Out-Null
}
function CutFromBottom($sketchAction,$depth){
  $s=$cd.Sketches.Add($XY); & $sketchAction $s
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $depth*$f, $kPos, $kCut) | Out-Null
}

Write-Host "2) LM8UU-Bohrungen (2x, durch)..."
CutFromTop { param($s)
  $s.SketchCircles.AddByCenterRadius((P (-$rod_cc/2) 0), ($lm_d/2)*$f) | Out-Null
  $s.SketchCircles.AddByCenterRadius((P ( $rod_cc/2) 0), ($lm_d/2)*$f) | Out-Null
} ($bz+1)

Write-Host "3) M8-Durchgang + Mutter-Tasche (unten)..."
CutFromTop { param($s) $s.SketchCircles.AddByCenterRadius((P 0 0), ($m8_bore/2)*$f) | Out-Null } ($bz+1)
CutFromBottom { param($s)
  $s.SketchLines.AddAsTwoPointRectangle((P (-$nut_af/2) (-$nut_len/2)),(P ($nut_af/2) ($nut_len/2))) | Out-Null
} $nut_depth

Write-Host "4) Taststift-Bohrung + Feder-Senkung (vorne)..."
CutFromTop { param($s) $s.SketchCircles.AddByCenterRadius((P 0 $plunge_y), ($plunge_d/2)*$f) | Out-Null } ($bz+1)
CutFromTop { param($s) $s.SketchCircles.AddByCenterRadius((P 0 $plunge_y), ($spring_d/2)*$f) | Out-Null } $spring_h

Write-Host "5) Mikroschalter-Tasche + Schraubloecher..."
CutFromTop { param($s)
  $s.SketchLines.AddAsTwoPointRectangle((P $sw_x0 $sw_y0),(P $sw_x1 $sw_y1)) | Out-Null
} $sw_depth
CutFromTop { param($s)
  $s.SketchCircles.AddByCenterRadius((P $sw_h1x $sw_hy), ($sw_hole/2)*$f) | Out-Null
  $s.SketchCircles.AddByCenterRadius((P $sw_h2x $sw_hy), ($sw_hole/2)*$f) | Out-Null
} ($bz+1)

Write-Host "6) Speichern .ipt + .stl..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)
$stl=$inv.ApplicationAddIns.ItemById($STLID)
$ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
$opts=$inv.TransientObjects.CreateNameValueMap()
$data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
$stl.SaveCopyAs($doc,$ctx,$opts,$data)
$doc.Close($true)
foreach($file in @($outIpt,$outStl)){ if(Test-Path $file){Write-Host ("FERTIG: {0} ({1:N1} KB)" -f $file,((Get-Item $file).Length/1KB))} }
