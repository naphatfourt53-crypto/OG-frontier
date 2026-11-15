# ---------------------------------------------------------------------------
#  Build the team distribution: Project / Windows / Web / Legacy + checksums.
#  Usage:
#    powershell -NoProfile -ExecutionPolicy Bypass -File tools\package_team.ps1
#  Requires Godot 4.7.2 with export templates installed.
# ---------------------------------------------------------------------------
param(
    [string]$Version = "0.5.0",
    [string]$Godot = "",
    [string]$LegacyRef = "legacy-v0.1.0",
    [switch]$SkipExport
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

function Write-Step($msg) {
    Write-Host ""
    Write-Host "== $msg ==" -ForegroundColor Cyan
}

# ---------- locate Godot ----------
if ([string]::IsNullOrWhiteSpace($Godot)) {
    $parent = Split-Path $root -Parent
    $grand = Split-Path $parent -Parent
    $candidates = @(
        (Join-Path $root "Godot_v4.7.2-stable_win64_console.exe"),
        (Join-Path $parent "Godot_v4.7.2-stable_win64_console.exe"),
        (Join-Path $grand "Godot_v4.7.2-stable_win64_console.exe"),
        (Join-Path $root "Godot_v4.7.2-stable_win64.exe"),
        (Join-Path $parent "Godot_v4.7.2-stable_win64.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $Godot = $c; break }
    }
}
if ([string]::IsNullOrWhiteSpace($Godot) -or -not (Test-Path -LiteralPath $Godot)) {
    throw "Godot 4.7.2 not found. Pass -Godot 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'."
}
Write-Host "Godot: $Godot"

# ---------- build ----------
if (-not $SkipExport) {
Write-Step "Exporting Web"
New-Item -ItemType Directory -Force (Join-Path $root "builds\web") | Out-Null
& $Godot --headless --path $root --export-release "Web" "builds/web/index.html"
if ($LASTEXITCODE -ne 0) { throw "Web export failed (exit $LASTEXITCODE)." }

Write-Step "Exporting Windows"
New-Item -ItemType Directory -Force (Join-Path $root "builds\windows") | Out-Null
if (Test-Path (Join-Path $root "builds\windows\OGFrontier.pck")) {
    Remove-Item -Force (Join-Path $root "builds\windows\OGFrontier.pck")
}
& $Godot --headless --path $root --export-release "Windows Desktop" "builds/windows/OGFrontier.exe"
if ($LASTEXITCODE -ne 0) { throw "Windows export failed (exit $LASTEXITCODE)." }
}

# ---------- stage ----------
Write-Step "Staging packages"
$dist = Join-Path $root "dist"
$stage = Join-Path $dist "_stage"
if (Test-Path -LiteralPath $stage) { Remove-Item -Recurse -Force -LiteralPath $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
New-Item -ItemType Directory -Force $dist | Out-Null

$projName = "LastLaunch_v${Version}_Project"
$winName = "LastLaunch_v${Version}_Windows"
$webName = "LastLaunch_v${Version}_Web"
$legacyName = "LastLaunch_Legacy_v0.1.0_Project"

$projStage = Join-Path $stage $projName
$winStage = Join-Path $stage $winName
$webStage = Join-Path $stage $webName
$legacyStage = Join-Path $stage $legacyName

# Project: the repo minus caches, builds, dist and test output.
$excludeDirs = @(
    (Join-Path $root ".git"),
    (Join-Path $root ".godot"),
    (Join-Path $root "builds"),
    (Join-Path $root "dist"),
    (Join-Path $root "tests\out")
)
New-Item -ItemType Directory -Force $projStage | Out-Null
$roboArgs = @($root, $projStage, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/XD") + $excludeDirs + @("/XF", "*.zip", "*.exe")
& robocopy @roboArgs | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with code $LASTEXITCODE." }

# Windows: exe + ANGLE DLLs + launchers + readme.
New-Item -ItemType Directory -Force $winStage | Out-Null
Copy-Item (Join-Path $root "builds\windows\*") $winStage -Recurse -Force
Copy-Item (Join-Path $root "tools\launchers\RUN_LAST_LAUNCH.bat") $winStage -Force
Copy-Item (Join-Path $root "tools\launchers\RUN_LAST_LAUNCH_SAFE.bat") $winStage -Force
Copy-Item (Join-Path $root "tools\launchers\READ_ME_FIRST_WINDOWS.txt") (Join-Path $winStage "READ_ME_FIRST.txt") -Force
Copy-Item (Join-Path $root "START_HERE.txt") $winStage -Force

# Web: static files + local server + readme.
New-Item -ItemType Directory -Force $webStage | Out-Null
Copy-Item (Join-Path $root "builds\web\*") $webStage -Recurse -Force
Copy-Item (Join-Path $root "tools\launchers\PLAY_WEB.bat") $webStage -Force
Copy-Item (Join-Path $root "tools\launchers\serve_web.ps1") $webStage -Force
Copy-Item (Join-Path $root "tools\launchers\READ_ME_FIRST_WEB.txt") (Join-Path $webStage "READ_ME_FIRST.txt") -Force
Copy-Item (Join-Path $root "START_HERE.txt") $webStage -Force

# Legacy: the original 7-screen prototype from git, in its own top folder.
Write-Step "Staging Legacy $LegacyRef"
$legacyOk = $false
$tmpZip = Join-Path $dist "_legacy.zip"
try {
    & git -C $root rev-parse --verify $LegacyRef 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        if (Test-Path $tmpZip) { Remove-Item -Force $tmpZip }
        & git -C $root archive --format=zip --output=$tmpZip $LegacyRef
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tmpZip)) {
            New-Item -ItemType Directory -Force $legacyStage | Out-Null
            # git writes the zip itself, so no external tar.exe (which cannot
            # handle this repo's non-ASCII path).
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $legacyStage)
            if (Test-Path (Join-Path $legacyStage "project.godot")) { $legacyOk = $true }
        }
    }
} catch {
    $legacyOk = $false
}
if (Test-Path $tmpZip) { Remove-Item -Force $tmpZip }
if ($legacyOk) {
    $legacyNote = @"
LEGACY v0.1.0 - original prototype (7 screens)

This is the old version, kept for comparison only.
Open it with Godot 4.7.2 by selecting project.godot in this folder.
It predates the ISS story, tutorial, crew cabin, terminal, farm/prep and
EVA stamina systems, and it has no NASA photos or sound effects.
Use LastLaunch_v${Version} for the current demo.
"@
    [System.IO.File]::WriteAllText((Join-Path $legacyStage "READ_ME_FIRST.txt"), $legacyNote, (New-Object System.Text.UTF8Encoding($true)))
} else {
    Write-Host "  (legacy ref '$LegacyRef' not found - skipped)" -ForegroundColor Yellow
    if (Test-Path $legacyStage) { Remove-Item -Recurse -Force $legacyStage }
}

