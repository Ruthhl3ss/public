param (
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $False)]
    [string]$AzLoginname,
    [Parameter(Mandatory = $True, Position = 2, ValueFromPipeline = $False)]
    [string]$AzPassword,
    [Parameter(Mandatory = $True, Position = 3, ValueFromPipeline = $False)]
    [string]$PackageName,
    [Parameter(Mandatory = $True, Position = 4, ValueFromPipeline = $False)]
    [string]$DOOrganizationname,
    [Parameter(Mandatory = $True, Position = 5, ValueFromPipeline = $False)]
    [string]$DOProject,
    [Parameter(Mandatory = $True, Position = 6, ValueFromPipeline = $False)]
    [string]$Scope,
    [Parameter(Mandatory = $True, Position = 7, ValueFromPipeline = $False)]
    [string]$Feed,
    [Parameter(Mandatory = $True, Position = 8, ValueFromPipeline = $False)]
    [string]$ArtifactName,
    [Parameter(Mandatory = $True, Position = 9, ValueFromPipeline = $False)]
    [string]$Version
    )

function InstallArtifact {

    $Path = 'C:\ProgramData\DevOpsInstallFolder\'+$PackageName

    #CreationOfFolders
    If (!(Test-Path 'C:\ProgramData\DevOpsInstallFolder')){
        New-Item 'C:\ProgramData\DevOpsInstallFolder' -ItemType Directory
    }

    If (!(Test-Path $Path)){
        New-Item $Path -ItemType Directory
    }

    az extension add --name azure-devops --yes

    az login --allow-no-subscriptions -u $AzLoginname -p $AzPassword 

    az artifacts universal download --organization $DOOrganizationname --project $DOProject --scope $Scope --feed $Feed --version $Version --name $ArtifactName --path $path

    $installScript = Get-ChildItem $Path -Filter *.ps1 

    If (Test-Path $installScript.Fullname ){

        .$installScript.Fullname
    }
    Else {

        Write-Host "Install Script not available"
    }
}

InstallArtifact -AzLoginname $AzLoginname -AzPassword $AzPassword -PackageName $PackageName -DOOrganizationname $DOOrganizationname -DOProject $DOProject -Scope $Scope -Feed $Feed -ArtifactName $ArtifactName -Version $Version