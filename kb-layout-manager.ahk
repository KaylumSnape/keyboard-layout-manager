#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================================
; Keyboard Layout Manager
; Version: 1.1.5
;
; Automatically selects the configured preferred layout when a configured
; keyboard is connected, and the default layout when it is not.
;
; Settings are stored beside this script or compiled executable in
; KeyboardLayoutManager.ini. Add keyboard VID/PID values to the
; [PreferredUSKeyboards] section in that file. The INI file also documents
; every setting and the available system tray actions.
; ============================================================================

global DEBUG_MODE := false

global LANG_US := 0x0409
global LANG_UK := 0x0809
global APP_NAME := "Keyboard Layout Manager"
global APP_VERSION := "1.1.5"
global APP_MENU_TITLE := APP_NAME " (v" APP_VERSION ")"
global PROJECT_URL := "https://github.com/KaylumSnape/keyboard-layout-manager"
global APP_ICON_FILE := A_ScriptDir "\assets\KeyboardLayoutManager.ico"
global CONFIG_FILE := A_ScriptDir "\KeyboardLayoutManager.ini"
global STARTUP_SHORTCUT := A_Startup "\KeyboardLayoutManager.lnk"
global Settings := Map()
global PreferredKeyboardIds := []
global LastAppliedLayout := ""

if FileExist(APP_ICON_FILE)
{
    TraySetIcon(APP_ICON_FILE)
}
A_IconHidden := false
A_IconTip := APP_NAME " v" APP_VERSION

InitializeApplication()

if (DEBUG_MODE)
{
    RegisterDebugHotkeys()
}


; ============================================================================
; Application Setup
; ============================================================================

RegisterDebugHotkeys()
{
    Hotkey("F8", (*) => DebugState())
    Hotkey("F9", (*) => ForceLayout("US"))
    Hotkey("F10", (*) => ForceLayout("UK"))
    Hotkey("F12", (*) => Reload())
}

InitializeApplication()
{
    LoadConfiguration()
    UpdateStartupShortcut()
    CreateTrayMenu()

    ; Device arrival/removal notifications.
    OnMessage(0x0219, WM_DEVICECHANGE)

    ; Session lock/unlock notifications.
    OnMessage(0x02B1, WM_WTSSESSION_CHANGE)

    DllCall(
        "Wtsapi32\WTSRegisterSessionNotification",
        "Ptr", A_ScriptHwnd,
        "UInt", 0
    )

    OnExit(Cleanup)

    ; Perform the initial check after Windows has settled.
    ScheduleCheck(500)
}

CreateTrayMenu()
{
    global APP_MENU_TITLE

    A_TrayMenu.Delete()
    A_TrayMenu.Add(APP_MENU_TITLE, (*) => 0)
    A_TrayMenu.Disable(APP_MENU_TITLE)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Check Now", CheckNow)
    A_TrayMenu.Add("Show Status", ShowStatus)
    A_TrayMenu.Add("Open Configuration File", OpenConfigurationFile)
    A_TrayMenu.Add("View on GitHub", OpenProjectPage)
    A_TrayMenu.Add("Detect Connected Keyboards", ShowConnectedKeyboards)
    A_TrayMenu.Add("Add Connected US Keyboard...", AddPreferredKeyboard)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Enable Notifications", ToggleNotifications)
    A_TrayMenu.Add("Run At Startup", ToggleRunAtStartup)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload", (*) => Reload())
    A_TrayMenu.Add("Exit", (*) => ExitApp())

    UpdateTrayMenuChecks()
}

UpdateTrayMenuChecks()
{
    global Settings

    SetTrayMenuCheck("Enable Notifications", Settings["ShowNotifications"])
    SetTrayMenuCheck("Run At Startup", Settings["RunAtStartup"])
}

SetTrayMenuCheck(itemName, isChecked)
{
    if (isChecked)
    {
        A_TrayMenu.Check(itemName)
    }
    else
    {
        A_TrayMenu.Uncheck(itemName)
    }
}


; ============================================================================
; Configuration
; ============================================================================

