$ErrorActionPreference = "Stop"
$file = "H:\ZwickRoell Projekt\Messstand_Komplett.iam"
try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$true
$doc=$inv.Documents.Open($file,$true)
function Save-View($cmd,$out){
  try { $inv.CommandManager.ControlDefinitions.Item($cmd).Execute() } catch {}
  Start-Sleep -Milliseconds 500
  $cam=$inv.ActiveView.Camera; $cam.Fit(); $cam.Apply()
  Start-Sleep -Milliseconds 500
  $inv.ActiveView.SaveAsBitmap($out,1600,1100)
}
Save-View "AppIsometricViewCmd" "H:\ZwickRoell Projekt\_asm_iso.png"
Save-View "AppFrontViewCmd"      "H:\ZwickRoell Projekt\_asm_front.png"
$doc.Close($true)
Write-Host "ok"
