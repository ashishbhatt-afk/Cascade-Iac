# Ensure script runs with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Write-Host "Setting system time zone to 'GMT Standard Time' (UK)..."
Set-TimeZone -Id "GMT Standard Time"

Write-Host "Setting system locale and language to 'en-GB'..."
Set-WinSystemLocale -SystemLocale "en-GB"
Set-WinHomeLocation -GeoId 242
Set-WinUILanguageOverride -Language "en-GB"
Set-WinDefaultInputMethodOverride -InputTip "0409:00000809"

# Set language list and keyboard layout
$LangList = New-WinUserLanguageList -Language "en-GB"
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("0409:00000809")  # English (UK)
Set-WinUserLanguageList $LangList -Force

Write-Host "Setting system-wide date format (dd/MM/yyyy) for new users..."

# Load the Default User Hive
$defaultHive = "C:\Users\Default\NTUSER.DAT"
$tempHive = "HKU\TempDefault"

# Load registry hive if not already mounted
if (-not (Test-Path "Registry::$tempHive")) {
    reg.exe load $tempHive "$defaultHive" > $null 2>&1
}

# Use reg.exe to set values (avoids issues with Set-ItemProperty)
reg.exe ADD "$tempHive\Control Panel\International" /v sShortDate /t REG_SZ /d "dd/MM/yyyy" /f
reg.exe ADD "$tempHive\Control Panel\International" /v sDate /t REG_SZ /d "/" /f
reg.exe ADD "$tempHive\Control Panel\International" /v LocaleName /t REG_SZ /d "en-GB" /f

# Unload hive safely
reg.exe unload $tempHive > $null 2>&1

Write-Host "System-wide locale and time configuration complete (UK)."
