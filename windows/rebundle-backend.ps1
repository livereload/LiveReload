$DebugPreference = "continue"
$ErrorActionPreference = "stop"

$win_dir      = Split-Path ($MyInvocation.MyCommand.Path)
$packages_dir = Join-Path $win_dir ..\node_modules
$tools_dir    = Join-Path $win_dir tools
$7za          = Join-Path $tools_dir 7za.exe

$backend_dir = Join-Path $win_dir backend

function 7z-Pack([string]$archive, [string]$source) {
    & $7za a $archive $source | Out-Null
}

Push-Location $win_dir
Remove-Item res\bundled\backend.7z -ErrorAction Ignore
7z-Pack res\bundled\backend.7z backend
Pop-Location
