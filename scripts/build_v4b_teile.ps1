# ============================================================
#  v4b â€” korrigierter Teilesatz fuer das Kontakt-Mikrometer (autonom).
#  Behebt: schwebende Waende, Probenspannweite, Servo-Montage,
#  Motorhalter, Taststift-Federmechanik, Rastbolzen-Detent.
#  Regeln: Loecher IMMER als Einzelschnitte (Rect+Innenkreise unzuverlaessig),
#  Rechtecke koordinaten-normalisiert, Volumen-Check je Teil.
# ============================================================
$ErrorActionPreference="Stop"; $f=0.1
$kPart=12290;$kJoin=20485;$kCut=20482;$kPos=20993;$kNeg=20994;$kSym=20995;$mmU=11811
$kBrowse=13059;$STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

try{$inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application")}
catch{$inv=New-Object -ComObject Inventor.Application}
$inv.Visible=$false;$inv.SilentOperation=$true
while($inv.Documents.Count -gt 0){$inv.Documents.Item(1).Close($true)}
$tg=$inv.TransientGeometry
function P($x,$y){ return $tg.CreatePoint2d($x*$f,$y*$f) }
function NewPart(){ $d=$inv.Documents.Add($kPart,$inv.FileManager.GetTemplateFile($kPart)); try{$d.UnitsOfMeasure.LengthUnits=$mmU}catch{}; return $d }
function SaveDoc($doc,$name){
  $vol=$doc.ComponentDefinition.MassProperties.Volume
  $ipt=Join-Path $PSScriptRoot ("..\cad\"+$name+".ipt"); $stlP=Join-Path $PSScriptRoot ("..\stl\"+$name+".stl")
  if(Test-Path $ipt){Remove-Item $ipt -Force}
  $doc.SaveAs($ipt,$false)
  $stl=$inv.ApplicationAddIns.ItemById($STLID)
  $ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
  $opts=$inv.TransientObjects.CreateNameValueMap()
  $data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$stlP
  if($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)){try{$opts.Value("Resolution")=1}catch{}}
  $stl.SaveCopyAs($doc,$ctx,$opts,$data)
  $doc.Close($true)
  Write-Host ("FERTIG {0,-22} Vol={1,8:N2} cm3" -f $name,$vol)
}
function Circ($sk,$cx,$cy,$dia){ $sk.SketchCircles.AddByCenterRadius((P $cx $cy),($dia/2)*$f)|Out-Null }
function Rect($sk,$x1,$y1,$x2,$y2){
  $xa=[math]::Min($x1,$x2); $xb=[math]::Max($x1,$x2)
  $ya=[math]::Min($y1,$y2); $yb=[math]::Max($y1,$y2)
  $sk.SketchLines.AddAsTwoPointRectangle((P $xa $ya),(P $xb $yb))|Out-Null
}

# ================= 1) GRUNDPLATTE 140 x 210 x 8 =================
Write-Host "1) Grundplatte_v4..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -70 -105 70 105
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kJoin)|Out-Null
$topP=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 8*$f); $topP.Visible=$false
$holes=@(
  @(-14,0,9.0), @(-28.5,0,3.2), @(0.5,0,3.2),
  @(-29,-89.5,2.8), @(29,-89.5,2.8), @(-29,85.5,2.8), @(29,85.5,2.8)
)
foreach($h in $holes){
  $s=$cd.Sketches.Add($topP); Circ $s $h[0] $h[1] $h[2]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kNeg, $kCut)|Out-Null
}
foreach($sy in -1,1){                                  # Wellen-Bosse
  $s=$cd.Sketches.Add($XY); Circ $s -14 ($sy*22) 16.0
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 20*$f, $kPos, $kJoin)|Out-Null
}
$topB=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 20*$f); $topB.Visible=$false
foreach($sy in -1,1){                                  # glatte Ã˜8-Wellen: Presssitz (+Kleber)
  $s=$cd.Sketches.Add($topB); Circ $s -14 ($sy*22) 7.8
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 16*$f, $kNeg, $kCut)|Out-Null
}
SaveDoc $doc "Grundplatte_v4"

