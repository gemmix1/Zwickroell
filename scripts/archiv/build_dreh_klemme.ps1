# ============================================================
#  Dreh-Klemme (Servo-Seite) fuer das Kontakt-Mikrometer (v4).
#  Sitzt auf der SG90-Achse, dreht das Probenende um die Laengsachse.
#  - Zentrier-Tasche 20x6 (Grip-Ende) -> Querschnitt-Schwerpunkt auf der Drehachse
#    (Breite X wird zentriert; Dicke Y ist ohnehin 0/180-robust).
#  - SG90-Ritzelaufnahme (Ø4.8) + axiale M2-Schraube.
#  - Index-Flansch mit 4 Loechern (0/90/180/270) -> exakte 90-Grad-Rastung
#    (Index-Pin vom Rahmen definiert den Winkel, nicht der Servo -> Squareness).
#  Inventor-API in cm -> Faktor 0.1. Ausgabe via $PSScriptRoot.
# ============================================================
$ErrorActionPreference = "Stop"

# ---------- PARAMETER (mm) ----------
$bx=28.0; $by=16.0; $bz=34.0        # Klemmkoerper
$pkt_x=20.2; $pkt_y=6.2; $pkt_d=24.0 # Zentrier-Tasche (Grip 20x6 + Spiel)
$spline_d=4.8; $spline_h=10.0        # SG90-Ritzel (Ø4.8)
$axscrew_d=2.0                       # axiale M2-Hornschraube
$set_d=2.6                           # M3-Set-Screw (Retainer, Y-Richtung)
$fl_d=44.0; $fl_t=4.0                # Index-Flansch
$idx_d=3.0; $idx_r=16.0              # 4 Index-Loecher, Radius (ausserhalb Koerper-Footprint)

$f = 0.1
$outIpt = Join-Path $PSScriptRoot "Dreh_Klemme.ipt"
$outStl = Join-Path $PSScriptRoot "Dreh_Klemme.stl"
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
$cd=$doc.ComponentDefinition
$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3)   # normal Z
$XZ=$cd.WorkPlanes.Item(2)   # normal Y
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function Circle($sk,$cx,$cy,$dia){ $sk.SketchCircles.AddByCenterRadius((P $cx $cy), ($dia/2)*$f) | Out-Null }

Write-Host "1) Klemmkoerper..."
$s=$cd.Sketches.Add($XY)
$s.SketchLines.AddAsTwoPointRectangle((P (-$bx/2) (-$by/2)),(P ($bx/2) ($by/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $bz*$f, $kPos, $kJoin) | Out-Null

Write-Host "2) Index-Flansch (unten, Ø44 x 4) MIT 4 Index-Loechern in einem Zug..."
$s=$cd.Sketches.Add($XY)
Circle $s 0 0 $fl_d                                  # Aussenkontur
foreach ($ang in 0,90,180,270) {                    # 4 Index-Loecher als innere Konturen
  $rad=[math]::PI*$ang/180.0
  Circle $s ($idx_r*[math]::Cos($rad)) ($idx_r*[math]::Sin($rad)) $idx_d
}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $fl_t*$f, $kNeg, $kJoin) | Out-Null

$top=$cd.WorkPlanes.AddByPlaneAndOffset($XY, $bz*$f); $top.Visible=$false
# Ebene knapp ueber der Flansch-Oberseite: Solid direkt darunter -> AddForSolid greift
# auch fuer Kreise ausserhalb des Koerper-Footprints (Flansch reicht bis r22).
$pf=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 0.5*$f); $pf.Visible=$false
$thru = ($bz+$fl_t+1)   # Durchgang von oben durch alles
$flcut = ($fl_t+2)      # von $pf nach unten durch den Flansch

Write-Host "3) Zentrier-Tasche (oben, 20x6)..."
$s=$cd.Sketches.Add($top)
$s.SketchLines.AddAsTwoPointRectangle((P (-$pkt_x/2) (-$pkt_y/2)),(P ($pkt_x/2) ($pkt_y/2))) | Out-Null
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $pkt_d*$f, $kNeg, $kCut) | Out-Null

Write-Host "4) SG90-Ritzelaufnahme (Ø4.8, von unten durch Flansch)..."
$s=$cd.Sketches.Add($pf); Circle $s 0 0 $spline_d
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $flcut*$f, $kNeg, $kCut) | Out-Null

Write-Host "5) Axiale M2-Schraube (durch, von oben)..."
$s=$cd.Sketches.Add($top); Circle $s 0 0 $axscrew_d
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), $thru*$f, $kNeg, $kCut) | Out-Null

# (Index-Loecher sind bereits in Schritt 2 im Flansch. Grip haelt der Slip-Fit
#  der 20.2x6.2-Tasche; bei Bedarf spaeter eine Klemmschraube ergaenzen.)

Write-Host "8) Speichern .ipt + .stl..."
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
