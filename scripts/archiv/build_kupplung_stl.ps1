# Steuert Autodesk Inventor per COM: baut die Wellenkupplung und exportiert STL.
$ErrorActionPreference = "Stop"

# ---- Parameter (mm) ----
$d_aussen  = 18.0
$laenge    = 24.0
$d_motor   = 3.2
$t_motor   = 10.0
$d_spindel = 8.3
$t_spindel = 12.0
$d_made    = 3.0
$f = 0.1   # mm -> cm (Inventor-API rechnet in cm)

$outStl = "H:\ZwickRoell Projekt\wellenkupplung_3mm_8mm.stl"
$outIpt = "H:\ZwickRoell Projekt\wellenkupplung_3mm_8mm.ipt"

# ---- Inventor-Enums (numerisch) ----
$kPartDocumentObject       = 12290
$kJoinOperation            = 20485
$kCutOperation             = 20482
$kPositiveExtentDirection  = 20993
$kNegativeExtentDirection  = 20994
$kSymmetricExtentDirection = 20995
$kMillimeterLengthUnits    = 11811
$kFileBrowseIOMechanism    = 13059
$STL_CLIENTID = "{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

Write-Host "Verbinde mit Inventor..."
try { $inv = [Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv = New-Object -ComObject Inventor.Application }
$inv.Visible = $false
$inv.SilentOperation = $true

# Evtl. offene (Hintergrund-)Dokumente aus vorherigen Laeufen schliessen
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }

$tg = $inv.TransientGeometry
$tpl = $inv.FileManager.GetTemplateFile($kPartDocumentObject)
$doc = $inv.Documents.Add($kPartDocumentObject, $tpl)
try { $doc.UnitsOfMeasure.LengthUnits = $kMillimeterLengthUnits } catch {}
$cd  = $doc.ComponentDefinition
$ef  = $cd.Features.ExtrudeFeatures

$XY = $cd.WorkPlanes.Item(3)
$XZ = $cd.WorkPlanes.Item(2)

function New-Sketch($plane) { return $cd.Sketches.Add($plane) }

Write-Host "1) Hauptkoerper..."
$sk = New-Sketch $XY
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), $d_aussen/2*$f) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $laenge*$f, $kPositiveExtentDirection, $kJoinOperation) | Out-Null

Write-Host "2) Bohrung Motorseite..."
$sk = New-Sketch $XY
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), $d_motor/2*$f) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $t_motor*$f, $kPositiveExtentDirection, $kCutOperation) | Out-Null

Write-Host "3) Bohrung Spindelseite..."
$wpTop = $cd.WorkPlanes.AddByPlaneAndOffset($XY, $laenge*$f)
$wpTop.Visible = $false
$sk = New-Sketch $wpTop
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), $d_spindel/2*$f) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $t_spindel*$f, $kNegativeExtentDirection, $kCutOperation) | Out-Null

Write-Host "4) Madenschrauben-Loecher..."
$sk = New-Sketch $XZ
$rm = ($d_made / 2.0) * $f
$z1 = ($t_motor * 0.33) * $f
$z2 = ($t_motor * 0.66) * $f
$z3 = ($t_motor + 2.0 + $t_spindel * 0.33) * $f
$z4 = ($t_motor + 2.0 + $t_spindel * 0.66) * $f
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, $z1), $rm) | Out-Null
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, $z2), $rm) | Out-Null
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, $z3), $rm) | Out-Null
$sk.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, $z4), $rm) | Out-Null
$ef.AddByDistanceExtent($sk.Profiles.AddForSolid(), $d_aussen * $f, $kSymmetricExtentDirection, $kCutOperation) | Out-Null

Write-Host "5) Inventor-Teil (.ipt) speichern..."
if (Test-Path $outIpt) { Remove-Item $outIpt -Force }
$doc.SaveAs($outIpt, $false)   # editierbare native Inventor-Datei

Write-Host "6) STL exportieren..."
$stl = $inv.ApplicationAddIns.ItemById($STL_CLIENTID)
$ctx = $inv.TransientObjects.CreateTranslationContext()
$ctx.Type = $kFileBrowseIOMechanism
$opts = $inv.TransientObjects.CreateNameValueMap()
$data = $inv.TransientObjects.CreateDataMedium()
$data.FileName = $outStl
if ($stl.HasSaveCopyAsOptions($doc, $ctx, $opts)) {
    try { $opts.Value("Resolution") = 1 } catch {}
    try { $opts.Value("ExportUnits") = "millimeter" } catch {}
}
$stl.SaveCopyAs($doc, $ctx, $opts, $data)

$doc.Close($true)
foreach ($file in @($outIpt, $outStl)) {
    if (Test-Path $file) {
        $kb = [math]::Round((Get-Item $file).Length/1KB,1)
        Write-Host "FERTIG: $file ($kb KB)"
    } else {
        Write-Host "FEHLER: $file wurde nicht erzeugt."
    }
}
