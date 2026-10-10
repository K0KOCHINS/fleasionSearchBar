<# : batch portion
@echo off
title Fleasion Search Bar - Install / Update
set "FSB_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([IO.File]::ReadAllText($env:FSB_SELF)))"
if errorlevel 1 pause
exit /b
#>

# ---------------------------------------------------------------------------
# Fleasion Search Bar installer / updater
#
# Double-click the .bat. It finds the Fleasion .exe you already have, swaps it
# for the same Fleasion with the config search bar added (keeping a backup),
# and starts it. Run it again any time to update.
#
# Fleasion is made by the Fleasion team: https://github.com/fleasion/Fleasion
# Unofficial add-on, GPL v3.0: https://github.com/K0KOCHINS/fleasionSearchBar
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Windows.Forms

trap {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Nothing was changed unless it says so above.' -ForegroundColor Red
    exit 1
}

$Repo          = 'K0KOCHINS/fleasionSearchBar'
$PatchUrl      = "https://raw.githubusercontent.com/$Repo/main/fleasion-config-search.patch"
$PinnedCommit  = '7f4c6c1'
$ConfigDir     = Join-Path $env:LOCALAPPDATA 'FleasionNT'
$StateFile     = Join-Path $ConfigDir 'searchbar_install.json'
$WorkDir       = Join-Path $env:LOCALAPPDATA 'FleasionSearchBar'
$FreshInstall  = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Fleasion\Fleasion.exe'

function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }

function Show-Box($text, $buttons = 'OK', $icon = 'Information') {
    # Owner window keeps the popup in front of the console
    $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }
    try { return [System.Windows.Forms.MessageBox]::Show($owner, $text, 'Fleasion Search Bar', $buttons, $icon) }
    finally { $owner.Dispose() }
}

function Test-FleasionExe($path) {
    if (-not $path) { return $false }
    $path = $path.Trim('"')
    return (Test-Path -LiteralPath $path -PathType Leaf) -and ($path -like '*.exe') -and ((Split-Path $path -Leaf) -like '*leasion*')
}

# ---------------------------------------------------------------- find the exe
function Find-FleasionExe {
    # 1. Where we installed last time
    if (Test-Path $StateFile) {
        try {
            $state = Get-Content $StateFile -Raw | ConvertFrom-Json
            if (Test-FleasionExe $state.path) { return $state.path }
        } catch {}
    }
    # 2. A Fleasion that is running right now
    $running = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -like '*leasion*' -and $_.Path -and (Test-FleasionExe $_.Path) } |
        Select-Object -First 1
    if ($running) { return $running.Path }
    # 3. Fleasion's own Run on Boot record
    $autostart = Join-Path $ConfigDir 'autostart_info.json'
    if (Test-Path $autostart) {
        try {
            $info = Get-Content $autostart -Raw | ConvertFrom-Json
            if ($info.mode -eq 'exe' -and (Test-FleasionExe $info.path)) { return $info.path }
        } catch {}
    }
    try {
        $run = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction Stop).PSObject.Properties |
            Where-Object { $_.Name -like '*leasion*' } | Select-Object -First 1
        if ($run) {
            $candidate = ($run.Value -replace '^"([^"]+)".*$', '$1') -replace '^(\S+\.exe).*$', '$1'
            if (Test-FleasionExe $candidate) { return $candidate }
        }
    } catch {}
    # 4. Fleasion's Start Menu shortcut
    $lnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Fleasion.lnk'
    if (Test-Path $lnk) {
        try {
            $target = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).TargetPath
            if (Test-FleasionExe $target) { return $target }
        } catch {}
    }
    # 5. The usual download spots (newest first)
    $folders = @(
        (Join-Path $env:USERPROFILE 'Downloads'),
        [Environment]::GetFolderPath('Desktop'),
        [Environment]::GetFolderPath('MyDocuments')
    )
    $found = foreach ($folder in $folders) {
        if (Test-Path $folder) {
            Get-ChildItem -LiteralPath $folder -Filter 'Fleasion*.exe' -File -Depth 2 -ErrorAction SilentlyContinue
        }
    }
    $best = $found | Where-Object { $_.Name -notlike '*backup*' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($best) { return $best.FullName }
    return $null
}