# ================= 2) TUERME (Servo + Idler) =================
function BuildTurm($mitServo){
  $doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures
  $XY=$cd.WorkPlanes.Item(3); $XZ=$cd.WorkPlanes.Item(2)
  $s=$cd.Sketches.Add($XY); Rect $s -35 0 35 8
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 84*$f, $kPos, $kJoin)|Out-Null
  foreach($sx in -1,1){                                 # Fusslaschen innen
    $s=$cd.Sketches.Add($XY); Rect $s ($sx*24) -12 ($sx*35) 0
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 6*$f, $kPos, $kJoin)|Out-Null
  }
  foreach($sx in -1,1){                                 # Fuss-Schraubloecher
    $s=$cd.Sketches.Add($XY); Circ $s ($sx*29) -6 3.4
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 6.2*$f, $kPos, $kCut)|Out-Null
  }
  if($mitServo){
    $s=$cd.Sketches.Add($XZ); Rect $s -17.75 45.5 6.25 58.5   # SG90-Durchsteck
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kPos, $kCut)|Out-Null
    foreach($hx in -19.75,8.25){                              # Flansch-Schrauben
      $s=$cd.Sketches.Add($XZ); Circ $s $hx 52 2.5
      $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kPos, $kCut)|Out-Null
    }
    $s=$cd.Sketches.Add($XZ); Circ $s 16 52 4.3               # Rastbolzen-Durchgang
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kPos, $kCut)|Out-Null
    foreach($hz in 46,58){                                    # Rast_Halter-Pilotloecher
      $s=$cd.Sketches.Add($XZ); Circ $s 16 $hz 1.9
      $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kPos, $kCut)|Out-Null
    }
    $pRec=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, 5*$f); $pRec.Visible=$false
    $s=$cd.Sketches.Add($pRec); Rect $s -22.75 44.5 11.25 59.5  # Flansch-Vertiefung aussen
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3.2*$f, $kPos, $kCut)|Out-Null
  } else {
    # v5: 608ZZ-Kugellager (8x22x7) von innen einpressen, 1mm-Lippe aussen haelt
    $s=$cd.Sketches.Add($XZ); Circ $s 0 52 22.3               # Lagersitz 7.2 tief
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 7.2*$f, $kPos, $kCut)|Out-Null
    $s=$cd.Sketches.Add($XZ); Circ $s 0 52 18.0               # Durchgang hinter Lippe
    $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.2*$f, $kPos, $kCut)|Out-Null
  }
  return $doc
}
Write-Host "2) Tuerme..."
SaveDoc (BuildTurm $true)  "Turm_Servo"
SaveDoc (BuildTurm $false) "Turm_Idler"

# ================= 3) MOTORBLOCK N20 =================
Write-Host "3) Motorblock..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3);$XZ=$cd.WorkPlanes.Item(2)
$s=$cd.Sketches.Add($XY); Rect $s -18 -13 18 13
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 32*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 5.0              # Motorwellen-Durchgang
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4.2*$f, $kPos, $kCut)|Out-Null
# N20-Flanschschrauben: 4 RADIALE LANGLOECHER (deckt Lochabstand 7..11 ab,
# N20-Bohrbilder variieren zwischen 8 und 9.5 mm)
$mslots=@( @(3.3,-1,5.8,1), @(-5.8,-1,-3.3,1), @(-1,3.3,1,5.8), @(-1,-5.8,1,-3.3) )
foreach($sl in $mslots){
  $s=$cd.Sketches.Add($XY); Rect $s $sl[0] $sl[1] $sl[2] $sl[3]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4.2*$f, $kPos, $kCut)|Out-Null
}
foreach($hx in -14.5,14.5){                            # Saeulen-Pilots (durch)
  $s=$cd.Sketches.Add($XY); Circ $s $hx 0 2.8
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 32.2*$f, $kPos, $kCut)|Out-Null
}
$topM=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 32*$f); $topM.Visible=$false
$s=$cd.Sketches.Add($topM); Circ $s 0 0 22.0           # Kupplungskammer
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 28*$f, $kNeg, $kCut)|Out-Null
$s=$cd.Sketches.Add($XZ); Rect $s -8 5 8 27            # Zugangsfenster beidseitig
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 30*$f, $kSym, $kCut)|Out-Null
SaveDoc $doc "Motorblock_N20"

