# ===============================
# install-language.ps1
# Configure en-GB Language and Locale (All Users)
# Fully Packer-safe (no UI logon, no Sysprep)
# ===============================

Start-Transcript -Path "C:\_bits\SetLang-Final.log" -Append

try {
    $LanguageTag = "en-GB"
    $KeyboardHex = "00000809"  # UK keyboard layout
    $cabPath = "C:\_bits\languagepack\en-gb\Microsoft-Windows-Server-Language-Pack_x64_en-gb.cab"
    $ntuserPath = "C:\Users\Default\NTUSER.DAT"
    $defaultUserHive = "HKU\TempDefault"
    $runOnceScript = "C:\_bits\set-uk-culture.ps1"

    Write-Host "==============================="
    Write-Host "Installing en-GB language pack"
    Write-Host "==============================="

    if (Test-Path $cabPath) {
        Write-Host "Installing language pack CAB from $cabPath..."
        DISM /Online /Add-Package /PackagePath:$cabPath
    } else {
        Write-Warning "Language pack CAB not found at $cabPath"
    }

   

    Write-Host "==============================="
    Write-Host "Applying .DEFAULT user registry settings..."
    Write-Host "==============================="

    reg add "HKU\.DEFAULT\Keyboard Layout\Preload" /v 1 /t REG_SZ /d $KeyboardHex /f
    reg add "HKU\.DEFAULT\Control Panel\International" /v Locale /t REG_SZ /d $KeyboardHex /f
    reg add "HKU\.DEFAULT\Control Panel\International" /v LocaleName /t REG_SZ /d $LanguageTag /f
    reg add "HKU\.DEFAULT\Control Panel\International" /v InputLocale /t REG_SZ /d $KeyboardHex /f
    reg add "HKU\.DEFAULT\Control Panel\International" /v TimeZone /t REG_SZ /d "GMT Standard Time" /f


    Write-Host "==============================="
    Write-Host "Applying Default User profile settings via NTUSER.DAT..."
    Write-Host "==============================="

    if (Test-Path $ntuserPath) {
        Write-Host "Loading registry hive from: $ntuserPath"
        reg load $defaultUserHive $ntuserPath | Out-Null

        reg add "$defaultUserHive\Keyboard Layout\Preload" /v 1 /t REG_SZ /d $KeyboardHex /f
        reg add "$defaultUserHive\Control Panel\International" /v Locale /t REG_SZ /d $KeyboardHex /f
        reg add "$defaultUserHive\Control Panel\International" /v LocaleName /t REG_SZ /d $LanguageTag /f
        reg add "$defaultUserHive\Control Panel\International" /v InputLocale /t REG_SZ /d $KeyboardHex /f
        reg add "$defaultUserHive\Control Panel\International" /v TimeZone /t REG_SZ /d "GMT Standard Time" /f


        Write-Host "Injecting RunOnce entry to set per-user display language and culture..."

        $runOnceCommand = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runOnceScript`""
        reg add "$defaultUserHive\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v SetUKCulture /t REG_SZ /d "$runOnceCommand" /f

        reg unload $defaultUserHive | Out-Null
        Write-Host "Default User registry hive updated successfully."
    } else {
        Write-Warning "NTUSER.DAT not found - cannot configure future user defaults."
    }

    
}
catch {
    Write-Error ("An error occurred: {0}" -f $_)
}

# ===============================
# Set UK London Timezone (System-wide)
# ===============================
Write-Host "Setting system timezone to 'GMT Standard Time' (UK London)..."
tzutil.exe /s "GMT Standard Time"

Stop-Transcript
exit 0

