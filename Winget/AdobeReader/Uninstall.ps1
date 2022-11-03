#Fill this variable with the Winget package ID
$PackageName = "Adobe.Acrobat.Reader.64-bit"

#Creating Loggin Folder
if (!(Test-Path -Path C:\ProgramData\WinGetLogs)) {
    New-Item -Path C:\ProgramData\WinGetLogs -Force -ItemType Directory
}
#Start Logging
Start-Transcript -Path "C:\ProgramData\WinGetLogs\$($PackageName)_Uninstall.log" -Append

#Detect Apps
$InstalledApps = winget list --id $PackageName

if ($InstalledApps) {
    
    Write-Host "Trying to uninstall $($PackageName)"
    
    try {
        winget uninstall $PackageName --silent
    }
    catch {
        Throw "Failed to uninstall $($PackageName)"
    }
}
else {
    Write-Host "$($PackageName) is not installed or detected"
}

Stop-Transcript