# ---------- UTF-8 BOM for Windows text files ----------
Get-ChildItem $stage -Recurse -Include *.txt -File | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($_.FullName, $text, (New-Object System.Text.UTF8Encoding($true)))
}

# ---------- sanity checks ----------
Write-Step "Checking package contents"
function Require($path, $label) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing $label : $path" }
}
Require (Join-Path $projStage "project.godot") "project.godot"
Require (Join-Path $projStage "scenes\menu.tscn") "scenes/menu.tscn"
Require (Join-Path $winStage "OGFrontier.exe") "Windows exe"
Require (Join-Path $webStage "index.html") "index.html"
Require (Join-Path $webStage "index.wasm") "index.wasm"
Require (Join-Path $webStage "index.pck") "index.pck"

# ---------- zip ----------
Write-Step "Creating ZIP files"
Add-Type -AssemblyName System.IO.Compression.FileSystem
function New-Package($sourceDir, $zipPath) {
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -Force -LiteralPath $zipPath }
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $sourceDir, $zipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $true)
    $item = Get-Item $zipPath
    Write-Host ("  {0}  {1:N1} MB" -f $item.Name, ($item.Length / 1MB))
}

$packages = @(
    @{ Dir = $projStage; Zip = (Join-Path $dist "$projName.zip") },
    @{ Dir = $winStage; Zip = (Join-Path $dist "$winName.zip") },
    @{ Dir = $webStage; Zip = (Join-Path $dist "$webName.zip") }
)
if ($legacyOk) {
    $packages += @{ Dir = $legacyStage; Zip = (Join-Path $dist "$legacyName.zip") }
}
foreach ($p in $packages) {
    New-Package $p.Dir $p.Zip
}

# ---------- top-level docs + checksums ----------
Copy-Item (Join-Path $root "START_HERE.txt") (Join-Path $dist "START_HERE.txt") -Force
$readme = @"
LAST LAUNCH v${Version} - TEAM PACKAGE
=====================================

Files to upload to the GitHub Release (tag v${Version}):
  $projName.zip   - open in Godot 4.7.2 (project.godot at the top level)
  $winName.zip    - Windows build, run RUN_LAST_LAUNCH.bat
  $webName.zip    - browser build, run PLAY_WEB.bat (best for old GPUs)
  $legacyName.zip - original 7-screen prototype (optional)

Do not commit these ZIPs to git: the exe is larger than GitHub's 100 MB limit.
Upload them as Release assets instead.

Checksums are in SHA256SUMS.txt.
"@
[System.IO.File]::WriteAllText((Join-Path $dist "README_UPLOAD.md"), $readme, (New-Object System.Text.UTF8Encoding($false)))

$hashLines = Get-ChildItem $dist -Filter *.zip | Sort-Object Name | ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLower()
    "$hash  $($_.Name)"
}
$hashLines | Set-Content -Encoding ASCII (Join-Path $dist "SHA256SUMS.txt")

Remove-Item -Recurse -Force $stage

Write-Step "Done"
Get-ChildItem $dist | Select-Object Name, @{N='MB';E={[math]::Round($_.Length/1MB,1)}} | Format-Table -AutoSize
Write-Host "Send the ZIPs (or the GitHub Release link) to the team."
