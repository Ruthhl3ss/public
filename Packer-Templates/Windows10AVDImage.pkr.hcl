packer {
  required_plugins {
    windows-update = {
      version = "0.12.0"
      source = "github.com/rgl/windows-update"
    }
  }
}

variable "WorkingDirectory" {
  type    = string
  default = ""
}

variable "client_id" {
  type    = string
  default = ""
}

variable "client_secret" {
  type    = string
  default = ""
  sensitive = true
}

variable "location" {
  type    = string
  default = ""
}

variable "managed_image_name" {
  type    = string
  default = "Windows10_${env("Build_BuildNumber")}"
}

variable "managed_image_resource_group_name" {
  type    = string
  default = ""
}

variable "offer" {
  type    = string
  default = "Windows-10"
}

variable "publisher" {
  type    = string
  default = ""
}

variable "sku" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "vm_size" {
  type    = string
  default = ""
}

variable "virtual_network_name" {
  type    = string
  default = ""
}

variable "virtual_network_resource_group_name" {
  type    = string
  default = ""
}

variable "virtual_network_subnet_name" {
  type    = string
  default = ""
}

source "azure-arm" "windowsvm" {
  async_resourcegroup_delete              = true
  client_id                               = var.client_id
  client_secret                           = var.client_secret
  communicator                            = "winrm"
  image_offer                             = var.offer
  image_publisher                         = var.publisher
  image_sku                               = var.sku
  location                                = var.location
  managed_image_name                      = var.managed_image_name
  managed_image_resource_group_name       = var.managed_image_resource_group_name
  os_type                                 = "Windows"
  private_virtual_network_with_public_ip  = "false"
  virtual_network_name                    = var.virtual_network_name
  virtual_network_resource_group_name     = var.virtual_network_resource_group_name
  virtual_network_subnet_name             = var.virtual_network_subnet_name
  subscription_id                         = var.subscription_id
  tenant_id                               = var.tenant_id
  vm_size                                 = var.vm_size
  winrm_insecure                          = "true"
  winrm_timeout                           = "3m"
  winrm_use_ssl                           = "true"
  winrm_username                          = "packer"
}

build {
  sources = ["source.azure-arm.windowsvm"]

  provisioner "windows-update" {
    filters         = ["exclude:$_.Title -like '*Preview*'", "include:$true"]
    search_criteria = "IsInstalled=0"
    update_limit    = 25
  }
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"&amp; {Write-Output 'Machine restarted.'}\""
  }
  provisioner "powershell" {
    inline = ["if( Test-Path $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml -Force}", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; Write-Output $imageState.ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Start-Sleep -s 10 } else { break } }"]
  }
}