[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^$|^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CompilerPath,

    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$RuntimePath = (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),

    [Parameter()]
    [ValidateScript({ -not $_ -or (Test-Path $_ -PathType Leaf) })]
    [string]$InstallerCompilerPath
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSCommandPath
$sourceScript = Join-Path $projectRoot 'kb-layout-manager.ahk'

if ([string]::IsNullOrWhiteSpace($Version))
{
    $versionMatch = Select-String -Path $sourceScript -Pattern '^global APP_VERSION := "(\d+\.\d+\.\d+)"$' | Select-Object -First 1
    if (-not $versionMatch)
    {
        throw 'APP_VERSION was not found in kb-layout-manager.ahk.'
    }

    $Version = $versionMatch.Matches[0].Groups[1].Value
}

$defaultConfig = Join-Path $projectRoot 'KeyboardLayoutManager.default.ini'
$iconFile = Join-Path $projectRoot 'assets\KeyboardLayoutManager.ico'
$outputRoot = Join-Path $projectRoot 'release'
$packageName = "KeyboardLayoutManager-$Version"
$packageDirectory = Join-Path $outputRoot $packageName
$archivePath = Join-Path $outputRoot "$packageName.zip"
$installerScript = Join-Path $projectRoot 'installer.iss'
$installerPath = Join-Path $outputRoot "KeyboardLayoutManager-Setup-$Version.exe"

if (Select-String -Path $sourceScript -Pattern '^global DEBUG_MODE := true$' -Quiet)
{
    throw 'Set DEBUG_MODE to false before creating a distribution build.'
}

if (-not (Test-Path $iconFile -PathType Leaf))
{
    throw "Application icon was not found: $iconFile"
}

Remove-Item -Path $packageDirectory -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $archivePath -Force -ErrorAction SilentlyContinue
New-Item -Path $packageDirectory -ItemType Directory -Force | Out-Null

$executablePath = Join-Path $packageDirectory 'KeyboardLayoutManager.exe'
$compilerArguments = '/in "{0}" /out "{1}" /base "{2}" /icon "{3}"' -f $sourceScript, $executablePath, $RuntimePath, $iconFile
$compilerProcess = Start-Process -FilePath $CompilerPath -ArgumentList $compilerArguments -Wait -PassThru
if ($compilerProcess.ExitCode -ne 0 -or -not (Test-Path $executablePath -PathType Leaf))
{
    throw "Ahk2Exe failed to create $executablePath."
}

Copy-Item -Path $defaultConfig -Destination (Join-Path $packageDirectory 'KeyboardLayoutManager.ini')
New-Item -Path (Join-Path $packageDirectory 'assets') -ItemType Directory -Force | Out-Null
Copy-Item -Path $iconFile -Destination (Join-Path $packageDirectory 'assets\KeyboardLayoutManager.ico') -Force
Copy-Item -Path (Join-Path $projectRoot 'README.md') -Destination $packageDirectory
Compress-Archive -Path $packageDirectory -DestinationPath $archivePath

Write-Host "Release archive created: $archivePath"

if ($InstallerCompilerPath)
{
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    $installerArguments = '/DAppVersion="{0}" /DSourceDir="{1}" /DOutputDir="{2}" "{3}"' -f $Version, $packageDirectory, $outputRoot, $installerScript
    $installerProcess = Start-Process -FilePath $InstallerCompilerPath -ArgumentList $installerArguments -Wait -PassThru

    if ($installerProcess.ExitCode -ne 0 -or -not (Test-Path $installerPath -PathType Leaf))
    {
        throw "Inno Setup failed to create $installerPath."
    }

    Write-Host "Installer created: $installerPath"
}