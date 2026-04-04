param(
  [Parameter(Mandatory=$true)][string]$SourcePngPath,
  [Parameter(Mandatory=$true)][string]$OutPngPath,
  [Parameter()][string]$BackgroundHex = "#FFFFFF"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (!(Test-Path $SourcePngPath)) { throw "PNG not found: $SourcePngPath" }

function Parse-HexColor {
  param([Parameter(Mandatory=$true)][string]$Hex)
  $h = $Hex.TrimStart('#')
  if ($h.Length -ne 6) { throw "BackgroundHex must be #RRGGBB" }
  $r = [Convert]::ToInt32($h.Substring(0,2),16)
  $g = [Convert]::ToInt32($h.Substring(2,2),16)
  $b = [Convert]::ToInt32($h.Substring(4,2),16)
  return [System.Drawing.Color]::FromArgb(255,$r,$g,$b)
}

$bg = Parse-HexColor -Hex $BackgroundHex

$img = [System.Drawing.Image]::FromFile($SourcePngPath)
try {
  $w = $img.Width
  $h = $img.Height
  $bmp = New-Object System.Drawing.Bitmap $w,$h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.Clear($bg)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
  } finally {
    $g.Dispose()
  }

  if (Test-Path $OutPngPath) { Remove-Item $OutPngPath -Force }
  $bmp.Save($OutPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $img.Dispose()
  $bmp.Dispose()
}

Write-Host \"Written $OutPngPath (bg=$BackgroundHex)\" 

