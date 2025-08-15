# this script counts the number of existing VMs and SQL Managed Instances in Azure based on specified prefixes and environments.
# It also calculates the number of new servers to deploy based on user input and existing counts.
# it currently uses hardcoded prefixes for VM names and resource groups, but these can be adjusted as needed.
# The script outputs a summary of existing VMs and SQL Managed Instances, as well as the calculated deployment counts for new servers.
# It also sets pipeline output variables for use in subsequent tasks.


param(
    [Parameter()]
    [string]
    $subscriptionId = "35217a63-b412-434b-862a-4ea348a188e4",

    [Parameter()]
    [array]
    $VMPrefixes = @("D5CASWINWEB", "S5CASWINWEB", "P5CASWINWEB", 
                    "D5CASWINSQL", "S5CASWINSQL", "P5CASWINSQL",
                    "D5CASWINRBQ", "S5CASWINRBQ", "P5CASWINRBQ",
                    "D5CASWINAPP", "S5CASWINAPP", "P5CASWINAPP"),


    [Parameter()]
    [string]
    $environment = "dev", # dev, staging, prod

    [Parameter()]
    [int]
    $webserversToDeploy = 0,

    [Parameter()]
    [int]
    $sqlserversToDeploy = 0,

    [Parameter()]
    [int]
    $appserversToDeploy = 0,

    [Parameter()]
    [int]
    $rbqToDeploy = 0,

    [Parameter()]
    [int]
    $sqlmiToDeploy = 0
)

# Define resource groups
$resourceGroups = @("rg-cas-dev-uks-core", "rg-cas-staging-uks-core", "rg-cas-prod-uks-core")

# Create a summary table
$summaryTable = [ordered]@{
    "Subscription ID" = $subscriptionId
    "Environment"     = $environment
    "Number of New Webservers to Deploy" = $webserversToDeploy
    "Number of New SQL Servers to Deploy" = $sqlserversToDeploy
    "Number of New App Servers to Deploy" = $appserversToDeploy
    "Number of New SQL Managed Instances to Deploy" = $sqlmiToDeploy
    "NNumber of New RabbitMQ to Deploy" = $rbqToDeploy
    "Resource Groups"  = $resourceGroups -join ", "
    "VM Prefixes"       = $VMPrefixes -join ", "
}
$summaryTable | Format-Table -HideTableHeaders

# Initialize counts with predefined keys for consistency
$counts = @{
    Existing_Dev_WebServerCount    = 0
    Existing_Dev_SQLServerCount    = 0
    Existing_Dev_AppServerCount    = 0
    Existing_Dev_SQLManagedInstanceCount = 0
    Existing_Dev_RBQCount = 0

    Existing_Staging_WebServerCount = 0
    Existing_Staging_SQLServerCount = 0
    Existing_Staging_AppServerCount = 0
    Existing_Staging_SQLManagedInstanceCount = 0
    Existing_Staging_RBQCount = 0

    Existing_Prod_WebServerCount    = 0
    Existing_Prod_SQLServerCount    = 0
    Existing_Prod_AppServerCount    = 0
    Existing_Prod_SQLManagedInstanceCount = 0
    Existing_Prod_RBQCount = 0 
}

# Retrieve VM data from all resource groups
$vms = @()
foreach ($rg in $resourceGroups) {
    $vms += az vm list -g $rg --output json | ConvertFrom-Json
}

# Display the VMs in a table format
$vms | ForEach-Object {
    [PSCustomObject]@{
        Name           = $_.name
        Location       = $_.location
        OS             = $_.storageProfile.osDisk.osType
        ResourceGroup  = $_.resourceGroup
    }
} | Format-Table -AutoSize

# Process VMs and count based on prefixes
foreach ($vm in $vms) {
    $vmName = $vm.Name

    # Match the VM to one of the prefixes
    foreach ($prefix in $VMPrefixes) {
        if ($vmName -like "$prefix*") {
            # Determine environment and type
            $env = if ($prefix.StartsWith("D")) { "Existing_Dev_" }
                   elseif ($prefix.StartsWith("S")) { "Existing_Staging_" }
                   elseif ($prefix.StartsWith("P")) { "Existing_Prod_" }

            $type = if ($prefix -match "WEB") { "WebServerCount" }
                    elseif ($prefix -match "SQL") { "SQLServerCount" }
                    elseif ($prefix -match "APP") { "AppServerCount" }
                    elseif ($prefix -match "RBQ") { "RBQCount" }

            # Increment the count
            $key = "$env$type"
            $counts[$key]++
        }
    }
}

