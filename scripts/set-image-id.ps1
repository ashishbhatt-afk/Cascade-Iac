# This script reads an image ID from a file and sets it as a variable in Azure DevOps.
param (
  [string]$FilePath
)

$imageId = Get-Content $FilePath -Raw
Write-Host "##vso[task.setvariable variable=IMAGE_ID]$imageId"
