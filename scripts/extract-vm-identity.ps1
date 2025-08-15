param (
    [string]$PlanPath,
    [string]$ResultPath
)

Write-Host "Starting: Extract and Publish New VM Info (No object IDs)..."

# Validate plan file
if (-Not (Test-Path $PlanPath)) {
    Write-Error "Terraform plan file not found at: $PlanPath"
    exit 1
}

# Read and parse plan JSON
try {
    $planJson = Get-Content $PlanPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse plan JSON: $_"
    exit 1
}

# Extract VM names that are being created
$newVMNames = @()
foreach ($resChange in $planJson.resource_changes) {
    if ($resChange.type -eq "azurerm_windows_virtual_machine" -and $resChange.change.actions -contains "create") {
        $vmNameFromPlan = $resChange.change.after.name
        if ($vmNameFromPlan) {
            $newVMNames += $vmNameFromPlan
        }
    }
}

if ($newVMNames.Count -eq 0) {
    Write-Warning "No new VMs found in the plan."
    exit 0
}

Write-Host "New VMs in plan: $($newVMNames -join ', ')"

# Discover SQL Managed Instance FQDN from one of the resource groups (user must ensure consistency)

# Discover SQL Managed Instance FQDN from the resource group of the first VM
try {
    $targetRg = $planJson.resource_changes | Where-Object {
        $_.type -eq "azurerm_windows_virtual_machine" -and $_.change.actions -contains "create"
    } | Select-Object -First 1 | ForEach-Object { $_.change.after.resource_group_name }

    if (-not $targetRg) {
        Write-Error "Could not determine target resource group from the Terraform plan."
        exit 1
    }

    $sqlMisInRg = az sql mi list --resource-group $targetRg --query "[].{name:name, fqdn:fullyQualifiedDomainName}" -o json | ConvertFrom-Json
    if (-not $sqlMisInRg -or $sqlMisInRg.Count -eq 0) {
        Write-Error "No SQL Managed Instances found in resource group '$targetRg'."
        exit 1
    }

    $firstMi = $sqlMisInRg[0]
    $privateFqdn = $firstMi.fqdn
    $fqdnParts = $privateFqdn -split '\.'
    if ($fqdnParts.Count -ge 4) {
        $publicFqdn = "$($fqdnParts[0]).public.$($fqdnParts[1]).database.windows.net"
    } else {
        Write-Error "FQDN format unexpected: $privateFqdn"
        exit 1
    }

    Write-Host "Discovered SQL MI in $targetRg"
    Write-Host "Private FQDN: $privateFqdn"
    Write-Host "Public FQDN: $publicFqdn"
    Write-Host "##vso[task.setvariable variable=sqlMiFqdn;isOutput=true]$publicFqdn"
    Write-Host "##vso[task.setvariable variable=sqlMiPrivateFqdn;isOutput=true]$privateFqdn"
    # Extract environment name from resource group name (assuming naming convention like rg-cas-{env}-{region}-{type})
    $environmentName = ""
    if ($targetRg -match "rg-cas-(\w+)-") {
        $environmentName = $matches[1]
    } else {
        # Fallback: try to extract from any part of the resource group name that might indicate environment
        $rgParts = $targetRg -split "-"
        if ($rgParts.Count -ge 3) {
            $environmentName = $rgParts[2]  # Assuming third part is environment
        } else {
            $environmentName = "unknown"
        }
    }
    
    Write-Host "##vso[task.setvariable variable=resourceGroupName;isOutput=true]$targetRg"
    Write-Host "##vso[task.setvariable variable=environmentName;isOutput=true]$environmentName"
} catch {
    Write-Error "Failed to discover SQL MI via Azure CLI: $_"
    exit 1
}

# Prepare result array
$result = @()
foreach ($vmName in $newVMNames) {
    $result += [PSCustomObject]@{
        name           = $vmName
        sql_mi_fqdn    = $publicFqdn
        private_fqdn   = $privateFqdn
    }
}

# Write result file
try {
    $result | ConvertTo-Json -Depth 3 | Out-File -FilePath $ResultPath -Encoding utf8
    Write-Host "VM info written to $ResultPath"
} catch {
    Write-Error "Failed to write result JSON: $_"
    exit 1
}

# Create comma-separated VM list for DACPAC task
$vmList = $newVMNames -join ','
Write-Host "##[section]Processing VMs: $vmList on SQL MI: $privateFqdn"
Write-Host "##vso[task.setvariable variable=vmList;isOutput=true]$vmList"
Write-Host "##vso[task.setvariable variable=sqlMiFqdnForDacpac;isOutput=true]$privateFqdn"

# Final info
Write-Host "Final Pipeline Variables Set:"
Write-Host "SQL MI Public FQDN: $publicFqdn"
Write-Host "SQL MI Private FQDN: $privateFqdn"
Write-Host "Resource Group Name: $targetRg"
Write-Host "Environment Name: $environmentName"
Write-Host "Final DACPAC Variables Set:"
Write-Host "VM List: $vmList"
Write-Host "SQL MI FQDN for DACPAC: $privateFqdn"
