#Fill this variable with the Winget package ID
$PackageName = "Adobe.Acrobat.Reader.64-bit"

#Getting Current Installed Packages
$AppxPackages = Get-AppxPackage

#Creating Loggin Folder
if (!(Test-Path -Path C:\ProgramData\WinGetLogs)) {
    New-Item -Path C:\ProgramData\WinGetLogs -Force -ItemType Directory
}
#Start Logging
Start-Transcript -Path "C:\ProgramData\WinGetLogs\$($PackageName).log" -Append

#Getting Windows Version
$WindowsVersion = (Get-CimInstance Win32_OperatingSystem).version

#Start Winget Installation with dependencies if Windows 10 is detected
If (($WindowsVersion -ge "10.0.18*") -and ($WindowsVersion -lt "10.0.22*")){

    Write-Host "Host runs Windows 10, Checking if Winget needs to be installed." -ForegroundColor Yellow

    If($AppxPackages.Name -notcontains "Microsoft.Winget.Source") {

        Write-Host "Winget is not installed, trying to install latest version from Github" -ForegroundColor Yellow

        Try {
            #Create Temp Folder
            Write-Host "Creating Temp Folder" -ForegroundColor Yellow

            if (!(Test-Path -Path C:\Temp)) {
            New-Item -Path C:\Temp -Force -ItemType Directory
            }

            Set-Location C:\temp
            
            #Install Dependencies
            If ($AppxPacakges.Name -notcontains "Microsoft.UI.Xaml.2.7"){
                
                try {
                    Write-Host "Installing Microsoft.UI.Xaml.2.7" -ForegroundColor Yellow
            
                    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0" -OutFile "C:\Temp\microsoft.ui.xaml.2.7.0.zip"
                
                    Expand-Archive C:\Temp\microsoft.ui.xaml.2.7.0.zip -Force
                
                    Add-AppxPackage "C:\Temp\microsoft.ui.xaml.2.7.0\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
                }
                catch {
                    Throw "Installing Microsoft.UI.Xaml.2.7 install Failed"
                }

            }
            Else {
                Write-Host "Microsoft.UI.Xaml.2.7 already installed" -ForegroundColor Green
            }
            #Install Dependencies
            If ($AppxPacakges.Name -notcontains "Microsoft.VCLibs.140.00.UWPDesktop"){

                try {
                    Write-Host "Installing Microsoft.VCLibs.140.00.UWPDesktop" -ForegroundColor Yellow
            
                    Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "C:\Temp\Microsoft.VCLibs.x64.14.00.Desktop.appx"
                
                    Add-AppxPackage "C:\Temp\Microsoft.VCLibs.x64.14.00.Desktop.appx"
                }
                catch {
                    Throw "Microsoft.VCLibs.140.00.UWPDesktop"
                }
                

            }
            Else {
                Write-Host "Microsoft.VCLibs.140.00.UWPDesktop already installed" -ForegroundColor Green
            }
            #Install Winget
            If ($AppxPacakges.Name -notcontains "Microsoft.Winget.Source") {    
                try {
                    Write-Host "Installing Winget" -ForegroundColor Yellow  

                    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "C:\Temp\Winget.msixbundle"
    
                    Add-AppxPackage "C:\Temp\Winget.msixbundle"
                }
                catch {
                    Throw "Winget install Failed"
                }     

            }
            Else {      
                Write-Host "Winget already installed" -ForegroundColor Green
            }

            Set-Location C:\Windows

            Write-Host "Cleaning up Temp Folder" -ForegroundColor Yellow

            if (Test-Path -Path C:\Temp) {
                Remove-Item -Path C:\Temp -Force -Recurse
            }  
        }
        Catch {
            Throw "Failed to install Winget"
            Break
        }

    }
    Else {
        Write-Host "Winget already installed, moving on" -ForegroundColor Green
    }
}

#Skipping Winget Installation if Windows 11 is detected
If ($WindowsVersion -Like "10.0.22*"){

    Write-Host "Host runs Windows 11, skipping installation of WinGet" -ForegroundColor Green

}

#Trying to install Package with Winget
IF ($PackageName){
    try {
        Write-Host "Installing $($PackageName) via Winget" -ForegroundColor Green
        winget install $PackageName --silent --accept-source-agreements --accept-package-agreements
    }
    Catch {
        Throw "Failed to install package $($_)"
    }
}
Else {
    Write-Host "No PackageName specified" -ForegroundColor Red
}
#Stop Logging
Stop-Transcript