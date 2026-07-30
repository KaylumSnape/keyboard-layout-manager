# Keyboard Layout Manager

Keyboard Layout Manager selects a Windows keyboard layout based on whether a configured external keyboard is connected.

## Installation

Use `KeyboardLayoutManager-Setup-<version>.exe` for the normal installation experience.

It installs per-user under `%LOCALAPPDATA%\Keyboard Layout Manager`, creates a Start Menu shortcut, preserves an existing INI file during upgrades, and offers to launch the application.

The ZIP release is also available for portable/manual installation. It contains:

- `KeyboardLayoutManager.exe`
- `KeyboardLayoutManager.ini`
- `README.md`

Extract the ZIP to a user-writable folder such as `%LOCALAPPDATA%\Keyboard Layout Manager`. Do not use `Program Files`: the application saves tray settings to the INI file beside its executable.

## First Run

1. Ensure both the UK and US Windows keyboard layouts are installed.
2. Run `KeyboardLayoutManager.exe`.
3. Right-click its system-tray icon and select `Add Connected US Keyboard...`.
4. Follow the unplug/reconnect prompts. Confirm the newly detected keyboard to save its VID/PID in `KeyboardLayoutManager.ini`.

The tray menu also provides `Check Now`, `Show Status`, `Open Configuration File`, keyboard detection and setup, notification/startup toggles, reload, and exit.

## Configuration

`KeyboardLayoutManager.ini` is the only configuration file. It documents all available settings. After editing it manually, select `Reload` in the tray menu.

## Building A Release

Install the official AutoHotkey v2 compiler (`Ahk2Exe`), then run the following from this folder:

```powershell
.\build-release.ps1 -CompilerPath 'C:\Path\To\Ahk2Exe.exe'
```

To also create the installer, install Inno Setup 6 and supply its compiler path:

```powershell
.\build-release.ps1 -CompilerPath 'C:\Path\To\Ahk2Exe.exe' -InstallerCompilerPath 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
```

The script derives its release version from `APP_VERSION` in the source file. It uses the installed AutoHotkey v2 64-bit runtime by default. Supply `-RuntimePath` only when it is installed elsewhere or a 32-bit release is needed. It creates a matching ZIP and, when Inno Setup is supplied, installer. It refuses to build while `DEBUG_MODE` is set to `true` in the source script.

## License

Released under the [MIT License](LICENSE).
