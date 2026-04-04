param(
  [Parameter(Mandatory=$true)][string]$PngPath,
  [Parameter()][int]$Grid = 40
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (!(Test-Path $PngPath)) { throw "PNG not found: $PngPath" }

$img = [System.Drawing.Bitmap]::FromFile($PngPath)
try {
  $w = $img.Width
  $h = $img.Height

  $stepX = [Math]::Max(1, [int]($w / $Grid))
  $stepY = [Math]::Max(1, [int]($h / $Grid))

  $tot = 0
  $tr = 0

  for ($y = 0; $y -lt $h; $y += $stepY) {
    for ($x = 0; $x -lt $w; $x += $stepX) {
      $c = $img.GetPixel($x, $y)
      $tot++
      if ($c.A -eq 0) { $tr++ }
    }
  }

  if ($tot -le 0) { $tot = 1 }
  $frac = [Math]::Round(($tr / $tot) * 100.0, 2)
  Write-Host ("png={0} {1}x{2} samples={3} transparentSamples={4} transparentFrac={5}% " -f $PngPath, $w, $h, $tot, $tr, $frac)
}
finally {
  $img.Dispose()
}

