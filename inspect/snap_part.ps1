$ErrorActionPreference = "Stop"
$found = Get-ChildItem "H:\" -Filter "Grund*Neu.ipt" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $found) { Write-Host "DATEI NICHT GEFUNDEN"; exit 1 }
$file = $found.FullName

try { $inv = [Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv = New-Object -ComObject Inventor.Application }
$inv.Visible = $true

$doc = $inv.Documents.Open($file, $true)
Start-Sleep -Milliseconds 800

function Save-View($cmdName, $outfile) {
  try { $inv.CommandManager.ControlDefinitions.Item($cmdName).Execute() } catch {}
  Start-Sleep -Milliseconds 400
  $cam = $inv.ActiveView.Camera
  $cam.Fit()
  $cam.Apply()
  Start-Sleep -Milliseconds 400
  $inv.ActiveView.SaveAsBitmap($outfile, 1500, 1000)
  if (Test-Path $outfile) { Write-Host "OK: $outfile" } else { Write-Host "FEHLT: $outfile" }
}

Save-View "AppIsometricViewCmd" "H:\ZwickRoell Projekt\_plate_iso.png"
Save-View "AppTopViewCmd"        "H:\ZwickRoell Projekt\_plate_top.png"
Save-View "AppFrontViewCmd"      "H:\ZwickRoell Projekt\_plate_front.png"

$doc.Close($true)
Write-Host "Snapshots fertig."
