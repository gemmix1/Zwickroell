# Setzt alle Teile zu einer Baugruppe zusammen (Messstand).
$ErrorActionPreference = "Stop"
$f=0.1; $deg=[math]::PI/180
$kAsm=12291
$dir="H:\ZwickRoell Projekt"
$out="$dir\Messstand_Komplett.iam"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

$asm=$inv.Documents.Add($kAsm, $inv.FileManager.GetTemplateFile($kAsm))
$ad=$asm.ComponentDefinition
$orig=$tg.CreatePoint(0,0,0)

function AxisVec($a){ switch($a){ "X"{return $tg.CreateVector(1,0,0)} "Y"{return $tg.CreateVector(0,1,0)} "Z"{return $tg.CreateVector(0,0,1)} default{return $tg.CreateVector(0,0,1)} } }

$probe = (Get-ChildItem "$dir" -Filter "12x6_Probe*.ipt" | Select-Object -First 1).FullName

function Place($file,$x,$y,$z,$axis,$angle){
  $path = if ([System.IO.Path]::IsPathRooted($file)) { $file } else { "$dir\$file" }
  $m=$tg.CreateMatrix()
  if ($axis -ne "none") { $m.SetToRotation($angle*$deg, (AxisVec $axis), $orig) }
  $m.SetTranslation($tg.CreateVector($x*$f,$y*$f,$z*$f))
  try { $occ=$ad.Occurrences.Add($path,$m); Write-Host "platziert: $(Split-Path $path -Leaf)"; return $occ }
  catch { Write-Host "FEHLER bei $(Split-Path $path -Leaf) : $($_.Exception.Message)"; return $null }
}

# --- top der Platte bei Z=0; Platte wird verankert ---
$platte = Place "Grundplatte_v2.ipt"   0    0   -15  "none" 0
try { $platte.Grounded = $true } catch {}
$null = Place $probe                   0    0    -2  "Z"   90    # Probe in Mulde, Laenge auf X

# --- Quer-Achse (Breite) auf 2 Stuetzen, Stange entlang Y ---
$null = Place "Stuetze.ipt"         -115  -70    0  "none" 0
$null = Place "Stuetze.ipt"         -115   70    0  "none" 0
$null = Place "Gewindestange_M8.ipt" -115   90   70  "X"   90   # Stange entlang Y (Y -90..90)
$null = Place "Motor_N20.ipt"       -115  120   70  "X"   90    # Breiten-Motor am Stangenende

# --- Vertikale Dicken-Achse: Stange rauf, Arm ueber die Probe ---
$null = Place "Gewindestange_M8.ipt" -115    0   70  "none" 0   # vertikal Z70..250
$null = Place "Sensorarm.ipt"       -115    0  110  "none" 0    # Pad bei X=0 ueber Probe
$null = Place "Sensor_VL53L1X.ipt"     0    0  107  "X"  180    # Sensor schaut nach unten
$null = Place "wellenkupplung_3mm_8mm.ipt" -115  0  250 "none" 0
$null = Place "Motor_N20.ipt"       -115    0  276  "X"  180    # Dicken-Motor, Welle nach unten

if (Test-Path $out) { Remove-Item $out -Force }
$asm.SaveAs($out,$false)
$asm.Close($true)
Write-Host "FERTIG: $out"
