param(
  [Parameter(Mandatory=$true)][string]$SourcePngPath,
  [Parameter(Mandatory=$true)][string]$OutIcoPath,
  [Parameter()][int]$Size = 48
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

if (!(Test-Path $SourcePngPath)) { throw "PNG not found: $SourcePngPath" }
if (Test-Path $OutIcoPath) { Remove-Item $OutIcoPath -Force }

$img = [System.Drawing.Image]::FromFile($SourcePngPath)
try {
  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  try {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
      $g.Clear([System.Drawing.Color]::Transparent)
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.DrawImage($img, 0, 0, $Size, $Size)
    } finally {
      $g.Dispose()
    }
    $bmp.Save($OutIcoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
  } finally {
    $bmp.Dispose()
  }
} finally {
  $img.Dispose()
}

Write-Host "Written $OutIcoPath (bytes=$((Get-Item $OutIcoPath).Length))"

