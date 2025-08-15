# Description: This script runs 'terraform output -json' to generate a JSON file containing the outputs of a Terraform configuration.

param (
    [string]$WorkingDir,
    [string]$OutputPath
)

Push-Location $WorkingDir

Write-Host "Running 'terraform output -json' to generate outputs file"
terraform output -json | Out-File -FilePath $OutputPath -Encoding utf8

if (-Not (Test-Path $OutputPath)) {
    Write-Error "Terraform output file was not created!"
    exit 1
}

Pop-Location
