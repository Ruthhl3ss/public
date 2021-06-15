
#Gather parameters
param (
[Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $False)]
[string]$AzLoginname,
[Parameter(Mandatory = $True, Position = 2, ValueFromPipeline = $False)]
[string]$AzPassword,
[Parameter(Mandatory = $True, Position = 3, ValueFromPipeline = $False)]
[string]$AztenantID,
[Parameter(Mandatory = $True, Position = 4, ValueFromPipeline = $False)]
[string]$PackageName,
[Parameter(Mandatory = $True, Position = 5, ValueFromPipeline = $False)]
[string]$DOOrganizationname,
[Parameter(Mandatory = $True, Position = 6, ValueFromPipeline = $False)]
[string]$DOProject,
[Parameter(Mandatory = $True, Position = 7, ValueFromPipeline = $False)]
[string]$Scope,
[Parameter(Mandatory = $True, Position = 8, ValueFromPipeline = $False)]
[string]$Feed,
[Parameter(Mandatory = $True, Position = 9, ValueFromPipeline = $False)]
[string]$ArtifactName,
[Parameter(Mandatory = $True, Position = 10, ValueFromPipeline = $False)]
[string]$Version
)
#Create extra variable
$Path = 'C:\ProgramData\DevOpsInstallFolder\'+$PackageName
    
#CreationOfFolders
If (!(Test-Path 'C:\ProgramData\DevOpsInstallFolder')){
    New-Item 'C:\ProgramData\DevOpsInstallFolder' -ItemType Directory
}

If (!(Test-Path $Path)){
    New-Item $Path -ItemType Directory
}
#Install Azure DevOps Extension for Azure CLI
az extension add --name azure-devops --yes
#Log on to Azure CLI
az login --allow-no-subscriptions -u $AzLoginname -p $AzPassword --tenant $AztenantID
#DOwnload Artifacts
az artifacts universal download --organization $DOOrganizationname --project $DOProject --scope $Scope --feed $Feed --version $Version --name $ArtifactName --path $path
#Grab install script path from artifact
$installScript = Get-ChildItem $Path -Filter *.ps1 

#Run Install script if available
If (Test-Path $installScript.Fullname ){
    .$installScript.Fullname
}
Else {
    Write-Host "Install Script not available"
}