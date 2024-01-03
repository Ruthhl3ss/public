Start-Transcript -Path "C:\Windows\Temp\WinUpdate.log"

Install-PackageProvider Nuget -Force

Install-Module -Name PSWindowsUpdate -Force

Install-WindowsUpdate -Install -AcceptAll -IgnoreReboot | Out-File "c:\Windows\Temp\MSUpdates-$(Get-Date -f yyyy-MM-dd).log" 

Stop-Transcript