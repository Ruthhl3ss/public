# Create WinGet Folder
New-Item -Path C:\WinGet -ItemType directory -ErrorAction SilentlyContinue

# Install VCLibs
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "C:\WinGet\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxPackage "C:\WinGet\Microsoft.VCLibs.x64.14.00.Desktop.appx"

# Install Microsoft.UI.Xaml from NuGet
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 -OutFile "C:\WinGet\Microsoft.UI.Xaml.2.7.3.zip"
Expand-Archive "C:\WinGet\Microsoft.UI.Xaml.2.7.3.zip" -DestinationPath "C:\WinGet\Microsoft.UI.Xaml.2.7.3"
Add-AppxPackage "C:\WinGet\Microsoft.UI.Xaml.2.7.3\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"

# Install latest WinGet from GitHub
Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile "C:\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Add-AppxPackage "C:\WinGet\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

# Fix Permissions
TAKEOWN /F "C:\Program Files\WindowsApps" /R /A /D Y
ICACLS "C:\Program Files\WindowsApps" /grant Administrators:F /T

# Add Environment Path
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
if ($ResolveWingetPath) {
	$WingetPath = $ResolveWingetPath[-1].Path
}
$ENV:PATH += ";$WingetPath"
$SystemEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
$SystemEnvPath += ";$WingetPath;"
setx /M PATH "$SystemEnvPath"

TAKEOWN /F "C:\Program Files\WindowsApps" /R /A /D Y
ICACLS "C:\Program Files\WindowsApps" /grant Administrators:F /T