# ================= 4) TASTER-SCHLITTEN v2 =================
Write-Host "4) Taster_Schlitten..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures
$XY=$cd.WorkPlanes.Item(3);$XZ=$cd.WorkPlanes.Item(2)
$s=$cd.Sketches.Add($XY); Rect $s -34 -20 34 20
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Rect $s 0 20 28 26           # Stuetzpad hinter Boss
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$top24=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 24*$f); $top24.Visible=$false
# Boss fuer V-153-Mikroschalter (27.8 lang, Loecher 22.2): Flaeche bei y=17.5
# (Stift-Bahn bei (0,14) bleibt frei), z 24..40
$s=$cd.Sketches.Add($top24); Rect $s 0 17.5 28 26
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 16*$f, $kPos, $kJoin)|Out-Null
# v5: LM8UU-Kugellager (Ã˜15 Presssitz) + T8-Anti-Backlash-Flanschmutter
$choles=@( @(-22,0,15.0), @(22,0,15.0), @(0,0,10.5), @(0,14,6.4) )
foreach($h in $choles){                                # Durchgangsbohrungen
  $s=$cd.Sketches.Add($top24); Circ $s $h[0] $h[1] $h[2]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24.2*$f, $kNeg, $kCut)|Out-Null
}
$s=$cd.Sketches.Add($XY); Circ $s 0 0 22.4             # T8-Flansch-Senkung (von unten)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kPos, $kCut)|Out-Null
foreach($a in 45,135,225,315){                          # 4x M3-Pilots auf Ã˜16-Lochkreis
  $r=[math]::PI*$a/180.0
  $s=$cd.Sketches.Add($XY); Circ $s (8*[math]::Cos($r)) (8*[math]::Sin($r)) 2.8
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut)|Out-Null
}
$s=$cd.Sketches.Add($XY); Circ $s 0 14 13.0            # Feder-Senkung von unten
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 14*$f, $kPos, $kCut)|Out-Null
foreach($hx in -9,9){                                  # Kappen-Pilotloecher
  $s=$cd.Sketches.Add($XY); Circ $s $hx 14 2.0
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut)|Out-Null
}
# V-153-Montage: 2 LANGLOECHER (3.2 x 8) im 22.2-Raster, M3 + Mutter hinten,
# hoehenverstellbar fuer die Hebel-Justage
$pBoss=$cd.WorkPlanes.AddByPlaneAndOffset($XZ, 17.5*$f); $pBoss.Visible=$false
foreach($sx in 2.9,25.1){
  $s=$cd.Sketches.Add($pBoss); Rect $s ($sx-1.6) 30 ($sx+1.6) 38
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8.7*$f, $kPos, $kCut)|Out-Null
}
SaveDoc $doc "Taster_Schlitten"

