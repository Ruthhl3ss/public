Start-Transcript -Path "C:\Windows\Temp\Modules.log"

Set-ExecutionPolicy Bypass -Force

Install-PackageProvider -name NuGet -force

Import-Module -Name PowershellGet

Install-Module -Name PowershellGet -Force

Stop-Transcript