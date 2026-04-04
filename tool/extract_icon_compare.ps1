param(
  [Parameter(Mandatory=$true)][string]$ExePath,
  [Parameter(Mandatory=$true)][string]$SourcePngPath,
  [Parameter(Mandatory=$true)][string]$OutPngPath
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function Get-AvgColor {
  param([Parameter(Mandatory=$true)][string]$Path)

  $img = [System.Drawing.Image]::FromFile($Path)
  try {
    $bmp = New-Object System.Drawing.Bitmap $img
    try {
      $w = $bmp.Width
      $h = $bmp.Height

      # Sample roughly a 25x25 grid (avoid full scan).
      $stepX = [Math]::Max(1, [int]($w / 25))
      $stepY = [Math]::Max(1, [int]($h / 25))

      $sumR = 0.0
      $sumG = 0.0
      $sumB = 0.0
      $cnt = 0.0

      for ($y = 0; $y -lt $h; $y += $stepY) {
        for ($x = 0; $x -lt $w; $x += $stepX) {
          $c = $bmp.GetPixel($x, $y)
          if ($c.A -gt 0) {
            $sumR += $c.R
            $sumG += $c.G
            $sumB += $c.B
            $cnt += 1.0
          }
        }
      }

      if ($cnt -le 0) { $cnt = 1.0 }

      return @{
        r = [Math]::Round($sumR / $cnt, 2)
        g = [Math]::Round($sumG / $cnt, 2)
        b = [Math]::Round($sumB / $cnt, 2)
      }
    } finally {
      $bmp.Dispose()
    }
  } finally {
    $img.Dispose()
  }
}

if (!(Test-Path $ExePath)) { throw "Exe not found: $ExePath" }
if (!(Test-Path $SourcePngPath)) { throw "Source PNG not found: $SourcePngPath" }

$ico = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
if ($null -eq $ico) { throw "Failed to extract icon from exe: $ExePath" }

$bmpOut = $ico.ToBitmap()
try {
  # Overwrite if exists.
  if (Test-Path $OutPngPath) { Remove-Item $OutPngPath -Force }
  $bmpOut.Save($OutPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $bmpOut.Dispose()
}

Write-Host "Extracted: $OutPngPath (bytes=$((Get-Item $OutPngPath).Length))"

$avgSrc = Get-AvgColor -Path $SourcePngPath
$avgExe = Get-AvgColor -Path $OutPngPath

Write-Host ("avg_src: r={0} g={1} b={2}" -f $avgSrc.r, $avgSrc.g, $avgSrc.b)
Write-Host ("avg_exe: r={0} g={1} b={2}" -f $avgExe.r, $avgExe.g, $avgExe.b)

