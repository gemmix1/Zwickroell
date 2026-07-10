# ============================================================
#  Fuegt der Messstand_v4.iam echte Constraints hinzu â€” ueber FLAECHEN
#  (occ.SurfaceBodies liefert Proxies direkt; kein CreateGeometryProxy noetig).
#  Statik -> grounded. Beweglich (Freiheitsgrade erhalten):
#   - Taster_Schlitten: gleitet vertikal (Achsen-Mates auf Spindel + Welle)
#   - Taststift: gleitet vertikal im Schlitten (Federweg)
#   - Dreh_Klemme + Probe + Idler_Klemme: drehen gemeinsam um die Probenachse
#  Flaechen werden ueber Radius/Lage gefunden; jeder Constraint wird per
#  Drift-Check verifiziert (Mate/Flush und +/-Offset automatisch probiert).
# ============================================================
$ErrorActionPreference="Stop"
$dir=Join-Path $PSScriptRoot "..\cad"
$iam=Join-Path $dir "Messstand_v4.iam"
$kLine=115202   # kInferredLine (Achse aus Zylinderflaeche)

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$true; $inv.SilentOperation=$true
$doc=$inv.Documents.Open($iam,$true)
$def=$doc.ComponentDefinition
$cons=$def.Constraints

$occ=@{}
foreach($o in $def.Occurrences){ $occ[$o.Name]=$o }
function O($n){ return $occ[$n] }

# ---- Aufraeumen (alte Constraints + User-Arbeitsgeometrie) ----
Write-Host "Aufraeumen..."
$cDel=@(); foreach($c in $cons){ $cDel+=$c }
foreach($c in $cDel){ try{$c.Delete()}catch{} }
$axDel=@(); foreach($wa in $def.WorkAxes){ if($wa.Name -notmatch "Achse$|Axis$"){ $axDel+=$wa } }
foreach($wa in $axDel){ try{$wa.Delete()}catch{} }
$wpDel=@(); foreach($wp in $def.WorkPoints){ if($wp.Name -notmatch "Mittelpunkt|Center"){ $wpDel+=$wp } }
foreach($wp in $wpDel){ try{$wp.Delete()}catch{} }

# ---- Statik fixieren ----
$statics=@("Grundplatte_v4:1","Turm_Servo:1","Turm_Idler:1","Motorblock_N20:1",
  "Fuehrungswelle_8x150:1","Fuehrungswelle_8x150:2","Fuehrungswelle_8x150:3",
  "Servo_SG90:1","Rast_Halter:1","Index_Pin:1","Kupplung_ph:1","Motor_N20_ph:1",
  "Taststift_Kappe:1")
foreach($n in $statics){ (O $n).Grounded=$true }
Write-Host ("{0} Teile fixiert." -f $statics.Count)

# ---- Flaechensuche (Koordinaten in cm, Baugruppen-Kontext) ----
function FindCyl($o,$r,$box){   # box=@(xmin,xmax,ymin,ymax,zmin,zmax) oder $null
  foreach($b in $o.SurfaceBodies){ foreach($fc in $b.Faces){
    $rad=$null; try{ $rad=$fc.Geometry.Radius }catch{}
    if($null -eq $rad){ continue }
    $isCone=$false; try{ $null=$fc.Geometry.HalfAngle; $isCone=$true }catch{}
    if($isCone){ continue }
    if([math]::Abs($rad-$r) -ge 0.02){ continue }
    if($box){
      $p=$fc.PointOnFace
      if($p.X -lt $box[0] -or $p.X -gt $box[1] -or $p.Y -lt $box[2] -or $p.Y -gt $box[3] -or $p.Z -lt $box[4] -or $p.Z -gt $box[5]){ continue }
    }
    return $fc
  }}
  return $null
}
function FindPlane($o,$axis,$coordMin,$coordMax){   # axis="X"/"Y"/"Z": Normal ~ Achse, Lage im Fenster
  foreach($b in $o.SurfaceBodies){ foreach($fc in $b.Faces){
    $n=$null; try{ $n=$fc.Geometry.Normal }catch{}
    if($null -eq $n){ continue }
    $comp=switch($axis){ "X"{[math]::Abs($n.X)} "Y"{[math]::Abs($n.Y)} "Z"{[math]::Abs($n.Z)} }
    if($comp -lt 0.999){ continue }
    $p=$fc.PointOnFace
    $c=switch($axis){ "X"{$p.X} "Y"{$p.Y} "Z"{$p.Z} }
    if($c -ge $coordMin -and $c -le $coordMax){ return $fc }
  }}
  return $null
}

# ---- Drift-Check-Rahmen ----
function Snap($o){ $m=$o.Transformation; $a=@(); for($r=1;$r -le 3;$r++){ for($c=1;$c -le 4;$c++){ $a+=$m.Cell($r,$c) } }; return $a }
function Drift($s1,$s2){ $d=0.0; for($i=0;$i -lt $s1.Count;$i++){ $d+=[math]::Abs($s1[$i]-$s2[$i]) }; return $d }

