[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor `
                                               [Net.SecurityProtocolType]::Tls11 -bor `
                                               [Net.SecurityProtocolType]::Tls

Write-Host "fsutil..."
fsutil behavior set disable8dot3 1
Write-Host "done fsutil..."

Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force

if ( !(Get-Module -ListAvailable -Name Powershell-yaml)) {
    Write-Host "Module does not exist"
    Install-Module powershell-yaml -Force
    Get-Module -ListAvailable -Name Powershell-yaml
}
Import-Module powershell-yaml

######################### Start of functions to install each tool
function dotnethosting8 {
    Push-Location
    Set-Location dotnethosting8
    Write-Host "Location under dotnethosting8 function is $(Get-Location)"										 
    $installer = Get-ChildItem -Path "." -Filter "dotnet-hosting-*-win.exe" | Select-Object -First 1
    if ($installer) {
        $process = Start-Process -Wait -PassThru -FilePath $installer.FullName -ArgumentList "/quiet /norestart /accepteula"
        Write-Host "dotnet hosting bundle installation in progress...."
        if ($process.ExitCode -ne 0) { throw "dotnet hosting bundle 8 failed with exit code $($process.ExitCode)" }
    } else {
        Write-Host "Installer not found."
    }
    Pop-Location    
}

function dotnethosting6 {
    Push-Location
    Set-Location dotnethosting6
    Write-Host "Location under dotnethosting6 function is $(Get-Location)"														 
    $installer = Get-ChildItem -Path "." -Filter "dotnet-hosting-*-win.exe" | Select-Object -First 1
    if ($installer) {
        $process = Start-Process -Wait -PassThru -FilePath $installer.FullName -ArgumentList "/quiet /norestart /accepteula"
        Write-Host "dotnet hosting bundle installation in progress...."
        if ($process.ExitCode -ne 0) { throw "dotnet hosting bundle 6 failed with exit code $($process.ExitCode)" }
    } else {
        Write-Host "Installer not found."
    }
    Pop-Location  
}

function NDP {
    Push-Location
    Set-Location NDP
    Write-Host "Location under NDP function is $(Get-Location)"
    $installer = Get-ChildItem -Path "." -Filter "NDP*.exe" | Select-Object -First 1
    if ($installer) {
        Write-Host "installer found: $($installer.FullName)"
        Write-Host "Starting NDP installation..."
        $process = Start-Process -Wait -PassThru -FilePath $installer.FullName -ArgumentList "/quiet /norestart /accepteula"
        if ($process.ExitCode -eq 3010) {
            Write-Host "NDP installation succeeded but requires restart (exit code 3010)."
        } elseif ($process.ExitCode -ne 0) {
            throw "NDP installation failed with exit code $($process.ExitCode)"
        }
    } else {
        Write-Host "NDP installer not found."
    }
    Pop-Location
}

function iisrewritemodule {
    Push-Location
    Set-Location iisrewritemodule
    Write-Host "Location under iisrewritemodule function is $(Get-Location)"
    $installer = Get-ChildItem -Path "." -Filter "rewrite_*.msi" | Select-Object -First 1
    if ($installer) {
        $process = Start-Process -Wait -PassThru -FilePath msiexec.exe -ArgumentList "/i $($installer.FullName) /qn /norestart"
        Write-Host "IIS rewrite module installation in progress...."
        if ($process.ExitCode -ne 0) { throw "IIS rewrite module installation failed with exit code $($process.ExitCode)" }
    } else {
        Write-Host "IIS rewrite module installer not found."
    }
    Pop-Location
}

function rdsserver {
    Push-Location
    Write-Host "Location under rdsserver function is $(Get-Location)"																															   								   
    Set-Location SSMS
    $installer = Get-ChildItem -Path "." -Filter "SSMS*.exe" | Select-Object -First 1  
    if ($installer) {
        $process = Start-Process -Wait -PassThru -FilePath $installer.FullName -ArgumentList "/quiet /norestart"
        Write-Host "SSMS installation in progress...."
        if ($process.ExitCode -ne 0) { throw "SSMS installation failed with exit code $($process.ExitCode)" }
    } else {
        Write-Host "SSMS installer not found."
    }
    Pop-Location
}

function ManageEngine {
    Push-Location
    Set-Location ManageEngine
    Write-Host "Location under ManageEngine function is $(Get-Location)"										 
    $installer = Get-ChildItem -Path "." -Filter "ME*.exe" | Select-Object -First 1
    if ($installer) {
        $process = Start-Process -Wait -PassThru -FilePath $installer.FullName -ArgumentList "/silent /norestart" 
        Write-Host "ManageEngine agent installation in progress...."
        if ($process.ExitCode -ne 0) { throw "ManageEngine agent install failed with exit code $($process.ExitCode)" }
    } else {
        Write-Host "Installer not found."
    }
    Pop-Location    
}

Get-ChildItem Env:
$product = $env:product
$key = $env:key
$storageaccount = "----------" #enter your storage aacount name here
$container = "---------" #enter your storage container name here
$destinationPath = "c:\_bits"

# Ensure destination directory exists
if (!(Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

az storage blob download-batch -d $destinationPath -s $container --account-name $storageaccount --account-key $key

if ($product -eq "rdsserver") {

    Push-Location
    Set-Location "$destinationPath\rdsserver"
    rdsserver
    Pop-Location
}
elseif ($product -eq "commonforwebandapp") {

    Push-Location
    Set-Location "$destinationPath\commonforwebandapp"
    dotnethosting6
    dotnethosting8
    NDP
    ManageEngine
    Pop-Location
}
else {
    Write-Host "Product not found"
}

