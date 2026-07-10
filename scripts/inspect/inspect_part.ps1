$ErrorActionPreference = "Stop"
$found = Get-ChildItem "H:\" -Filter "Grund*Neu.ipt" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $found) { Write-Host "DATEI NICHT GEFUNDEN unter H:\ (Muster Grund*Neu.ipt)"; exit 1 }
$file = $found.FullName
Write-Host "DATEI: $file"

try { $inv = [Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv = New-Object -ComObject Inventor.Application }
$inv.Visible = $false; $inv.SilentOperation = $true

$doc = $inv.Documents.Open($file, $false)
$cd  = $doc.ComponentDefinition

# --- Abmessungen (RangeBox, cm -> mm) ---
$rb = $cd.RangeBox
$dx = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$dy = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
$dz = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
Write-Host ("ABMESSUNGEN (mm): {0:N2} x {1:N2} x {2:N2}" -f $dx,$dy,$dz)

# --- Masse / Volumen ---
try {
  $mp = $cd.MassProperties
  Write-Host ("VOLUMEN (cm^3): {0:N2}" -f $mp.Volume)
  Write-Host ("MASSE (kg):     {0:N4}" -f $mp.Mass)
  Write-Host ("OBERFLAECHE (cm^2): {0:N2}" -f $mp.Area)
} catch { Write-Host "MassProperties n/v: $($_.Exception.Message)" }

# --- Material ---
try { Write-Host ("MATERIAL: {0}" -f $cd.Material.Name) } catch { Write-Host "Material n/v" }

# --- Koerper ---
Write-Host ("SOLID BODIES: {0}" -f $cd.SurfaceBodies.Count)

# --- Parameter (Modellmasse) ---
Write-Host "--- MODELL-PARAMETER ---"
foreach ($p in $cd.Parameters.ModelParameters) {
  try {
    $val = $p.Value * 10   # cm -> mm fuer Laengen
    Write-Host ("  {0} = {1:N3} (mm, falls Laenge)  [{2}]" -f $p.Name, $val, $p.Units)
  } catch {}
}

# --- Features (Baum) ---
Write-Host "--- FEATURES ---"
foreach ($ft in $cd.Features) {
  try { Write-Host ("  {0}   [{1}]" -f $ft.Name, $ft.Type) } catch { Write-Host ("  {0}" -f $ft.Name) }
}

# --- Bohrungen / Loecher Details ---
Write-Host "--- HOLE-FEATURES ---"
try {
  foreach ($h in $cd.Features.HoleFeatures) {
    Write-Host ("  {0}" -f $h.Name)
  }
} catch {}

$doc.Close($true)
Write-Host "Inspektion fertig."