function TryAxisMate($nm,$f1,$f2,$watch){
  if($null -eq $f1 -or $null -eq $f2){ Write-Host ("  !!  {0}: Flaeche nicht gefunden" -f $nm); return }
  $before=Snap $watch; $c=$null
  try{
    $c=$cons.AddMateConstraint($f1,$f2,0.0,$kLine,$kLine)
    $doc.Update()
    if((Drift $before (Snap $watch)) -lt 0.05){ Write-Host ("  OK  {0}" -f $nm); return }
    $c.Delete(); $doc.Update(); Write-Host ("  !!  {0}: Drift" -f $nm)
  } catch { if($c){try{$c.Delete()}catch{}}; Write-Host ("  !!  {0}: {1}" -f $nm,$_.Exception.Message.Split("`n")[0]) }
}
function TryPlaneMate($nm,$f1,$f2,$offCm,$watch){
  if($null -eq $f1 -or $null -eq $f2){ Write-Host ("  !!  {0}: Flaeche nicht gefunden" -f $nm); return }
  $before=Snap $watch
  foreach($type in "mate","flush"){ foreach($sgn in 1,-1){
    $c=$null
    try{
      if($type -eq "mate"){ $c=$cons.AddMateConstraint($f1,$f2,($offCm*$sgn)) }
      else                { $c=$cons.AddFlushConstraint($f1,$f2,($offCm*$sgn)) }
      $doc.Update()
      if((Drift $before (Snap $watch)) -lt 0.05){ Write-Host ("  OK  {0} ({1}, off={2})" -f $nm,$type,($offCm*$sgn)); return }
      $c.Delete(); $doc.Update()
    } catch { if($c){try{$c.Delete()}catch{}} }
  }}
  Write-Host ("  !!  {0}: keine Variante driftfrei" -f $nm)
}

# ---- Teile ----
$sch=O "Taster_Schlitten:1"; $stift=O "Taststift:1"
$rod1=O "Fuehrungswelle_8x150:1"; $spindel=O "Fuehrungswelle_8x150:3"
$dreh=O "Dreh_Klemme:1"; $idl=O "Idler_Klemme:1"; $probe=O "Probe_Platzhalter:1"
$tSrv=O "Turm_Servo:1"; $tIdl=O "Turm_Idler:1"

Write-Host "Constraints..."
# 1) Schlitten: M8-Bohrung auf Spindel + LM8UU auf Welle1 -> nur Z-Gleiten frei
TryAxisMate "Schlitten<->Spindel" (FindCyl $sch 0.43 $null) (FindCyl $spindel 0.40 $null) $sch
TryAxisMate "Schlitten<->Welle1"  (FindCyl $sch 0.75 @(-99,99,-99,0,-99,99)) (FindCyl $rod1 0.40 $null) $sch

# 2) Rotationsachse: Klemmen an das Idler-Journal (im gegruendeten Turm)
TryAxisMate "DrehKlemme<->Achse"  (FindCyl $dreh 2.2 $null) (FindCyl $tIdl 0.42 $null) $dreh
TryAxisMate "IdlerKlemme<->Achse" (FindCyl $idl 0.40 $null) (FindCyl $tIdl 0.42 $null) $idl

# 3) Axiale Lage der Dreh-Klemme (Flanschflaeche vs. Turm-Innenwand, 4.5mm Spalt)
TryPlaneMate "DrehKlemme axial" (FindPlane $dreh "Y" -9.15 -9.05) (FindPlane $tSrv "Y" -9.60 -9.50) 0.45 $dreh

# 4) Probe fest in die Dreh-Klemmen-Tasche (rotiert mit)
TryPlaneMate "Probe laengs"   (FindPlane $probe "Y" -8.35 -8.25) (FindPlane $dreh "Y" -8.35 -8.25) 0.0  $probe
TryPlaneMate "Probe seitlich" (FindPlane $probe "X" 0.95 1.05)   (FindPlane $dreh "X" 0.95 1.06)   0.01 $probe
TryPlaneMate "Probe hoehe"    (FindPlane $probe "Z" 6.25 6.35)   (FindPlane $dreh "Z" 6.25 6.36)   0.01 $probe

# 5) Idler-Klemme axial + Rotation an Probe gekoppelt
TryPlaneMate "Idler axial"    (FindPlane $idl "Y" 8.25 8.35)   (FindPlane $probe "Y" 8.25 8.35) 0.0  $idl
TryPlaneMate "Idler Kopplung" (FindPlane $idl "X" 0.95 1.06)   (FindPlane $probe "X" 0.95 1.05) 0.01 $idl

# 6) Taststift gleitet in der Schlitten-Bohrung
TryAxisMate "Taststift<->Schlitten" (FindCyl $stift 0.30 $null) (FindCyl $sch 0.32 $null) $stift

Write-Host "Speichern..."
$doc.Save()
$inv.SilentOperation=$false
Write-Host "FERTIG - Inventor bleibt offen. Schlitten/Probe sind jetzt ziehbar."



