[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $TenantId = "TenantID.onmicrosoft.com",
    [Parameter()]
    [string]
    $ClientID = "Service Principal Client ID",
    [Parameter()]
    [string]
    $StorageAccountName = "storageaccountname",
    [Parameter()]
    [string]
    $RGName = "ResourceGroupName",
    [Parameter()]
    [string]
    $ContainerName = "ContainerName"
)

$ClientSecret = Get-AutomationVariable -Name secret

#Importing Modules
$Module_Name = "IntuneBackupAndRestore"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Microsoft.Graph.Intune"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Az.Accounts"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Az.Storage"
Write-Output "Importing Module $Module_Name"
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

Write-Host "Logging on to Azure with Az Account"
$Secret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientID, $Secret
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

#################################################
######### Upload to Storage Account #############
#################################################

## Parameters
$FolderName = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

Write-Host "Uploading Intune Backup to storageaccount $($StorageAccountName) in container $($ContainerName)"

$StorageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $RGName -AccountName $StorageAccountName
$sourceFileRootDirectory = $Path
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey.Value[0]
$container = Get-AzStorageContainer -Name $ContainerName -Context $ctx

$container.CloudBlobContainer.Uri.AbsoluteUri
if ($container) {
    $filesToUpload = Get-ChildItem $sourceFileRootDirectory -Recurse -File

    foreach ($x in $filesToUpload) {
        $PartPath = ($x.fullname.Substring($sourceFileRootDirectory.Length + 1)).Replace("\", "/")
        $FullPath = $FolderName + "/" + $PartPath
        Write-Verbose "Uploading $("\" + $x.fullname.Substring($sourceFileRootDirectory.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $FullPath)"
        Set-AzStorageBlobContent -File $x.fullname -Container $container.Name -Blob $FullPath -Context $ctx -Force:$true| Out-Null
    }
}

### Clean Up Folder
if (Test-Path $Path) {
    Write-Host "Deleting $Path"
    Remove-Item $Path -Recurse -Force
} else {
    Write-Host "Path $Path does not exist"
}