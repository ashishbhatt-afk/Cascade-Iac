# C:\_bits\set-uk-culture.ps1
Write-Host "Applying UI and culture overrides..."

Set-WinSystemLocale -SystemLocale en-GB
Set-WinUILanguageOverride -Language en-GB
Set-WinUserLanguageList -LanguageList en-GB -Force
Set-Culture en-GB
Set-WinHomeLocation -GeoId 242
Set-TimeZone -Id "GMT Standard Time"  