LoadConfiguration()
{
    global Settings
    global PreferredKeyboardIds

    EnsureConfigurationFile()

    Settings := Map(
        "ShowNotifications", ReadBooleanSetting("General", "ShowNotifications", false),
        "NotificationDurationMs", ReadIntegerSetting("General", "NotificationDurationMs", 3000),
        "LayoutSwitchRetryDelayMs", Max(50, ReadIntegerSetting("General", "LayoutSwitchRetryDelayMs", 250)),
        "LayoutSwitchMaxAttempts", Max(1, ReadIntegerSetting("General", "LayoutSwitchMaxAttempts", 3)),
        "RunAtStartup", ReadBooleanSetting("General", "RunAtStartup", true),
        "DefaultLayout", ReadLayoutSetting("Layouts", "DefaultLayout", "UK"),
        "PreferredLayout", ReadLayoutSetting("Layouts", "PreferredLayout", "US")
    )

    PreferredKeyboardIds := LoadPreferredKeyboardIds()
}

EnsureConfigurationFile()
{
    global APP_NAME
    global APP_VERSION
    global CONFIG_FILE

    if FileExist(CONFIG_FILE)
    {
        return
    }

    defaultConfiguration := "; " APP_NAME " v" APP_VERSION " configuration.`n"
        . "; Select Reload from the system tray after editing this file.`n"
        . ";`n"
        . "; Tray actions:`n"
        . "; Check Now: apply the layout for currently connected keyboards.`n"
        . "; Show Status: show layout, detection, and configuration details.`n"
        . "; Open Configuration File: open this file in the default text editor.`n"
        . "; Detect Connected Keyboards: list USB keyboard details.`n"
        . "; Add Connected US Keyboard: identify a keyboard by unplugging and reconnecting it.`n"
        . "; Enable Notifications and Run At Startup: toggle and save those settings.`n"
        . "; Reload: reload this file. Exit: close Keyboard Layout Manager.`n`n"
        . "[General]`n"
        . "; Show a tray notification after the script applies a layout.`n"
        . "ShowNotifications=false`n"
        . "; Notification display time in milliseconds.`n"
        . "NotificationDurationMs=3000`n"
        . "; Wait after each Win+Space attempt. Increase to 500 if switching is unreliable.`n"
        . "LayoutSwitchRetryDelayMs=250`n"
        . "; Number of layout-switch attempts. Three is normally sufficient.`n"
        . "LayoutSwitchMaxAttempts=3`n"
        . "; Create or remove the Startup-folder shortcut automatically.`n"
        . "RunAtStartup=true`n`n"
        . "[Layouts]`n"
        . "; Layout used when no preferred keyboard is connected.`n"
        . "DefaultLayout=UK`n"
        . "; Layout used when a preferred keyboard is connected.`n"
        . "PreferredLayout=US`n`n"
        . "[PreferredUSKeyboards]`n"
        . "; One VID/PID per entry. Use Add Connected US Keyboard in the tray to add one.`n"
        . "; Keyboard1=VID_045E&PID_00DB`n"

    FileAppend(defaultConfiguration, CONFIG_FILE, "UTF-8-RAW")
}

ReadBooleanSetting(section, key, defaultValue)
{
    global CONFIG_FILE

    value := Trim(IniRead(CONFIG_FILE, section, key, defaultValue ? "true" : "false"))
    return StrLower(value) = "true" || value = "1" || StrLower(value) = "yes"
}

ReadIntegerSetting(section, key, defaultValue)
{
    global CONFIG_FILE

    value := Trim(IniRead(CONFIG_FILE, section, key, defaultValue))
    return value ~= "^\d+$" ? Integer(value) : defaultValue
}

ReadLayoutSetting(section, key, defaultValue)
{
    global CONFIG_FILE

    value := StrUpper(Trim(IniRead(CONFIG_FILE, section, key, defaultValue)))
    return value = "US" || value = "UK" ? value : defaultValue
}

LoadPreferredKeyboardIds()
{
    global CONFIG_FILE

    keyboardIds := []
    sectionContents := IniRead(CONFIG_FILE, "PreferredUSKeyboards")

    Loop Parse, sectionContents, "`n", "`r"
    {
        separatorPosition := InStr(A_LoopField, "=")
        if (!separatorPosition)
        {
            continue
        }

        keyboardId := Trim(SubStr(A_LoopField, separatorPosition + 1))
        if (keyboardId != "")
        {
            keyboardIds.Push(keyboardId)
        }
    }

    return keyboardIds
}

WriteBooleanSetting(section, key, value)
{
    global CONFIG_FILE

    IniWrite(value ? "true" : "false", CONFIG_FILE, section, key)
}

