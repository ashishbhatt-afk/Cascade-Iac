param (
    [Parameter(Mandatory = $true)]
    [string] $SourcePath,

    [Parameter()]
    [string] $TargetPath = $SourcePath,

    [Parameter(Mandatory = $true)]
    [string] $Transformations,

    [Parameter()]
    [bool] $WriteChanges = $true
)

$FormatEnumerationLimit = -1
$TargetPath = [string]::IsNullOrEmpty($TargetPath) ? $SourcePath : $TargetPath

[ordered]@{
    "Source Path"  = $SourcePath
    "Target Path"  = $TargetPath
    "WriteChanges" = $WriteChanges
} | Format-Table -HideTableHeaders

function GetValue($object, [string[]]$keys) {
    $propertyName = $keys[0]
    if ($keys.count.Equals(1)) {
        return $object.$propertyName
    }
    else { 
        return GetValue -object $object.$propertyName -key ($keys | Select-Object -Skip 1)
    }
}

function SetValue($object, [string[]]$keys, $value) {
    $propertyName = $keys[0]
    if ($keys.count.Equals(1)) {
        $object.$propertyName = $value
    }
    else { 
        SetValue -object $object.$propertyName -key ($keys | Select-Object -Skip 1) -value $value
    }
}

$transJson = $Transformations | ConvertFrom-Json -AsHashtable
$jsonData = Get-Content -Path $sourcePath -Raw | ConvertFrom-Json

$jsonChanges = @()

foreach ($trans in $transJson.GetEnumerator()) {
    $transName = $($trans.name)
    $transNameSplit = $transName.Split(".")

    # convert pipeline bool strings to boolean
    if ($trans.value -eq "True") {
        $transValue = $true
    }
    elseif ($trans.value -eq "False") {
        $transValue = $false
    }
    else {
        $transValue = $trans.value
    }

    $Row = "" | Select-Object Name, 'Old Value', 'New Value', 'New Type'
    $Row.Name = $transName
    $Row.'Old Value' = GetValue $jsonData -key $transName.Split(".")
    $Row.'New Value' = $transValue
    $Row.'New Type' = $transValue.GetType().Name
    $jsonChanges += $Row

    SetValue $jsonData -key $transNameSplit -value $transValue
}

$jsonChanges | Format-Table -AutoSize | Out-Host

if ($WriteChanges) {
    $jsonData | ConvertTo-Json -Depth 100 | Set-Content -Path $TargetPath -Force
}