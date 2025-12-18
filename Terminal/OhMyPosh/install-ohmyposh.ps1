<#! 
.SYNOPSIS
    Install Oh My Posh, copy a theme, update the user's PowerShell profile,
    install ONLY FiraCode Nerd Font Mono, and set Windows Terminal defaults.

.DESCRIPTION
    - Installs Oh My Posh (winget/Chocolatey).
    - Copies a co-located theme (default: nordtron.omp.json) to the user's home.
    - Updates the current user's PowerShell profile to init Oh My Posh with that theme.
    - Detects and installs **FiraCode Nerd Font Mono** only (no bulk font installs).
    - Updates Windows Terminal defaults to:
        colorScheme = Argonaut
        font.face   = FiraCode Nerd Font Mono
        font.size   = 9

.PARAMETER ThemePath
    Optional path to theme (.omp.json). Defaults to 'nordtron.omp.json'.
    If relative, resolved against the script's folder.

.PARAMETER Force
    Optional. Overwrite existing theme copy and replace prior init lines.

.NOTES
    - After running, Windows Terminal defaults are set automatically.
    - Oh My Posh recommends using a Nerd Font; we install FiraCode Nerd Font Mono
      and configure Windows Terminal to use it.

.EXAMPLE
    ./install-ohmyposh.ps1

.EXAMPLE
    ./install-ohmyposh.ps1 -ThemePath '.\my-theme.omp.json' -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position=0)]
    [string]$ThemePath = 'nordtron.omp.json',
    [switch]$Force
)

# ---------- Helpers ----------
function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host $msg -ForegroundColor Green }
function Write-Warn($msg) { Write-Warning $msg }
function Write-Err($msg)  { Write-Host $msg -ForegroundColor Red }

# ---------- Oh My Posh install ----------
function Ensure-OhMyPoshInstalled {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Ok "Oh My Posh is already installed: $(oh-my-posh version)"
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info 'Installing Oh My Posh via winget...'
        try {
            winget install JanDeDobbeleer.OhMyPosh --silent --accept-package-agreements --accept-source-agreements | Out-Null
        } catch {
            Write-Warn "winget install failed: $($_.Exception.Message)"
        }
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { Write-Ok 'Oh My Posh installed via winget.'; return }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info 'Installing Oh My Posh via Chocolatey...'
        try { choco install oh-my-posh -y | Out-Null } catch { Write-Warn "Chocolatey install failed: $($_.Exception.Message)" }
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { Write-Ok 'Oh My Posh installed via Chocolatey.'; return }
    }

    Write-Warn 'Could not auto-install Oh My Posh. Please install it manually:'
    Write-Host ' - winget install JanDeDobbeleer.OhMyPosh' -ForegroundColor Yellow
    Write-Host ' - Docs: https://ohmyposh.dev/docs/installation/fonts' -ForegroundColor Yellow
    throw 'Oh My Posh is not installed.'
}

# ---------- Theme path/Copy ----------
function Resolve-ThemePath {
    param([string]$Path)
    $scriptDir = $PSScriptRoot

    if (Test-Path -LiteralPath $Path) { return (Resolve-Path -LiteralPath $Path).Path }

    $candidate = Join-Path -Path $scriptDir -ChildPath $Path
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }

    throw "Theme file not found: $Path"
}

function Copy-ThemeToHome {
    param([string]$SourcePath)
    $home = [Environment]::GetFolderPath('UserProfile')
    $destName = Split-Path -Leaf $SourcePath
    $destPath = Join-Path -Path $home -ChildPath $destName

    if ((Test-Path -LiteralPath $destPath) -and -not $Force) {
        Write-Info "Theme already exists at $destPath (use -Force to overwrite)."
    } else {
        Copy-Item -LiteralPath $SourcePath -Destination $destPath -Force
        Write-Ok "Copied theme to $destPath"
    }

    return $destPath
}

# ---------- Profile update ----------
function Update-Profile {
    param([string]$ThemeDestPath)
    $profilePath = $PROFILE
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path -LiteralPath $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    if (Test-Path -LiteralPath $profilePath) {
        $backupPath = "$profilePath.bak-$timestamp"
        Copy-Item -LiteralPath $profilePath -Destination $backupPath -Force
        Write-Info "Profile backed up: $backupPath"
    }

    $content = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath } else { @() }

    # Remove existing oh-my-posh init lines to avoid duplicates
    $filtered = $content | Where-Object { $_ -notmatch 'oh-my-posh\s+init\s+pwsh' }

    $initLine = 'oh-my-posh init pwsh --config "{0}" | Invoke-Expression' -f $ThemeDestPath
    $newContent = @($filtered) + $initLine

    Set-Content -LiteralPath $profilePath -Value $newContent -Encoding utf8
    Write-Ok "Updated profile: $profilePath"
    Write-Host "Added init line:" -ForegroundColor Cyan
    Write-Host $initLine -ForegroundColor Yellow
}

