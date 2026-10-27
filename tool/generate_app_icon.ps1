# Generates the Android launcher icons from the same visual language as the
# in-app AppLogo: indigo gradient, a white terminal card and a gold status dot.
#
# Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File tool\generate_app_icon.ps1
#
# The generated PNGs are committed; this script only needs to run again when
# the artwork changes.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$brandDir = Join-Path $root 'assets\brand'
$resDir = Join-Path $root 'android\app\src\main\res'

function New-RoundedPath {
  param(
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [float]$Radius
  )
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = $Radius * 2
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    $X + $Width - $diameter,
    $Y + $Height - $diameter,
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-Canvas {
  param([int]$Size)
  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $bitmap.SetResolution(96, 96)
  return $bitmap
}

function Get-Graphics {
  param([System.Drawing.Bitmap]$Bitmap)
  $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode =
    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode =
    [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.CompositingQuality =
    [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  return $graphics
}

function Fill-Background {
  param([System.Drawing.Graphics]$Graphics)
  $rect = New-Object System.Drawing.Rectangle(0, 0, 1024, 1024)
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.ColorTranslator]::FromHtml('#5A66E2'),
    [System.Drawing.ColorTranslator]::FromHtml('#3C47B5'),
    45
  )
  $Graphics.FillRectangle($brush, $rect)
  $brush.Dispose()
}

function Draw-Mark {
  param([System.Drawing.Graphics]$Graphics)
  $indigo = [System.Drawing.ColorTranslator]::FromHtml('#4F5BD5')
  $gold = [System.Drawing.ColorTranslator]::FromHtml('#F0C36A')

  $card = New-RoundedPath -X 272 -Y 322 -Width 480 -Height 380 -Radius 72
  $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $Graphics.FillPath($white, $card)

  $promptPen = New-Object System.Drawing.Pen($indigo, 44)
  $promptPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $promptPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $promptPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $points = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(382, 458)),
    (New-Object System.Drawing.PointF(462, 512)),
    (New-Object System.Drawing.PointF(382, 566))
  )
  $Graphics.DrawLines($promptPen, $points)
  $Graphics.DrawLine($promptPen, 520, 566, 642, 566)

  $ring = New-Object System.Drawing.SolidBrush($indigo)
  $Graphics.FillEllipse($ring, 694, 644, 116, 116)
  $dot = New-Object System.Drawing.SolidBrush($gold)
  $Graphics.FillEllipse($dot, 706, 656, 92, 92)

  $card.Dispose()
  $white.Dispose()
  $promptPen.Dispose()
  $ring.Dispose()
  $dot.Dispose()
}

function Export-Scaled {
  param(
    [System.Drawing.Bitmap]$Source,
    [int]$Size,
    [string]$Destination
  )
  $target = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = Get-Graphics -Bitmap $target
  $rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
  $graphics.DrawImage($Source, $rect)
  $graphics.Dispose()
  $target.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
  $target.Dispose()
}

function Export-Circular {
  param(
    [System.Drawing.Bitmap]$Source,
    [int]$Size,
    [string]$Destination
  )
  $scaled = New-Object System.Drawing.Bitmap($Size, $Size)
  $scaledGraphics = Get-Graphics -Bitmap $scaled
  $scaledGraphics.DrawImage(
    $Source,
    (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size))
  )
  $scaledGraphics.Dispose()

  $target = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = Get-Graphics -Bitmap $target
  $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
  $clip.AddEllipse(0, 0, $Size, $Size)
  $graphics.SetClip($clip)
  $graphics.DrawImage(
    $scaled,
    (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size))
  )
  $graphics.Dispose()
  $clip.Dispose()
  $scaled.Dispose()
  $target.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
  $target.Dispose()
}

New-Item -ItemType Directory -Force -Path (Join-Path $resDir 'mipmap-anydpi-v26') |
  Out-Null

# Full launcher artwork, also kept as the source asset.
$icon = New-Canvas -Size 1024
$iconGraphics = Get-Graphics -Bitmap $icon
Fill-Background -Graphics $iconGraphics
Draw-Mark -Graphics $iconGraphics
$iconGraphics.Dispose()
$icon.Save(
  (Join-Path $brandDir 'app_icon.png'),
  [System.Drawing.Imaging.ImageFormat]::Png
)

# Transparent adaptive foreground: the same mark without the background.
$foreground = New-Canvas -Size 1024
$foregroundGraphics = Get-Graphics -Bitmap $foreground
$foregroundGraphics.Clear([System.Drawing.Color]::Transparent)
Draw-Mark -Graphics $foregroundGraphics
$foregroundGraphics.Dispose()
$foreground.Save(
  (Join-Path $brandDir 'app_icon_foreground.png'),
  [System.Drawing.Imaging.ImageFormat]::Png
)

$legacySizes = [ordered]@{
  'mdpi' = 48
  'hdpi' = 72
  'xhdpi' = 96
  'xxhdpi' = 144
  'xxxhdpi' = 192
}
$foregroundSizes = [ordered]@{
  'mdpi' = 108
  'hdpi' = 162
  'xhdpi' = 216
  'xxhdpi' = 324
  'xxxhdpi' = 432
}

foreach ($entry in $legacySizes.GetEnumerator()) {
  $folder = Join-Path $resDir ("mipmap-" + $entry.Key)
  Export-Scaled -Source $icon -Size $entry.Value `
    -Destination (Join-Path $folder 'ic_launcher.png')
  Export-Circular -Source $icon -Size $entry.Value `
    -Destination (Join-Path $folder 'ic_launcher_round.png')
}

foreach ($entry in $foregroundSizes.GetEnumerator()) {
  $folder = Join-Path $resDir ("mipmap-" + $entry.Key)
  Export-Scaled -Source $foreground -Size $entry.Value `
    -Destination (Join-Path $folder 'ic_launcher_foreground.png')
}

$icon.Dispose()
$foreground.Dispose()

Write-Host 'Launcher icons generated.'
