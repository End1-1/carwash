param(
  [Parameter(Mandatory=$true)][string]$PngA,
  [Parameter(Mandatory=$true)][string]$PngB,
  [Parameter()][int]$TargetSize = 64,
  [Parameter()][int]$Grid = 20
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Load-ResizedBitmap {
  param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)][int]$Size)
  $img = [System.Drawing.Image]::FromFile($Path)
  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($img, 0, 0, $Size, $Size)
  } finally {
    $g.Dispose()
    $img.Dispose()
  }
  return $bmp
}

if (!(Test-Path $PngA)) { throw "Not found: $PngA" }
if (!(Test-Path $PngB)) { throw "Not found: $PngB" }

$a = Load-ResizedBitmap -Path $PngA -Size $TargetSize
$b = Load-ResizedBitmap -Path $PngB -Size $TargetSize

try {
  $stepX = [Math]::Max(1, [int]($TargetSize / $Grid))
  $stepY = [Math]::Max(1, [int]($TargetSize / $Grid))
  $cnt = 0
  $sumAbs = 0.0
  for ($y = 0; $y -lt $TargetSize; $y += $stepY) {
    for ($x = 0; $x -lt $TargetSize; $x += $stepX) {
      $ca = $a.GetPixel($x, $y)
      $cb = $b.GetPixel($x, $y)
      $sumAbs += ([Math]::Abs($ca.R - $cb.R) + [Math]::Abs($ca.G - $cb.G) + [Math]::Abs($ca.B - $cb.B))
      $cnt++
    }
  }
  if ($cnt -le 0) { $cnt = 1 }
  $avgAbs = $sumAbs / $cnt
  Write-Host ("diff: avgAbsRGB={0:N2} overSamples={1} target={2}x{2}" -f $avgAbs, $cnt, $TargetSize)
} finally {
  $a.Dispose()
  $b.Dispose()
}