# ------------------------------------------------------- get the patched build
function Get-ReleaseExe {
    Say 'Checking for the newest Fleasion + Search Bar build...'
    try {
        $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'FleasionSearchBar' }
    } catch {
        Say '  No ready-made build found online.' 'Yellow'
        return $null
    }
    $asset = $release.assets | Where-Object { $_.name -like '*Windows.exe' } | Select-Object -First 1
    if (-not $asset) { Say '  The newest release has no Windows .exe.' 'Yellow'; return $null }
    return [pscustomobject]@{ Tag = $release.tag_name; Name = $release.name; Url = $asset.browser_download_url }
}

function Add-ToolPaths {
    $env:PATH = "$env:USERPROFILE\.local\bin;$env:ProgramFiles\Git\cmd;$env:LOCALAPPDATA\Programs\Git\cmd;$env:PATH"
}

function Build-Locally {
    # Git and uv print normal progress on stderr, so rely on exit codes here
    $ErrorActionPreference = 'Continue'
    Say ''
    Say 'Building Fleasion + Search Bar on this PC. This takes 5-15 minutes the first time.' 'Cyan'
    Add-ToolPaths
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Say '  Installing Git...'
        winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements | Out-Host
        Add-ToolPaths
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git could not be installed. Install it from https://git-scm.com and run this again.' }
    }
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Say '  Installing uv...'
        Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
        Add-ToolPaths
        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { throw 'uv could not be installed. Install it from https://docs.astral.sh/uv/ and run this again.' }
    }
    $src = Join-Path $WorkDir 'src'
    if (Test-Path (Join-Path $src '.git')) {
        Say '  Updating Fleasion source...'
        git -C $src checkout -- . 2>$null
        git -C $src checkout main 2>$null
        git -C $src pull --quiet
    } else {
        Say '  Downloading Fleasion source...'
        New-Item -ItemType Directory -Force $WorkDir | Out-Null
        git clone --quiet --config core.autocrlf=false https://github.com/fleasion/Fleasion.git $src
        if ($LASTEXITCODE -ne 0) { throw 'Could not download Fleasion.' }
    }
    Say '  Adding the search bar...'
    $patch = Join-Path $WorkDir 'search.patch'
    Invoke-WebRequest $PatchUrl -OutFile $patch -UseBasicParsing
    git -C $src apply $patch 2>$null
    if ($LASTEXITCODE -ne 0) {
        Say '  Newest Fleasion changed; using the version the search bar was made for.' 'Yellow'
        git -C $src checkout -- . 2>$null
        git -C $src checkout --quiet $PinnedCommit
        git -C $src apply $patch
        if ($LASTEXITCODE -ne 0) { throw 'The search bar patch could not be applied.' }
    }
    Say '  Building (this is the slow part)...'
    Push-Location $src
    try {
        Remove-Item dist -Recurse -Force -ErrorAction SilentlyContinue
        uv sync --locked --group dev --quiet
        uv run build | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Building Fleasion failed.' }
    } finally { Pop-Location }
    $exe = Get-ChildItem (Join-Path $src 'dist') -Filter 'Fleasion-v*-Windows.exe' | Select-Object -First 1
    if (-not $exe) { throw 'The build finished but no .exe was made.' }
    $sha = (git -C $src rev-parse --short HEAD)
    return [pscustomobject]@{ Tag = "local-$sha"; Name = 'Local build'; File = $exe.FullName }
}

