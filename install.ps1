# EmfPreview - install the class library and the template into a Clarion 12 Unicode installation
# Usage:  powershell -ExecutionPolicy Bypass -File install.ps1 [-ClarionRoot C:\Clarion12unicode]
param([string]$ClarionRoot = "C:\Clarion12unicode")

$ErrorActionPreference = "Stop"
$src = Join-Path $PSScriptRoot "src"
$libsrc = Join-Path $ClarionRoot "accessory\libsrc\win"
$tpl = Join-Path $ClarionRoot "accessory\template\win"
$cl = Join-Path $ClarionRoot "bin\ClarionCL.exe"

if (-not (Test-Path $cl)) { throw "ClarionCL.exe not found under $ClarionRoot - is this a Clarion 12 Unicode installation?" }
New-Item -ItemType Directory -Force $libsrc | Out-Null
New-Item -ItemType Directory -Force $tpl | Out-Null

Copy-Item (Join-Path $src "EmfPreview.inc") $libsrc -Force
Copy-Item (Join-Path $src "EmfPreview.clw") $libsrc -Force
Copy-Item (Join-Path $src "EmfPreview.tpl") $tpl -Force
Write-Host "Copied EmfPreview.inc / .clw -> $libsrc"
Write-Host "Copied EmfPreview.tpl        -> $tpl"

# register the template chain (an already running IDE must be restarted to see it)
& $cl -tr (Join-Path $tpl "EmfPreview.tpl")
Write-Host "Template registered. Restart the Clarion IDE if it is open."
Write-Host "In your app: Global Extensions -> add 'EMF Unicode Previewer - Global (activate)'."
