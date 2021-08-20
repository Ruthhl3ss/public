
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $storageaccountrgname,
    [Parameter()]
    [string]
    $storageaccountname,
    [Parameter()]
    [string]
    $filesharename

)

$InstalledModules = Get-InstalledModule

If ($InstalledModules.Name -notcontains 'Az.Storage'){
    Install-Module -Name Az.Storage -Force
}

## Get StorageAccountKey
$storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $storageaccountrgname -AccountName $storageaccountname

Write-Host ($storageAccountKey).Value[0]

$connectTestResult = Test-NetConnection -ComputerName "$($storageaccountname).file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$($storageaccountname).file.core.windows.net`" /user:`"localhost\$($storageaccountname)`" /pass:$(($storageAccountKey).Value[0])"
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$($storageaccountname).file.core.windows.net\$($filesharename)" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

If (Test-Path Z:\Office){
    Write-Host "Z: Drive Mapped" -ForegroundColor Green

    If (Test-Path 'C:\Temp'){
        New-Item -Path 'C:\temp' -itemtype Directory
        New-Item -Path 'C:\temp\Log.txt'
        }
}
Else {
    Write-Host "Drive not mapped" -ForegroundColor Red
}