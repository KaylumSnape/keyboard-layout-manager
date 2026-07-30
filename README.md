# Keyboard Layout Manager

Keyboard Layout Manager automatically selects the appropriate Windows keyboard layout for a configured external keyboard and restores that choice after Windows resets the input language.

## Why It Is Needed

Windows can revert the selected input language to the default layout after a device is locked or restarted.

This utility detects keyboard and session changes, then automatically reapplies the appropriate layout so the desired input state is retained.

## Use Case

Use a UK laptop keyboard on the move and a US external keyboard at your desk. Keyboard Layout Manager automatically applies UK when the external keyboard is disconnected and US when the configured keyboard is connected, including after lock/unlock.

## What It Does

- Runs from the Windows system tray and responds to keyboard and session events.
- Identifies one or more US keyboards through a guided unplug/reconnect setup.
- Stores editable settings beside the application and can start automatically when you sign in.

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
2. Install **Keyboard Layout Manager** by running `KeyboardLayoutManager-Setup-<version>.exe`. Leave the launch option selected at the end of setup.
3. Find the **Keyboard Layout Manager** icon in the system tray. Windows may place it in the tray overflow (`^`) menu initially, or hide it and require you to go to `Taskbar setting` > `Other system tray icons`.
4. Right-click the icon and select `Add Connected US Keyboard...`.
5. Follow the unplug/reconnect prompts and confirm the detected keyboard.

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
