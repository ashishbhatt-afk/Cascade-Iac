<#
.SYNOPSIS
    Depersonalize (pre-image) ManageEngine DesktopCentral (UEMS) Agent on a Windows VM.
.DESCRIPTION
    This script sets the registry value "ImagedComputer"=1 under the appropriate DCAgent key,
    so that when you capture a VM image, each cloned VM will generate a fresh Agent ID
    instead of inheriting the same one.
    
    WARNING: Do NOT use this script for anything other than preparing an image.
             After running, the agent will stop communicating with the server until you
             restore its original communication (e.g., via a post-image VBScript).

    Steps:
      1) Run this script as Administrator on the source ("golden") VM just before shutting it down.
      2) Capture the VM image (the registry entry will mark it as "imaged").
      3) On each cloned VM’s first boot, DesktopCentral Agent sees “ImagedComputer”=1 and
         generates a new GUID/Config. It then registers as a brand-new machine.

.NOTES
    • Tested on PowerShell 5.1 and above.
    • Must run as Administrator.
    • If the registry path does not exist, it will be created automatically.
    • This script does not “undo” the change. To restore the original agent behavior on the “golden” VM,
      you must run the complementary “dcagentPostImage.vbs” (or equivalent restore script)  

#>

# --- Begin Script ---
Write-Host "=== Depersonalize UEMS Agent (Pre-Image) ===`n" -ForegroundColor Cyan

# 1) Determine OS Architecture
$arch = $env:PROCESSOR_ARCHITECTURE

if ([string]::IsNullOrEmpty($arch)) {
    # If the environment variable is missing/empty, assume 32-bit and use the ServerInfo subkey
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] PROCESSOR_ARCHITECTURE is not defined. Assuming 32-bit." -ForegroundColor Yellow
    $baseRegKey = "HKLM:\SOFTWARE\AdventNet\DesktopCentral\DCAgent\ServerInfo"
}
else {
    switch ($arch.ToLower()) {
        "x86" {
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] OS Architecture detected: 32-bit." -ForegroundColor Green
            $baseRegKey = "HKLM:\SOFTWARE\AdventNet\DesktopCentral\DCAgent"
        }
        default {
            # On 64-bit Windows, $env:PROCESSOR_ARCHITECTURE is typically "AMD64"
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] OS Architecture detected: 64-bit." -ForegroundColor Green
            $baseRegKey = "HKLM:\SOFTWARE\Wow6432Node\AdventNet\DesktopCentral\DCAgent"
        }
    }
}

# 2) Ensure the registry key exists (create if missing)
try {
    if (-not (Test-Path $baseRegKey)) {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Registry path does not exist. Creating: $baseRegKey" -ForegroundColor Yellow
        New-Item -Path $baseRegKey -Force | Out-Null
    }
    else {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Found registry path: $baseRegKey" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERROR: Could not create or verify registry path: $baseRegKey" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# 3) Write “ImagedComputer” = 1 as a DWORD under that key
$propertyName  = "ImagedComputer"
$propertyValue = 1
try {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Writing DWORD value: `$propertyName` = $propertyValue ..." -NoNewline
    New-ItemProperty -Path $baseRegKey `
                     -Name $propertyName `
                     -Value $propertyValue `
                     -PropertyType DWord `
                     -Force | Out-Null

    Write-Host "  [OK]" -ForegroundColor Green
}
catch {
    Write-Host "`nERROR: Failed to write `$propertyName` in $baseRegKey." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# 4) Final message
Write-Host "`n=== Depersonalization complete. ===" -ForegroundColor Cyan
Write-Host "• The agent will not communicate with the server until you run the Post-Image restore script." -ForegroundColor Yellow
Write-Host "• Now shut down this VM and capture your image." -ForegroundColor Yellow
# --- End Script ---
