# Changelog

All notable changes to Keyboard Layout Manager are documented in this file.

## [1.1.3] - 2026-07-30

### Added

- Custom transparent application icon for the tray, executable, shortcuts, and installer.

## [1.1.2] - 2026-07-30

### Added

- System-tray application version display.
- `Open Configuration File` tray action.
- Guided unplug/reconnect workflow for adding preferred US keyboards.
- Per-user Inno Setup installer and portable ZIP release builds.
- INI-backed settings with generated, documented defaults.
- Startup-folder shortcut management and configurable notifications.

### Changed

- Keyboard and layout checks remain event-driven using Windows device and session notifications.
- Layout switching retries are configurable through the INI file.
- Release builds derive their version from `APP_VERSION` in the AutoHotkey source.