$sqlmi = @()

foreach ($rg in $resourceGroups) {
    $sqlmi += az sql mi list -g $rg --output json | ConvertFrom-Json
}

# Process SQL Managed Instances and count based on prefixes

foreach ($mi in $sqlmi) {
    $miName = $mi.Name

    # Match the MI to one of the prefixes
    foreach ($prefix in $VMPrefixes) {
        if ($miName -like "$prefix*") {
            # Determine environment and type
            $env = if ($prefix.StartsWith("d")) { "Existing_Dev_" }
                   elseif ($prefix.StartsWith("s")) { "Existing_Staging_" }
                   elseif ($prefix.StartsWith("p")) { "Existing_Prod_" }

            $type = "SQLManagedInstanceCount"

            # Increment the count
            $key = "$env$type"
            $counts[$key]++
        }
    }
}



# Output the counts
Write-Output "Summary of VMs and MI by Type and Environment:"
$counts.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Output "$($_.Key): $($_.Value)"
}

# Calculate new server deployment counts based on environment
$newWebServersToDeploy = $webserversToDeploy
$newSQLServersToDeploy = $sqlserversToDeploy
$newAppServersToDeploy = $appserversToDeploy
$newSQLMIToDeploy = $sqlmiToDeploy
$newRBQToDeploy = $rbqToDeploy

switch ($environment.ToLower()) {
    "dev" {
        $newWebServersToDeploy += $counts["Existing_Dev_WebServerCount"]
        $newSQLServersToDeploy += $counts["Existing_Dev_SQLServerCount"]
        $newAppServersToDeploy += $counts["Existing_Dev_AppServerCount"]
        $newSQLMIToDeploy += $counts["Existing_Dev_SQLManagedInstanceCount"]
        $newRBQToDeploy += $counts["Existing_Dev_RBQCount"]
    }
    "staging" {
        $newWebServersToDeploy += $counts["Existing_Staging_WebServerCount"]
        $newSQLServersToDeploy += $counts["Existing_Staging_SQLServerCount"]
        $newAppServersToDeploy += $counts["Existing_Staging_AppServerCount"]
        $newSQLMIToDeploy += $counts["Existing_Staging_SQLManagedInstanceCount"]
        $newRBQToDeploy += $counts["Existing_Staging_RBQCount"]
    }
    "prod" {
        $newWebServersToDeploy += $counts["Existing_Prod_WebServerCount"]
        $newSQLServersToDeploy += $counts["Existing_Prod_SQLServerCount"]
        $newAppServersToDeploy += $counts["Existing_Prod_AppServerCount"]
        $newSQLMIToDeploy += $counts["Existing_Prod_SQLManagedInstanceCount"]
        $newRBQToDeploy += $counts["Existing_Prod_RBQCount"]
    }
    default {
        Write-Error "Invalid environment specified: $environment"
        exit 1
    }
}

# Print and set pipeline output variables for the new counts
Write-Output "Calculated Deployment Counts:"
Write-Output "Total Count of Webservers after Deployment would be = $newWebServersToDeploy"
Write-Output "Total Count of SQLServers after Deployment would be = $newSQLServersToDeploy"
Write-Output "Total Count of App Servers after Deployment would be = $newAppServersToDeploy"
Write-Output "Total Count of SQL Managed Instances after Deployment would be = $newSQLMIToDeploy"
Write-Output "Total Count of RabbitMQ after Deployment would be = $newRBQToDeploy"

Write-Host "##vso[task.setvariable variable=NewWebServersToDeploy;isOutput=true]$newWebServersToDeploy"
Write-Host "##vso[task.setvariable variable=NewSQLServersToDeploy;isOutput=true]$newSQLServersToDeploy"
Write-Host "##vso[task.setvariable variable=NewAppServersToDeploy;isOutput=true]$newAppServersToDeploy"
Write-Host "##vso[task.setvariable variable=NewSQLMIsToDeploy;isOutput=true]$newSQLMIToDeploy"
Write-Host "##vso[task.setvariable variable=NewRBQServersToDeploy;isOutput=true]$newRBQToDeploy"