AddPreferredKeyboardId(keyboardId)
{
    global CONFIG_FILE
    global PreferredKeyboardIds

    for existingKeyboardId in PreferredKeyboardIds
    {
        if (existingKeyboardId = keyboardId)
        {
            return false
        }
    }

    index := 1
    Loop
    {
        key := "Keyboard" index
        if (IniRead(CONFIG_FILE, "PreferredUSKeyboards", key, "") = "")
        {
            break
        }

        index += 1
    }

    IniWrite(keyboardId, CONFIG_FILE, "PreferredUSKeyboards", key)
    PreferredKeyboardIds.Push(keyboardId)
    return true
}


; ============================================================================
; Tray Actions
; ============================================================================

CheckNow(*)
{
    CheckKeyboard()
}

ShowStatus(*)
{
    global APP_NAME
    global CONFIG_FILE
    global LastAppliedLayout

    MsgBox(
        "Current Layout: " CurrentLayoutName()
        "`nPreferred US Keyboard Connected: "
        (IsPreferredUSKeyboardConnected() ? "Yes" : "No")
        "`nLast Applied Layout: " (LastAppliedLayout = "" ? "Not yet applied" : LastAppliedLayout)
        "`nConfiguration File: " CONFIG_FILE,
        APP_NAME
    )
}

OpenConfigurationFile(*)
{
    global CONFIG_FILE

    Run(CONFIG_FILE)
}

OpenProjectPage(*)
{
    global PROJECT_URL

    Run(PROJECT_URL)
}

ShowConnectedKeyboards(*)
{
    global APP_NAME

    keyboards := GetUsbKeyboardCandidates()
    message := "Connected keyboards with a usable VID/PID:`n`n"

    for keyboard in keyboards
    {
        message .= keyboard.FriendlyName "`n"
        if (keyboard.Manufacturer != "")
        {
            message .= "   Manufacturer: " keyboard.Manufacturer "`n"
        }
        message .= "   VID/PID: " keyboard.Id "`n`n"
    }

    if (!keyboards.Length)
    {
        message := "No connected USB keyboard devices with a VID/PID were found."
    }

    MsgBox(RTrim(message, "`n"), APP_NAME)
}

AddPreferredKeyboard(*)
{
    global APP_NAME

    while true
    {
        result := MsgBox(
            "Unplug the US keyboard, then click OK to record the current keyboards.",
            APP_NAME,
            "OKCancel Iconi"
        )
        if (result != "OK")
        {
            return
        }

        baselineKeyboards := GetUsbKeyboardCandidates()

        result := MsgBox(
            "Plug in the US keyboard and wait until Windows finishes connecting it, then click OK.",
            APP_NAME,
            "OKCancel Iconi"
        )
        if (result != "OK")
        {
            return
        }

        newKeyboards := GetNewKeyboardCandidates(baselineKeyboards)
        if (newKeyboards.Length)
        {
            break
        }

        result := MsgBox(
            "No newly connected keyboard was detected. Ensure the keyboard is connected, then try again.",
            APP_NAME,
            "RetryCancel Icon!"
        )
        if (result != "Retry")
        {
            return
        }
    }

    selectedKeyboard := SelectKeyboardCandidate(newKeyboards)
    if !IsObject(selectedKeyboard)
    {
        return
    }

    details := selectedKeyboard.FriendlyName
    if (selectedKeyboard.Manufacturer != "")
    {
        details .= "`nManufacturer: " selectedKeyboard.Manufacturer
    }
    details .= "`nVID/PID: " selectedKeyboard.Id

    confirmation := MsgBox(
        "Newly connected keyboard detected:`n`n"
        details "`n`nUse this keyboard for the US layout?",
        APP_NAME,
        "YesNo Icon?"
    )

    if (confirmation != "Yes")
    {
        return
    }

    if AddPreferredKeyboardId(selectedKeyboard.Id)
    {
        CheckKeyboard()
        MsgBox("Added " selectedKeyboard.Id " to KeyboardLayoutManager.ini.", APP_NAME)
    }
    else
        MsgBox("This keyboard is already configured for the US layout.", APP_NAME)
}

