# ============================================================
#  Messstand_v4.iam â€” Baugruppe v4b (korrigiert).
#  Welt: Platte z0..8, Probenachse z=60 laengs Y, Probe +-83.
#  Layout-Platzierung (Matrix), keine Constraints.
# ============================================================
$ErrorActionPreference = "Stop"
$f=0.1
$kAsm=12291; $mmU=11811
$dir=Join-Path $PSScriptRoot "..\cad"
$PI=[math]::PI

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }
$tg=$inv.TransientGeometry

Write-Host "Baugruppe anlegen..."
$asm=$inv.Documents.Add($kAsm,$inv.FileManager.GetTemplateFile($kAsm))
$occ=$asm.ComponentDefinition.Occurrences

function Mtrans($x,$y,$z){ $m=$tg.CreateMatrix(); $m.SetTranslation($tg.CreateVector($x*$f,$y*$f,$z*$f)); return $m }
function Mrot($deg,$ax,$x,$y,$z){
  $m=$tg.CreateMatrix()
  $v=switch($ax){ "X"{$tg.CreateVector(1,0,0)} "Y"{$tg.CreateVector(0,1,0)} "Z"{$tg.CreateVector(0,0,1)} }
  $m.SetToRotation(($deg*$PI/180.0), $v, $tg.CreatePoint(0,0,0))
  $m.SetTranslation($tg.CreateVector($x*$f,$y*$f,$z*$f))
  return $m
}
function Add($name,$m){ $occ.Add((Join-Path $dir ($name+".ipt")), $m) | Out-Null; Write-Host ("  + {0}" -f $name) }

# Struktur
Add "Grundplatte_v4" (Mtrans 0 0 0)
Add "Turm_Servo" (Mrot 180 "Z" 0 (-95.5) 8)     # Wand innen -95.5, Laschen nach innen
Add "Turm_Idler" (Mtrans 0 91.5 8)              # Wand 91.5..99.5
Add "Motorblock_N20" (Mtrans (-14) 0 (-32))
# Achse
Add "Fuehrungswelle_8x150" (Mtrans (-14) (-22) 4)
Add "Fuehrungswelle_8x150" (Mtrans (-14) 22 4)
Add "Fuehrungswelle_8x150" (Mtrans (-14) 0 (-20))   # Spindel-Visual (real M8, ~130mm)
Add "Taster_Schlitten" (Mrot (-90) "Z" (-14) 0 82)  # Stift-Bohrung -> (0,0)
Add "Taststift" (Mtrans 0 0 82)
Add "Taststift_Kappe" (Mtrans 0 0 79)
# Probe + Klemmen
Add "Dreh_Klemme" (Mrot (-90) "X" 0 (-91) 60)   # Pocketboden -83, Flansch -95..-91
Add "Idler_Klemme" (Mrot 90 "X" 0 91 60)        # Pocketboden +83, Zapfen 91..103
Add "Probe_Platzhalter" (Mtrans 0 0 57)
# Servo + Rast + Motor + Kaufteile (Repraesentation)
Add "Servo_SG90" (Mrot (-90) "X" 0 (-129) 60)
Add "Rast_Halter" (Mrot (-90) "X" (-16) (-115.5) 60)
Add "Index_Pin" (Mrot (-90) "X" (-16) (-114) 60)
Add "Kupplung_ph" (Mtrans (-14) 0 (-26))
Add "Motor_N20_ph" (Mtrans (-14) 0 (-60))
Add "Lager_608ZZ" (Mrot (-90) "X" 0 91.5 60)      # im Idler-Turm-Sitz
Add "T8_Mutter" (Mtrans (-14) 0 78.5)             # Flansch unter dem Schlitten
Add "Mikroschalter_ph" (Mrot 90 "Z" (-4) (-3) 108) # am Boss, Hebel ueber Stift
Add "Index_Pin" (Mtrans 0 0 66)                    # Stahl-TASTSPITZE (2. Ã˜4-Stift)
Add "Arduino_Shield_ph" (Mtrans 20 (-58) 8)        # Uno+Shield auf der Platte

Write-Host "Speichern..."
$iam=Join-Path $dir "Messstand_v4.iam"; if(Test-Path $iam){Remove-Item $iam -Force}
$asm.SaveAs($iam,$false)
$asm.Close($true)
Write-Host "FERTIG: Messstand_v4.iam"



