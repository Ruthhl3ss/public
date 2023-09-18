[CmdletBinding()]
param (
    [Parameter()][String]$PackageId,
    [Parameter()][String]$TenantID,
    [Parameter()][String]$ClientID,
    [Parameter()][String]$ClientSecret
)

$body = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $ClientID
    Client_Secret = $ClientSecret
}

$connection = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token `
    -Method POST `
    -Body $body

$Token = $connection.access_token 

$Path = "C:\Package"

If (!(Test-Path $Path)) {
    Write-Output "Creating Package Folder"
    New-Item -Path $Path -ItemType Directory
}
else {
    Write-Output "Package Folder already exists"
}

## Create Winget Package

winget -v

winget-intune package $PackageId --source winget --package-folder $Path

Start-Sleep 5

winget-intune publish $PackageId --package-folder $Path --token $Token

#CleanUp

Remove-Item -Path $Path -Recurse -Force