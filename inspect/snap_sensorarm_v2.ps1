$ErrorActionPreference = "Stop"
$file = "H:\ZwickRoell Projekt\Sensorarm_v2.ipt"
if (-not (Test-Path $file)) { Write-Host "Erst build_sensorarm_v2.ps1 ausfuehren"; exit 1 }

try { $inv = [Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv = New-Object -ComObject Inventor.Application }
$inv.Visible = $true
$doc = $inv.Documents.Open($file, $true)
Start-Sleep -Milliseconds 800

function Save-View($cmdName, $outfile) {
    try { $inv.CommandManager.ControlDefinitions.Item($cmdName).Execute() } catch {}
    Start-Sleep -Milliseconds 400
    $cam = $inv.ActiveView.Camera; $cam.Fit(); $cam.Apply()
    Start-Sleep -Milliseconds 400
    $inv.ActiveView.SaveAsBitmap($outfile, 1500, 1000)
    if (Test-Path $outfile) { Write-Host "OK: $outfile" } else { Write-Host "FEHLT: $outfile" }
}

Save-View "AppIsometricViewCmd" "H:\ZwickRoell Projekt\inspect\_sensorarm_v2_iso.png"
Save-View "AppTopViewCmd"       "H:\ZwickRoell Projekt\inspect\_sensorarm_v2_top.png"
Save-View "AppFrontViewCmd"     "H:\ZwickRoell Projekt\inspect\_sensorarm_v2_front.png"
Save-View "AppRightViewCmd"     "H:\ZwickRoell Projekt\inspect\_sensorarm_v2_seite.png"

$doc.Close($true)
Write-Host "Snapshots fertig."
