# Description: This script sets the DNS suffix for the local machine and disables the Server Manager scheduled task.
# It sets the DNS suffix to "internal.cloudapp.net" and hides power options in the Windows Explorer policies.
# It also disables the Server Manager scheduled task to prevent it from running automatically.

$dnsSuffix = "internal.cloudapp.net"

Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name 'Domain' -Value $dnsSuffix
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name 'NV Domain' -Value $dnsSuffix
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name 'HidePowerOptions' -Value 1
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
# Get-ItemProperty -Path $path -Name 'Domain', 'NV Domain' | Select-Object Domain, 'NV Domain'

# Display the current hostname
# [System.Net.Dns]::GetHostByName(($env:computerName)).HostName