SelectKeyboardCandidate(keyboards)
{
    global APP_NAME

    if (keyboards.Length = 1)
    {
        return keyboards[1]
    }

    prompt := "More than one new keyboard was detected. Select the US keyboard:`n`n"
    for keyboard in keyboards
    {
        prompt .= A_Index ". " keyboard.FriendlyName "`n"
        if (keyboard.Manufacturer != "")
        {
            prompt .= "   " keyboard.Manufacturer "`n"
        }
        prompt .= "   " keyboard.Id "`n`n"
    }

    result := InputBox(prompt "Enter the number to add:", APP_NAME)
    if (result.Result != "OK")
    {
        return ""
    }

    selection := Trim(result.Value)
    if !(selection ~= "^\d+$") || selection < 1 || selection > keyboards.Length
    {
        MsgBox("Enter a number from 1 to " keyboards.Length ".", APP_NAME, "Icon!")
        return ""
    }

    return keyboards[Integer(selection)]
}

GetNewKeyboardCandidates(baselineKeyboards)
{
    baselineIds := Map()
    for keyboard in baselineKeyboards
    {
        baselineIds[keyboard.Id] := true
    }

    newKeyboards := []
    for keyboard in GetUsbKeyboardCandidates()
    {
        if !baselineIds.Has(keyboard.Id)
        {
            newKeyboards.Push(keyboard)
        }
    }

    return newKeyboards
}

ToggleNotifications(*)
{
    global Settings

    Settings["ShowNotifications"] := !Settings["ShowNotifications"]
    WriteBooleanSetting("General", "ShowNotifications", Settings["ShowNotifications"])
    UpdateTrayMenuChecks()
}

ToggleRunAtStartup(*)
{
    global Settings

    Settings["RunAtStartup"] := !Settings["RunAtStartup"]
    WriteBooleanSetting("General", "RunAtStartup", Settings["RunAtStartup"])
    UpdateStartupShortcut()
    UpdateTrayMenuChecks()
}


; ============================================================================
; Startup Shortcut
; ============================================================================

UpdateStartupShortcut()
{
    global Settings
    global STARTUP_SHORTCUT

    if (Settings["RunAtStartup"])
    {
        shell := ComObject("WScript.Shell")
        shortcut := shell.CreateShortcut(STARTUP_SHORTCUT)
        shortcut.TargetPath := A_ScriptFullPath
        shortcut.WorkingDirectory := A_ScriptDir
        shortcut.Description := "Keyboard Layout Manager"
        shortcut.Save()
    }
    else if FileExist(STARTUP_SHORTCUT)
    {
        FileDelete(STARTUP_SHORTCUT)
    }
}


; ============================================================================
; Windows Event Handlers
; ============================================================================

WM_DEVICECHANGE(wParam, lParam, msg, hwnd)
{
    static DBT_DEVNODES_CHANGED := 0x0007
    static DBT_CONFIGCHANGED := 0x0018
    static DBT_DEVICEARRIVAL := 0x8000
    static DBT_DEVICEREMOVECOMPLETE := 0x8004

    if (
        wParam = DBT_DEVNODES_CHANGED
        || wParam = DBT_CONFIGCHANGED
        || wParam = DBT_DEVICEARRIVAL
        || wParam = DBT_DEVICEREMOVECOMPLETE
    )
    {
        ; Allow Windows time to enumerate or remove hardware.
        ScheduleCheck(750)
    }
}

WM_WTSSESSION_CHANGE(wParam, lParam, msg, hwnd)
{
    static WTS_SESSION_LOGON := 0x5
    static WTS_SESSION_UNLOCK := 0x8

    if (wParam = WTS_SESSION_LOGON || wParam = WTS_SESSION_UNLOCK)
    {
        ; Windows may reset layouts after unlock.
        ScheduleCheck(1000)
    }
}


; ============================================================================
; Layout Selection
; ============================================================================

ScheduleCheck(delayMs := 750)
{
    SetTimer(CheckKeyboard, 0)
    SetTimer(CheckKeyboard, -delayMs)
}

CheckKeyboard()
{
    global APP_NAME
    global LastAppliedLayout
    global Settings

    targetLayout := IsPreferredUSKeyboardConnected()
        ? Settings["PreferredLayout"]
        : Settings["DefaultLayout"]
    currentLayout := CurrentLayoutName()

    if (targetLayout != LastAppliedLayout || currentLayout != targetLayout)
    {
        EnsureLayout(targetLayout)
        LastAppliedLayout := targetLayout

        if (Settings["ShowNotifications"])
        {
            TrayTip(APP_NAME, "Layout set to: " targetLayout, 1)
            SetTimer(() => TrayTip(), -Settings["NotificationDurationMs"])
        }
    }
}

ForceLayout(targetLayout)
{
    global LastAppliedLayout

    if EnsureLayout(targetLayout)
    {
        LastAppliedLayout := targetLayout
    }
}