# ================= 5) KLEMMEN v2 (Koerper 24, Tasche 16) =================
Write-Host "5) Dreh_Klemme..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -14 -8 14 8
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY)                               # Flansch MIT Loechern (bewaehrt)
Circ $s 0 0 44.0
Circ $s 0 0 4.9
foreach($ang in 0,90,180,270){
  $r=[math]::PI*$ang/180.0
  Circ $s (16*[math]::Cos($r)) (16*[math]::Sin($r)) 4.2
}
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 4*$f, $kNeg, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 4.9              # Spline weiter in Koerper
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 6*$f, $kPos, $kCut)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 2.0              # M2 axial (Rest bis oben)
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24.2*$f, $kPos, $kCut)|Out-Null
$top24=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 24*$f); $top24.Visible=$false
$s=$cd.Sketches.Add($top24); Rect $s -10.1 -3.1 10.1 3.1
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 16*$f, $kNeg, $kCut)|Out-Null
# Senkung fuer M2-Schraubenkopf im Taschenboden (Probe muss PLAN aufliegen!)
$s=$cd.Sketches.Add($top24); Circ $s 0 0 4.6
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 18*$f, $kNeg, $kCut)|Out-Null
# M3-Klemmschraube quer: drueckt Grip gegen die Referenzwand (Breiten-Genauigkeit!)
$YZ=$cd.WorkPlanes.Item(1)
$s=$cd.Sketches.Add($YZ); Circ $s 0 16 2.6
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 30*$f, $kSym, $kCut)|Out-Null
SaveDoc $doc "Dreh_Klemme"

Write-Host "6) Idler_Klemme..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -14 -8 14 8
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 8.0              # Ã˜8-Zapfen nach unten
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kNeg, $kJoin)|Out-Null
$top24=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 24*$f); $top24.Visible=$false
$s=$cd.Sketches.Add($top24); Rect $s -10.1 -3.1 10.1 3.1
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 16*$f, $kNeg, $kCut)|Out-Null
# M3-Klemmschraube quer (wie Dreh_Klemme)
$YZ=$cd.WorkPlanes.Item(1)
$s=$cd.Sketches.Add($YZ); Circ $s 0 16 2.6
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 30*$f, $kSym, $kCut)|Out-Null
SaveDoc $doc "Idler_Klemme"

# ================= 6) TASTSTIFT + KAPPE + RAST_HALTER =================
Write-Host "7) Taststift..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circ $s 0 0 6.0
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 27*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 12.0             # Kragen unten
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3*$f, $kPos, $kJoin)|Out-Null
$s=$cd.Sketches.Add($XY); Circ $s 0 0 4.2              # Stahlstift-Aufnahme
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kPos, $kCut)|Out-Null
SaveDoc $doc "Taststift"

Write-Host "8) Taststift_Kappe..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -11 -10 11 10
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3*$f, $kPos, $kJoin)|Out-Null
$kholes=@( @(0,0,6.6), @(-9,0,2.4), @(9,0,2.4) )
foreach($h in $kholes){
  $s=$cd.Sketches.Add($XY); Circ $s $h[0] $h[1] $h[2]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 3.2*$f, $kPos, $kCut)|Out-Null
}
SaveDoc $doc "Taststift_Kappe"

Write-Host "9) Rast_Halter..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Rect $s -8 -8 8 8
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12*$f, $kPos, $kJoin)|Out-Null
$rholes=@( @(0,0,4.4), @(0,6,2.4), @(0,-6,2.4) )
foreach($h in $rholes){
  $s=$cd.Sketches.Add($XY); Circ $s $h[0] $h[1] $h[2]
  $ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 12.2*$f, $kPos, $kCut)|Out-Null
}
$topR=$cd.WorkPlanes.AddByPlaneAndOffset($XY, 12*$f); $topR.Visible=$false
$s=$cd.Sketches.Add($topR); Circ $s 0 0 8.0            # Feder-Tasche hinten
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 8*$f, $kNeg, $kCut)|Out-Null
SaveDoc $doc "Rast_Halter"

Write-Host "10) Index_Pin Ã˜4x24..."
$doc=NewPart;$cd=$doc.ComponentDefinition;$ef=$cd.Features.ExtrudeFeatures;$XY=$cd.WorkPlanes.Item(3)
$s=$cd.Sketches.Add($XY); Circ $s 0 0 4.0
$ef.AddByDistanceExtent($s.Profiles.AddForSolid(), 24*$f, $kPos, $kJoin)|Out-Null
SaveDoc $doc "Index_Pin"

Write-Host "ALLE TEILE FERTIG."


