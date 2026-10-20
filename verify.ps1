#requires -Version 5.1
<#
    Verify pcl.exe:
      1. compare SHA256 with the published checksum
      2. print file version information
      3. warn if the product name is not the official one

    Usage: powershell -ExecutionPolicy Bypass -File .\verify.ps1
#>

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$exe  = Join-Path $root 'pcl.exe'
$expected = 'a2f6122dfd295e4c62cf0f04484cfd8e261b15a243162dd3b12193f2378e0afc'

if (-not (Test-Path $exe)) {
    Write-Host "Not found: $exe" -ForegroundColor Red
    exit 1
}

$info = Get-Item $exe
$hash = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLower()
$vi   = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)

Write-Host "File        : $exe"
Write-Host "Size        : $($info.Length) bytes"
Write-Host "SHA256      : $hash"
Write-Host "ProductName : $($vi.ProductName)"
Write-Host "Version     : $($vi.FileVersion)"
Write-Host ""

if ($hash -eq $expected) {
    Write-Host "Checksum OK" -ForegroundColor Green
} else {
    Write-Host "Checksum MISMATCH (expected $expected)" -ForegroundColor Red
    exit 1
}

if ($vi.ProductName -ne 'Plain Craft Launcher') {
    Write-Host "WARNING: ProductName is not 'Plain Craft Launcher' - this may not be an official PCL binary" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next: close PCL, back up your pcl.exe, then copy this pcl.exe over it." -ForegroundColor Cyan
Write-Host "Then open the 'Download' page and check that Minecraft versions are listed." -ForegroundColor Cyan
