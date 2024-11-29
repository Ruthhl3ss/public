#Fill this variable with the Winget package ID
$PackageName = "Adobe.Acrobat.Reader.64-bit"

#Creating Loggin Folder
if (!(Test-Path -Path C:\ProgramData\WinGetLogs)) {
    New-Item -Path C:\ProgramData\WinGetLogs -Force -ItemType Directory
}
#Start Logging
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($PackageName)_Uninstall.log" -Append

#Detect Apps
$InstalledApps = & $WingetPath\winget.exe list --id $PackageName

if ($InstalledApps) {
    
    Write-Host "Trying to uninstall $($PackageName)"
    
    try {        
        $ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller____8wekyb3d8bbwe"
        if ($ResolveWingetPath) {
            $WingetPath = $ResolveWingetPath[-1].Path
        }
    
        $config
        cd $wingetpath

        & $WingetPath\winget.exe uninstall $PackageName --silent
    }
    catch {
        Throw "Failed to uninstall $($PackageName)"
    }
}
else {
    Write-Host "$($PackageName) is not installed or detected"
}

Stop-Transcript
