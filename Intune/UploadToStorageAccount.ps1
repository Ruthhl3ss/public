
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $RGName,
    [Parameter()]
    [string]
    $StorageAccountName,
    [Parameter()]
    [string]
    $ContainerName,
    [Parameter()]
    [string]
    $PackageName,
    [Parameter()]
    [string]
    $SourcePath
)

# Get Access Key from storage account
$GetKey = az storage account keys list --resource-group $RGName --account-name $StorageAccountName
$StorageAccountKey = $GetKey | ConvertFrom-Json

az storage blob upload-batch --destination $ContainerName `
                            --account-name $StorageAccountName `
                            --account-key $StorageAccountKey.Value[0] `
                            --destination-path $PackageName `
                            --source $SourcePath