# ------------------------------------------------------------- close Fleasion
function Close-Fleasion($exePath) {
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*leasion*' }
    if (-not $procs) { return }
    $answer = Show-Box "Fleasion is running.`n`nRight-click its tray icon and choose Exit, then press OK.`n`n(Press Cancel to stop the update.)" 'OKCancel'
    if ($answer -ne 'OK') { throw 'Update cancelled.' }
    Start-Sleep -Seconds 2
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*leasion*' }
    if ($procs) {
        $force = Show-Box 'Fleasion is still running. Close it now?' 'YesNo' 'Warning'
        if ($force -ne 'Yes') { throw 'Update cancelled.' }
        $procs | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
}

# ======================================================================= main
Say '==============================================' 'Cyan'
Say '   Fleasion + Search Bar  -  install / update' 'Cyan'
Say '==============================================' 'Cyan'
Say ''

$target = Find-FleasionExe
if ($target) {
    Say "Found your Fleasion: $target" 'Green'
} else {
    $answer = Show-Box "Couldn't find your Fleasion .exe.`n`nYes = pick it yourself`nNo = install a new copy in Documents\Fleasion" 'YesNoCancel' 'Question'
    if ($answer -eq 'Yes') {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = 'Pick your Fleasion .exe'
        $dialog.Filter = 'Fleasion (*.exe)|*.exe'
        $dialog.InitialDirectory = Join-Path $env:USERPROFILE 'Downloads'
        if ($dialog.ShowDialog() -ne 'OK') { throw 'No file picked.' }
        $target = $dialog.FileName
    } elseif ($answer -eq 'No') {
        $target = $FreshInstall
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        Say "Installing to: $target" 'Green'
    } else {
        throw 'Cancelled.'
    }
}

# Already up to date?
$release = Get-ReleaseExe
$installedTag = $null
if (Test-Path $StateFile) {
    try { $installedTag = (Get-Content $StateFile -Raw | ConvertFrom-Json).tag } catch {}
}
$upToDate = $release -and $installedTag -eq $release.Tag -and (Test-Path -LiteralPath $target)
if (-not $release -and $installedTag -like 'local-*' -and (Test-Path -LiteralPath $target)) {
    $rebuild = Show-Box "You already have Fleasion + Search Bar.`n`nRebuild it with the newest Fleasion? This takes 5-15 minutes.`n`nNo = just start Fleasion" 'YesNo' 'Question'
    $upToDate = ($rebuild -ne 'Yes')
}
if ($upToDate) {
    Say ''
    Say 'You already have the newest version.' 'Green'
    Say 'Starting Fleasion...'
    Start-Process -FilePath $target -WorkingDirectory (Split-Path $target)
    Start-Sleep -Seconds 2
    exit 0
}

# Get the new .exe
$newExe = Join-Path $env:TEMP 'Fleasion-SearchBar-new.exe'
if ($release) {
    Say "Downloading $($release.Name)..."
    Invoke-WebRequest $release.Url -OutFile $newExe -UseBasicParsing
    $tag = $release.Tag
} else {
    $built = Build-Locally
    Copy-Item -LiteralPath $built.File -Destination $newExe -Force
    $tag = $built.Tag
}
if ((Get-Item $newExe).Length -lt 10MB) { throw 'The downloaded file looks broken. Try again in a few minutes.' }

# Swap it in, keeping a backup
Close-Fleasion $target
if (Test-Path -LiteralPath $target) {
    $backup = [IO.Path]::ChangeExtension($target, '.backup.exe')
    Copy-Item -LiteralPath $target -Destination $backup -Force
    Say "Backup of your old Fleasion: $backup"
}
for ($try = 1; $try -le 10; $try++) {
    try { Copy-Item -LiteralPath $newExe -Destination $target -Force; break }
    catch {
        if ($try -eq 10) { throw "Could not replace $target (is Fleasion still open?)" }
        Start-Sleep -Seconds 1
    }
}
Remove-Item $newExe -Force -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $target -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force $ConfigDir | Out-Null
@{ path = $target; tag = $tag; updated = (Get-Date).ToString('s') } | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8

if ($target -eq $FreshInstall) {
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Fleasion.lnk'))
    $shortcut.TargetPath = $target
    $shortcut.WorkingDirectory = Split-Path $target
    $shortcut.Save()
    Say 'Added a Fleasion shortcut to your Desktop.'
}

Say ''
Say 'Done! Starting Fleasion with the search bar. You can close this window.' 'Green'
Start-Process -FilePath $target -WorkingDirectory (Split-Path $target)
Start-Sleep -Seconds 3
exit 0
