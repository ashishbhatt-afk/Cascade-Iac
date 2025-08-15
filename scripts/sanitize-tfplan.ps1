# This script sanitizes a Terraform plan JSON file by masking sensitive information because terraform plan files may contain sensitive data such as admin passwords which 
# are not masked by default. This script will mask the admin_password key in the JSON file and copy it to a specified tfgraph file.

param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFile,
    [Parameter(Mandatory = $true)]
    [string]$TfgraphFile
)

$sanitizedFile = [System.IO.Path]::ChangeExtension($JsonFile, "_sanitized.json")

if (Test-Path $JsonFile) {
    Write-Host "Sanitizing $JsonFile..."

    # Read JSON content as text
    $content = Get-Content -Path $JsonFile -Raw

    # Regex pattern to match any key named admin_password and mask its value
    # Matches both: "admin_password": "value" and "admin_password": { "value": "value" }
    $pattern1 = '("admin_password"\s*:\s*)"[^"]*"'
    $pattern2 = '("admin_password"\s*:\s*{\s*"value"\s*:\s*")[^"]*(")'

    # Apply masking
    $masked = $content -replace $pattern1, '$1"***MASKED***"' `
                       -replace $pattern2, '$1***MASKED***$2'

    # Save the masked content
    $masked | Set-Content -Path $sanitizedFile

    # Overwrite the original file
    Move-Item -Force -Path $sanitizedFile -Destination $JsonFile

    # Copy to tfgraph file
    Copy-Item -Force -Path $JsonFile -Destination $TfgraphFile
}
else {
    Write-Host "Terraform plan JSON not found. Skipping sanitization."
}