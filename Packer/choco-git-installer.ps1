$ErrorActionPreference = "Stop"

try {
    # Install Chocolatey
    iex ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    if (-not $?) { throw "Chocolatey installation failed" }

    # Install Git
    choco install git -y
    if ($LASTEXITCODE -ne 0) { throw "Git installation failed with exit code $LASTEXITCODE" }
    
    Write-Host "Git installation completed successfully."
    Write-Host "Starting Azure CLI installation..."
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -ArgumentList "/i AzureCLI.msi /quiet" -Wait
    if ($LASTEXITCODE -ne 0) { throw "Azure CLI installation failed with exit code $LASTEXITCODE" }
    Write-Host "Azure CLI installation completed successfully."
}
catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}
