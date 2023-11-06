
Start-Transcript -Path C:\Windows\Temp\RemoveRDAgent.log -Append

$MyApp = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*remote Desktop Services*" }
$MyApp.Uninstall()
$MyApp2 = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*remote Desktop agent*" }
$MyApp2.Uninstall()

Stop-Transcript