
packer {
  required_plugins {
    azure = {
      version = ">= 2.2.1"
      source  = "github.com/hashicorp/azure"
    }
  }
}
source "azure-arm" "baseline-1" {
  azure_tags = {
    dept = "DEVOPS"
    task = "DEVOPS Image Build"
  }
  build_resource_group_name         = "${var.build_resource_group_name}"
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "${var.image_sku}"
  managed_image_name                = "${local.product_managed_image_name}"
  managed_image_resource_group_name = "${var.build_resource_group_name}"
  os_type                           = "Windows"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  vm_size                           = "${var.vm_size }"
  winrm_insecure                    = true
  winrm_timeout                     = "5m"
  winrm_use_ssl                     = true
  winrm_username                    = "packer"
}

build {
  sources = ["source.azure-arm.baseline-1"]

  provisioner "powershell" {
    script = "./choco-git-installer.ps1"
  }

  provisioner "powershell" {
    script = "./base-installers.ps1"
    environment_vars = [
      "key=${var.storageaccountkey}",
      "product=${var.product}"
    ]
  }
  
  provisioner "powershell" {
    inline = [
      "Install-WindowsFeature -Name Web-Server, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Http-Redirect, Web-Health, Web-Http-Logging, Web-Custom-Logging, Web-Log-Libraries, Web-ODBC-Logging, Web-Performance, Web-Stat-Compression, Web-Dyn-Compression, Web-Security, Web-Filtering, Web-Basic-Auth, Web-IP-Security, Web-Url-Auth, Web-Windows-Auth, Web-App-Dev, Web-Net-Ext, Web-Asp, Web-Asp-Net, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Service, Web-Scripting-Tools, Web-Net-Ext45, Web-Asp-Net45"
    ]
  }

  provisioner "powershell" {
   script = "./me-agent-depersonalize.ps1"
  }

  provisioner "file" {
  source      = "./set-uk-culture.ps1"
  destination = "C:\\_bits\\set-uk-culture.ps1"
}  
  
provisioner "file" {
  source      = "./install-language.ps1"
  destination = "C:\\_bits\\install-language.ps1"
}

  
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
  inline = [
    "Write-Host 'Resuming provisioning after restart...'",
    "Start-Sleep -Seconds 60",
    "Write-Host 'System is fully online, proceeding...'"
  ]
  }

  provisioner "powershell" {
    script = "./install-iisrewrite-module.ps1"
    environment_vars = [
      "product=${var.product}"
    ]
  }

    
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
  inline = [
    "Write-Host 'Resuming provisioning after restart...'",
    "Start-Sleep -Seconds 60",
    "Write-Host 'System is fully online, proceeding...'"
  ]
  }



provisioner "powershell" {
  inline = [
    "Write-Host 'Running en-GB language setup script...'",
    "powershell.exe -ExecutionPolicy Bypass -File C:\\_bits\\install-language.ps1"
  ]
}
  
provisioner "windows-restart" {
  restart_timeout = "10m"
}


  provisioner "powershell" {
  inline = [
    "Write-Host 'Resuming provisioning after restart...'",
    "Start-Sleep -Seconds 60",
    "Write-Host 'System is fully online, proceeding...'"
  ]
  }


  provisioner "powershell" {
    inline = [ "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"]
  }
}