EnsureLayout(targetLayout)
{
    global LANG_US
    global LANG_UK
    global Settings

    targetLangId := targetLayout = "US" ? LANG_US : LANG_UK

    ; Win+Space is the switching mechanism proven reliable on this machine.
    ; Retry settings are configurable for systems that apply layouts slowly.
    Loop Settings["LayoutSwitchMaxAttempts"]
    {
        if (GetActiveLangId() = targetLangId)
        {
            return true
        }

        SendEvent("# ")
        Sleep(Settings["LayoutSwitchRetryDelayMs"])
    }

    return false
}


; ============================================================================
; Keyboard Detection
; ============================================================================

IsPreferredUSKeyboardConnected()
{
    global PreferredKeyboardIds

    if (PreferredKeyboardIds.Length = 0)
    {
        return false
    }

    for keyboard in GetConnectedKeyboards(false)
    {
        for keyboardId in PreferredKeyboardIds
        {
            if InStr(keyboard.DeviceId, keyboardId, false)
            {
                return true
            }
        }
    }

    return false
}

GetConnectedKeyboards(includeDisplayDetails := true)
{
    keyboards := []
    wmi := ComObjGet("winmgmts:\\.\root\CIMV2")
    query := includeDisplayDetails
        ? "SELECT DeviceID,Manufacturer,Name,Status FROM Win32_PnPEntity WHERE PNPClass='Keyboard'"
        : "SELECT DeviceID,Status FROM Win32_PnPEntity WHERE PNPClass='Keyboard'"
    devices := wmi.ExecQuery(query)

    for device in devices
    {
        if (device.Status = "OK")
        {
            keyboard := { DeviceId: device.DeviceID }

            if (includeDisplayDetails)
            {
                keyboard.FriendlyName := device.Name = "" ? device.DeviceID : device.Name
                keyboard.Manufacturer := device.Manufacturer = "" ? "" : device.Manufacturer
            }

            keyboards.Push(keyboard)
        }
    }

    return keyboards
}

GetUsbKeyboardCandidates()
{
    keyboards := []
    knownIds := Map()

    for keyboard in GetConnectedKeyboards()
    {
        keyboardId := GetVidPid(keyboard.DeviceId)
        if (keyboardId = "" || knownIds.Has(keyboardId))
        {
            continue
        }

        knownIds[keyboardId] := true
        keyboards.Push({
            FriendlyName: keyboard.FriendlyName,
            Manufacturer: keyboard.Manufacturer,
            Id: keyboardId
        })
    }

    return keyboards
}

GetVidPid(deviceId)
{
    if RegExMatch(deviceId, "i)VID_[0-9A-F]+&PID_[0-9A-F]+", &match)
    {
        return match[]
    }

    return ""
}


; ============================================================================
; Active Layout Detection and Diagnostics
; ============================================================================

CurrentLayoutName()
{
    global LANG_US
    global LANG_UK

    langId := GetActiveLangId()

    if (langId = LANG_US)
    {
        return "US"
    }
    if (langId = LANG_UK)
    {
        return "UK"
    }

    return "Unknown (" Format("0x{:04X}", langId) ")"
}

GetActiveLangId()
{
    hwnd := DllCall("GetForegroundWindow", "Ptr")

    if (hwnd)
    {
        pid := 0
        threadId := DllCall(
            "GetWindowThreadProcessId",
            "Ptr", hwnd,
            "UInt*", &pid,
            "UInt"
        )

        if (threadId)
        {
            hkl := DllCall("GetKeyboardLayout", "UInt", threadId, "Ptr")
        }
    }

    ; A tray menu can temporarily leave no foreground application window.
    if (!IsSet(hkl))
    {
        hkl := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")
    }

    return hkl & 0xFFFF
}

DebugState()
{
    global APP_NAME
    global LastAppliedLayout

    MsgBox(
        "US Keyboard Detected: " (IsPreferredUSKeyboardConnected() ? "Yes" : "No")
        "`n`nCurrent Layout: " CurrentLayoutName()
        "`n`nLast Applied Layout: " LastAppliedLayout,
        APP_NAME
    )
}


; ============================================================================
; Cleanup
; ============================================================================

Cleanup(*)
{
    DllCall(
        "Wtsapi32\WTSUnRegisterSessionNotification",
        "Ptr", A_ScriptHwnd
    )
}
