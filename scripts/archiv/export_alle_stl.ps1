# Exportiert ALLE .ipt-Dateien im Ordner als einzelne .stl (zum 3D-Drucken).
$ErrorActionPreference = "Stop"
$dir="H:\ZwickRoell Projekt"
$kBrowse=13059; $STLID="{533E9A98-FC3B-11D4-8E7E-0010B541CD80}"

try { $inv=[Runtime.InteropServices.Marshal]::GetActiveObject("Inventor.Application") }
catch { $inv=New-Object -ComObject Inventor.Application }
$inv.Visible=$false; $inv.SilentOperation=$true
while ($inv.Documents.Count -gt 0) { $inv.Documents.Item(1).Close($true) }

$stl=$inv.ApplicationAddIns.ItemById($STLID)

foreach ($ipt in Get-ChildItem $dir -Filter *.ipt) {
  try {
    $doc=$inv.Documents.Open($ipt.FullName,$false)
    $outStl = [IO.Path]::ChangeExtension($ipt.FullName, ".stl")
    $ctx=$inv.TransientObjects.CreateTranslationContext(); $ctx.Type=$kBrowse
    $opts=$inv.TransientObjects.CreateNameValueMap()
    $data=$inv.TransientObjects.CreateDataMedium(); $data.FileName=$outStl
    if ($stl.HasSaveCopyAsOptions($doc,$ctx,$opts)) { try{$opts.Value("Resolution")=1}catch{} }
    $stl.SaveCopyAs($doc,$ctx,$opts,$data)
    $doc.Close($true)
    Write-Host ("STL: {0} ({1:N1} KB)" -f (Split-Path $outStl -Leaf),((Get-Item $outStl).Length/1KB))
  } catch { Write-Host "FEHLER bei $($ipt.Name): $($_.Exception.Message)" }
}
Write-Host "Alle STL exportiert."
