#CreationOfFolders
If (!(Test-Path 'C:\ProgramData\DevOpsInstallFolder')){
    New-Item 'C:\ProgramData\DevOpsInstallFolder' -ItemType Directory
}

If (!(Test-Path $Path)){
    New-Item $Path -ItemType Directory
}

az login --allow-no-subscriptions -u $AzLoginname -p $AzPassword 

az artifacts universal download --organization $DOOrganizationname --project $DOProject --scope $Scope --feed $Feed --version $Version --name $ArtifactName --path $path

$installScript = Get-ChildItem $Path -Filter *.ps1 

If (Test-Path $installScript.Fullname ){

    .$installScript.Fullname
}
Else {

    Write-Host "Install Script not available"
}