param(
  [Parameter(Mandatory=$true)][string]$SourcePngPath,
  [Parameter(Mandatory=$true)][string]$OutIcoPath,
  [Parameter()][int]$Size = 48
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32 {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool DestroyIcon(IntPtr hIcon);
}
"@

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

    $hIcon = $bmp.GetHicon()
    try {
      $icon = [System.Drawing.Icon]::FromHandle($hIcon)
      try {
        # Icon.Save expects a Stream.
        $fs = [System.IO.File]::Open($OutIcoPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        try {
          $icon.Save($fs)
        } finally {
          $fs.Close()
          $fs.Dispose()
        }
      } finally {
        $icon.Dispose()
      }
    } finally {
      [void][Win32]::DestroyIcon($hIcon)
    }
  } finally {
    $bmp.Dispose()
  }
} finally {
  $img.Dispose()
}

Write-Host "Written $OutIcoPath (bytes=$((Get-Item $OutIcoPath).Length))"

