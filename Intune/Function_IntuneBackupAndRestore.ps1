
[CmdletBinding()]
param (
    [Parameter()]
    [bool]
    $Backup,
    [Parameter()]
    [bool]
    $Restore,
    [Parameter()]
    [string]
    $Path

)
    $InstalledModules = Get-InstalledModule
    if ($InstalledModules.name -notcontains "IntuneBackupAndRestore") {
        Write-Host "Installing Module IntuneBackupAndRestore"
        Install-Module -Name IntuneBackupAndRestore -Force
    }
    else {
        Write-Host "IntuneBackupAndRestore is already present"
    }
    if ($InstalledModules.name -notcontains "Microsoft.Graph.Intune") {
        Write-Host "Installing Module Microsoft.Graph.Intune"
        Install-Module -Name Microsoft.Graph.Intune -Force
    }
    else {
        Write-Host "Microsoft.Graph.Intune is already present"
    }
    #Login
    Write-Host "Logging on to Microsoft Graph Intune, fill the prompt with credentials"

    Import-Module IntuneBackupAndRestore
    Import-Module Microsoft.Graph.Intune

    Connect-MSGraph

    if ($Backup -eq $True) {
       Write-Host "Backup Option is true, starting Intune Backup."
       try {
            Start-IntuneBackup -Path $Path -Verbose
       }
       catch {
            $_.Exception
       }
        
    }
    #Export Current Config
    
    if ($Restore -eq $True) {
        
        Write-Host "Restore Option is true, starting Intune Backup."
        try {
            Start-IntuneRestoreConfig -Path $Path -Verbose
        }
        catch {
             $_.Exception
        }
    }