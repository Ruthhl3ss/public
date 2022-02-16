[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $TenantId,
    [Parameter()]
    [string]
    $ClientID,
    [Parameter()]
    [string]
    $ClientSecret,
    [Parameter()]
    [string]
    $StorageAccountName,
    [Parameter()]
    [string]
    $RGName,
    [Parameter()]
    [string]
    $ContainerName
)
#Checking for correct modules and installing them if needed
$InstalledModules = Get-InstalledModule
$Module_Name = "IntuneBackupAndRestore"
If ($InstalledModules.name -notcontains $Module_Name) {
	Write-Host "Installing module $Module_Name"
	Install-Module $Module_Name -Force
}
Else {
	Write-Host "$Module_Name Module already installed"
}		

#Importing Module
Write-Host "Importing Module $Module_Name"
Import-Module $Module_Name

#Checking for correct modules and installing them if needed
$InstalledModules = Get-InstalledModule
$Module_Name = "Microsoft.Graph.Intune"
If ($InstalledModules.name -notcontains $Module_Name) {
	Write-Host "Installing module $Module_Name"
	Install-Module $Module_Name -Force
}
Else {
	Write-Host "$Module_Name Module already installed"
}		

#Importing Module
Write-Host "Importing Module $Module_Name"
Import-Module $Module_Name

#################################################
################## Login ########################
#################################################

$authority = "https://login.windows.net/$TenantId"

Update-MSGraphEnvironment -AppId $ClientID -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $ClientSecret -Quiet

### Creating Folders
if (!(Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -Force -ItemType Directory
} else {
    Write-Host "Path C:\Temp already exists"
}

$Path = "C:\Temp\IntuneBackup"
if (!(Test-Path $Path)) {
    New-Item -Path $Path -Force -ItemType Directory
} else {
    Write-Host "Path $Path already exists"
}

#################################################
######## Starting Intune Backup #################
#################################################

Write-Host "Starting Intune Backup"
Start-IntuneBackup -Path $Path

#################################################
######### Logon to Microsoft Azure ##############
#################################################

Write-Host "Logging on to Azure with Az CLI"
az login --service-principal -u $ClientID -p $ClientSecret --tenant $TenantId

#################################################
######### Upload to Storage Account #############
#################################################

## Parameters
$FolderName = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

Write-Host "Uploading Intune Backup to storageaccount $($StorageAccountName) in container $($ContainerName)"

$GetKey = az storage account keys list --resource-group $RGName --account-name $StorageAccountName
$StorageAccountKey = $GetKey | ConvertFrom-Json

az storage blob upload-batch --destination $ContainerName `
                            --account-name $StorageAccountName `
                            --account-key $StorageAccountKey.Value[0] `
                            --destination-path $FolderName `
                            --source $Path

### Clean Up Folder
if (Test-Path $Path) {
    Write-Host "Deleting $Path"
    Remove-Item $Path -Recurse -Force
} else {
    Write-Host "Path $Path does not exist"
}