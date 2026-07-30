#ifndef AppVersion
  #define AppVersion "1.1.5"
#endif

#ifndef SourceDir
  #error "SourceDir must point to the staged release directory."
#endif

#ifndef OutputDir
  #define OutputDir "release"
#endif

#define AppName "Keyboard Layout Manager"
#define AppPublisher "Kaylum Snape"
#define AppPublisherUrl "https://github.com/KaylumSnape"
#define AppExeName "KeyboardLayoutManager.exe"

[Setup]
AppId={{A1E6B1B7-71D1-494A-8E4B-49C42D7A11E6}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherUrl}
AppSupportURL={#AppPublisherUrl}
DefaultDirName={localappdata}\Keyboard Layout Manager
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=KeyboardLayoutManager-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#SourceDir}\assets\KeyboardLayoutManager.ico
CloseApplications=yes
RestartApplications=no
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}

[Files]
Source: "{#SourceDir}\KeyboardLayoutManager.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\KeyboardLayoutManager.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "{#SourceDir}\assets\KeyboardLayoutManager.ico"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "{#SourceDir}\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Keyboard Layout Manager"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch Keyboard Layout Manager"; Flags: nowait postinstall skipifsilent