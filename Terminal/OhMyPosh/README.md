# Oh My Posh Installer & Nordtron Theme (FiraCode Nerd Font Mono)

This script installs **Oh My Posh**, copies your theme (default: `nordtron.omp.json`) to your home, updates your **PowerShell profile**, **installs ONLY FiraCode Nerd Font Mono**, and sets **Windows Terminal defaults** to:

```json
"defaults": {
  "colorScheme": "Argonaut",
  "font": {
    "face": "FiraCode Nerd Font Mono",
    "size": 9
  }
}
```

> Oh My Posh uses Nerd Fonts for icons/glyphs and recommends configuring a Nerd Font in your terminal. This script does that for Windows Terminal automatically.
> Windows Terminal font & color scheme settings are managed via `settings.json` or the Settings UI; the script safely updates the JSON and keeps a backup.

---

## Prerequisites

- **PowerShell** on Windows (Windows Terminal recommended).
- **winget** or **Chocolatey** (optional; used for Oh My Posh or font fallback).
- If script execution is blocked:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```

---

## Usage

Place `install-ohmyposh.ps1` and your theme (`nordtron.omp.json`) in the same folder, then run:

```powershell
# From the script folder
.\install-ohmyposh.ps1
```

What happens:

1. **Oh My Posh** is installed (via winget/Chocolatey).
2. **FiraCode Nerd Font Mono** is installed (OMP CLI first; Chocolatey fallback if needed).
3. Your theme is copied to **$HOME**.
4. Your **PowerShell profile** is updated with:
   ```powershell
   oh-my-posh init pwsh --config "$HOME\nordtron.omp.json" | Invoke-Expression
   ```
   (and a backup of your profile is saved).
5. **Windows Terminal defaults** are set to **Argonaut** + **FiraCode Nerd Font Mono** @ **9pt**.
   The script backs up `settings.json` before changing it.

Open a **new Windows Terminal / PowerShell** session to see the changes.

---

## Expected Terminal Prompt (Nordtron)

- **Line 1**: `┏[username]` · time `[HH:MM]` · Git `--[branch status]` + dots indicating changes, plus AWS/Kubernetes segments when active, root indicator `[⚡]`, and failure status `[x reason]`.
- **Line 2**: `┖[path]` and execution time `[Nms]`.
- **Line 3**: stylized prompt glyph before the cursor.

If glyphs appear as squares, verify Windows Terminal is using **FiraCode Nerd Font Mono** (the script sets this by default).

---

## Troubleshooting

- Verify Oh My Posh:
  ```powershell
  oh-my-posh version
  ```
- Check your profile:
  ```powershell
  $PROFILE
  Get-Content $PROFILE
  ```
- Print the theme config:
  ```powershell
  oh-my-posh print-config --config "$HOME\nordtron.omp.json"
  ```
- Fonts did not install?
  - OMP CLI installer may need a fresh shell; rerun the script or install via Chocolatey fallback.
  - You can always manually install from **Nerd Fonts** (FiraCode download).

---

## Rollback

- Restore your latest **PowerShell profile** backup:
  ```powershell
  $bak = Get-ChildItem "$PROFILE.bak-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($bak) { Copy-Item $bak.FullName $PROFILE -Force }
  ```
- Restore **Windows Terminal settings**:
  ```powershell
  $paths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  ) | Where-Object { Test-Path $_ }
  foreach ($p in $paths) {
    $bak = Get-ChildItem "$p.bak-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($bak) { Copy-Item $bak.FullName $p -Force }
  }
  ```
