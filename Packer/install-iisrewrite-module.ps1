
$product = $env:product
$destinationPath = "c:\_bits"

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

if ($product -eq "commonforwebandapp") {

    Push-Location
    Set-Location "$destinationPath\commonforwebandapp"
    iisrewritemodule
    Pop-Location
}
else {
    Write-Host "no need to install rewrite module for this product: $product"
}

