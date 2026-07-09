$ErrorActionPreference = "Stop"
$found = Get-ChildItem "H:\ZwickRoell Projekt" -Filter "12x6_Probe*.ipt" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $found) { Write-Host "DATEI NICHT GEFUNDEN (Muster 12x6_Probe*.ipt)"; exit 1 }
$file = $found.FullName
Write-Host "DATEI: $file"

try { $inv = [Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv = New-Object -ComObject Inventor.Application }
$inv.Visible = $true

$doc = $inv.Documents.Open($file, $true)
$cd  = $doc.ComponentDefinition

$rb = $cd.RangeBox
$dx = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$dy = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
$dz = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
Write-Host ("ABMESSUNGEN (mm): {0:N2} x {1:N2} x {2:N2}" -f $dx,$dy,$dz)

try {
  $mp = $cd.MassProperties
  Write-Host ("VOLUMEN (cm^3): {0:N3}" -f $mp.Volume)
  Write-Host ("OBERFLAECHE (cm^2): {0:N3}" -f $mp.Area)
} catch {}
try { Write-Host ("MATERIAL: {0}" -f $cd.Material.Name) } catch {}
Write-Host ("SOLID BODIES: {0}" -f $cd.SurfaceBodies.Count)

Write-Host "--- PARAMETER ---"
foreach ($p in $cd.Parameters.ModelParameters) {
  try { Write-Host ("  {0} = {1:N3} [{2}]" -f $p.Name, ($p.Value*10), $p.Units) } catch {}
}
Write-Host "--- FEATURES ---"
foreach ($ft in $cd.Features) { try { Write-Host ("  {0}" -f $ft.Name) } catch {} }

function Save-View($cmdName, $outfile) {
  try { $inv.CommandManager.ControlDefinitions.Item($cmdName).Execute() } catch {}
  Start-Sleep -Milliseconds 400
  $cam = $inv.ActiveView.Camera; $cam.Fit(); $cam.Apply()
  Start-Sleep -Milliseconds 400
  $inv.ActiveView.SaveAsBitmap($outfile, 1400, 1000)
}
Save-View "AppIsometricViewCmd" "H:\ZwickRoell Projekt\_probe_iso.png"
Save-View "AppTopViewCmd"        "H:\ZwickRoell Projekt\_probe_top.png"
Save-View "AppFrontViewCmd"      "H:\ZwickRoell Projekt\_probe_front.png"

$doc.Close($true)
Write-Host "Fertig."