# ---------- Nerd Font: FiraCode Nerd Font Mono ----------
function Test-FiraCodeMonoInstalled {
    $fontDirs   = @("$env:WINDIR\Fonts", "$env:LOCALAPPDATA\Microsoft\Windows\Fonts")
    $foundInFiles = $false

    foreach ($dir in $fontDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem $dir -ErrorAction SilentlyContinue | Where-Object {
                $_.Extension -match '\.(ttf|otf)$' -and (
                    $_.Name -match [Regex]::Escape('FiraCode') -and
                    $_.Name -match 'Nerd\s*Font' -and
                    $_.Name -match 'Mono'
                )
            }
            if ($files) { $foundInFiles = $true; break }
        }
    }

    $regKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
        'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    )
    $foundInReg = $false
    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            $props = (Get-Item $key).Property
            foreach ($p in $props) {
                $value = (Get-ItemProperty -Path $key -Name $p).$p
                if ($p -match 'FiraCode' -and $p -match 'Nerd\s*Font' -and $p -match 'Mono') { $foundInReg = $true; break }
                if ($value -match 'FiraCode' -and $value -match 'Nerd\s*Font' -and $value -match 'Mono') { $foundInReg = $true; break }
            }
        }
    }

    return ($foundInFiles -or $foundInReg)
}

function Install-FiraCodeMono {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Info "Installing FiraCode Nerd Font via Oh My Posh (per-user)..."
        try {
            oh-my-posh font install FiraCode
        } catch {
            Write-Warn "oh-my-posh font installer failed: $($_.Exception.Message)"
        }
    }

    if (-not (Test-FiraCodeMonoInstalled)) {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Info "Installing FiraCode Nerd Font via Chocolatey..."
            try { choco install nerd-fonts-firacode -y | Out-Null } catch { Write-Warn "Chocolatey fallback failed: $($_.Exception.Message)" }
        } else {
            Write-Warn "Chocolatey not available for fallback. Consider manual install from https://www.nerdfonts.com/ (FiraCode)."
        }
    }

    if (Test-FiraCodeMonoInstalled) {
        Write-Ok "FiraCode Nerd Font Mono installed."
    } else {
        Write-Err "Failed to install FiraCode Nerd Font Mono. Please install manually and rerun."
        throw "FiraCode Nerd Font Mono not installed."
    }
}

# ---------- Windows Terminal defaults update ----------
function Get-WindowsTerminalSettingsPaths {
    $paths = @()
    $store = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $unpkg = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
    if (Test-Path $store) { $paths += $store }
    if (Test-Path $unpkg) { $paths += $unpkg }
    return $paths
}

function Update-WindowsTerminalDefaults {
    param(
        [string]$FontFace = 'FiraCode Nerd Font Mono',
        [int]$FontSize = 9,
        [string]$ColorScheme = 'Argonaut'
    )

    $paths = Get-WindowsTerminalSettingsPaths
    if (-not $paths) {
        Write-Warn "Windows Terminal settings.json not found. Open Windows Terminal once to generate settings, or set font via UI. (Ctrl+,)"
        return
    }

    foreach ($settingsPath in $paths) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$settingsPath.bak-$timestamp"
        Copy-Item -LiteralPath $settingsPath -Destination $backup -Force
        Write-Info "Backed up Windows Terminal settings: $backup"

        $json = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json

        if (-not $json.profiles) { $json | Add-Member -NotePropertyName profiles -NotePropertyValue @{ } }
        if (-not $json.profiles.defaults) { $json.profiles.defaults = @{} }

        if (-not $json.profiles.defaults.font) { $json.profiles.defaults.font = @{} }
        $json.profiles.defaults.font.face = $FontFace
        $json.profiles.defaults.font.size = $FontSize
        $json.profiles.defaults.colorScheme = $ColorScheme

        $json | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath -Encoding utf8
        Write-Ok "Updated Windows Terminal defaults at: $settingsPath"
        Write-Host " - colorScheme: $ColorScheme" -ForegroundColor Cyan
        Write-Host " - font.face:   $FontFace" -ForegroundColor Cyan
        Write-Host " - font.size:   $FontSize" -ForegroundColor Cyan
    }
}

# ---------- Main ----------
try {
    Write-Info 'Checking Oh My Posh installation...'
    Ensure-OhMyPoshInstalled

    Write-Info 'Ensuring FiraCode Nerd Font Mono is installed...'
    Install-FiraCodeMono

    Write-Info 'Resolving theme path...'
    $resolvedTheme = Resolve-ThemePath -Path $ThemePath

    Write-Info 'Copying theme to home folder...'
    $destThemePath = Copy-ThemeToHome -SourcePath $resolvedTheme

    Write-Info 'Updating PowerShell profile...'
    Update-Profile -ThemeDestPath $destThemePath

    Write-Info 'Updating Windows Terminal defaults (Argonaut + FiraCode Nerd Font Mono @ 9pt)...'
    Update-WindowsTerminalDefaults -FontFace 'FiraCode Nerd Font Mono' -FontSize 9 -ColorScheme 'Argonaut'

    Write-Ok 'All done! Open a NEW PowerShell window to see your updated prompt.'
}
catch {
    Write-Warn $_
    exit 1
}
