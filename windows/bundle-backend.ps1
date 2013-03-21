$DebugPreference = "continue"
$ErrorActionPreference = "stop"

$win_dir      = Split-Path ($MyInvocation.MyCommand.Path)
$packages_dir = Join-Path $win_dir ..\node_modules
$tools_dir    = Join-Path $win_dir tools
$7za          = Join-Path $tools_dir 7za.exe

$backend_dir = Join-Path $win_dir backend
$interim_dir = Join-Path $win_dir backend-interim

function 7z-Unpack([string]$archive) {
    & $7za x $archive | Out-Null
}

function 7z-Pack([string]$archive, [string]$source) {
    & $7za a $archive $source | Out-Null
}

function Copy-NPM-Package([string]$package, [string]$destination) {
    $package_dir = Join-Path $packages_dir $package
    $package_json = Get-Content $package_dir\package.json | Out-String | ConvertFrom-JSON
    $version = $package_json.version
    $pack_name = "$package-$version"

    Write-Host "$package $($version)"

    Push-Location $interim_dir
    if (!(Test-Path "$pack_name.tar")) {
        npm pack $package_dir | Out-Null
        7z-Unpack "$pack_name.tgz"
    }
    7z-Unpack "$pack_name.tar"
    Pop-Location

    New-Item (Split-Path $destination) -Type directory -ErrorAction Ignore | Out-Null
    Move-Item (Join-Path $interim_dir package) $destination

    if ($package_json.dependencies) {
        foreach($dep in ($package_json.dependencies).psobject.properties.GetEnumerator()) {
            $subpackage = $dep.Name
            $subpackage_version_range = $dep.Value
            if (Test-Path (Join-Path $packages_dir $subpackage)) {
                Write-Host "$package $($version):  cp $subpackage"
                Copy-NPM-Package $subpackage (Join-Path $destination node_modules\$subpackage)
            } else {
                Write-Host "$package $($version):  npm install '$subpackage@$subpackage_version_range'"
                Push-Location $destination
                New-Item node_modules -Type directory -ErrorAction Ignore | Out-Null
                npm install "$subpackage@$subpackage_version_range" | Out-Null
                Pop-Location
            }
        }
    }
}

Remove-Item $interim_dir -Recurse -Force -ErrorAction Ignore
New-Item $interim_dir -type directory | Out-Null

Remove-Item $backend_dir -Recurse -Force -ErrorAction Ignore

Copy-NPM-Package livereload $backend_dir

Push-Location $win_dir
Remove-Item res\bundled\backend.7z -ErrorAction Ignore
7z-Pack res\bundled\backend.7z backend
Pop-Location
