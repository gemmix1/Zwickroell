# Baut die optimierte Grundplatte (Dogbone-Mulde + ToF-Mess-Fenster + Klemmloecher)
# und exportiert .ipt + .stl. Inventor-API rechnet in cm -> Faktor 0.1
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$plate_L = 220.0    # Plattenlaenge (X)
$plate_W = 80.0     # Plattenbreite (Y)
$plate_T = 15.0     # Plattendicke (Z)

$cl      = 0.25     # Spiel der Mulde pro Seite

# Dogbone (aus Probe: 166 lang, Enden 20 breit, Mitte 12 breit)
$grip_L  = 30.0     # Laenge je Einspannende
$grip_W  = 20.0     # Breite Einspannende
$gauge_L = 106.0    # Laenge Messbereich
$gauge_W = 12.0     # Breite Messbereich
$pocket_d = 2.0     # Muldentiefe: 2mm -> Probe ragt 4mm raus ("schwebt") fuer Seiten-Scan

# Mess-Fenster (offen nach unten, breiter als Probe -> scharfe Kante)
# Breiter und laenger fuer besseren Seiten-Arm-Zugang
$win_L = 60.0       # X-Laenge (war 40, jetzt 60 -> Arm sieht mehr Probenunterseite)
$win_W = 50.0       # Y-Breite

# Klemmloecher
$hole_d = 3.2

$f = 0.1
$outIpt = "H:\ZwickRoell Projekt\Grundplatte_v2.ipt"
$outStl = "H:\ZwickRoell Projekt\Grundplatte_v2.stl"

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

Write-Host "1) Grundblock..."
$sk=$cd.Sketches.Add($XY)
$sk.SketchLines.AddAsTwoPointRectangle((P (-$plate_L/2) (-$plate_W/2)),(P ($plate_L/2) ($plate_W/2))) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $plate_T*$f, $kPos, $kJoin) | Out-Null

$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $plate_T*$f); $top.Visible=$false
function CutRect($x1,$y1,$x2,$y2,$depth){
  $s=$cd.Sketches.Add($top)
  $s.SketchLines.AddAsTwoPointRectangle((P $x1 $y1),(P $x2 $y2)) | Out-Null
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $depth*$f, $kNeg, $kCut) | Out-Null
}

Write-Host "2) Dogbone-Mulde..."
$gx = $gauge_L/2                      # 53
$ex = $gx + $grip_L                   # 83
CutRect (-$ex-$cl) (-$grip_W/2-$cl) (-$gx+$cl) ($grip_W/2+$cl) $pocket_d   # Ende A
CutRect ($gx-$cl) (-$grip_W/2-$cl) ($ex+$cl) ($grip_W/2+$cl) $pocket_d     # Ende B
CutRect (-$gx-$cl) (-$gauge_W/2-$cl) ($gx+$cl) ($gauge_W/2+$cl) $pocket_d   # Mitte

Write-Host "3) Mess-Fenster (durch)..."
CutRect (-$win_L/2) (-$win_W/2) ($win_L/2) ($win_W/2) ($plate_T+1)

Write-Host "4) Klemmloecher..."
$s=$cd.Sketches.Add($top)
$hx = $gx + $grip_L/2     # 68
$hy = $grip_W/2 + 5       # 15
foreach ($sx in -1,1) { foreach ($sy in -1,1) {
  $s.SketchCircles.AddByCenterRadius((P ($sx*$hx) ($sy*$hy)), ($hole_d/2)*$f) | Out-Null
}}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), ($plate_T+1)*$f, $kNeg, $kCut) | Out-Null

Write-Host "5) Speichern .ipt + .stl..."
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
