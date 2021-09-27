#Check If Installation has succeeded
$InstalledApplications = Get-WmiObject Win32_Product

if ($InstalledApplications.IdentifyingNumber -contains '{6CD9E9ED-906D-4196-8DC3-F987D2F6615F}') {
    Write-Log 'Microsoft Visual C++ 2017 X64 Runtime installed succesfully' -Level info
}
Else {
    Write-Log 'Microsoft Visual C++ 2017 X64 Runtime installation not found' -Level Error
}

if ($InstalledApplications.identifyingNumber -contains '{7453C0F5-03D5-4412-BB8F-360574BE29AF}') {
    Write-Log 'Microsoft ODBC Driver 17 installed succesfully' -Level info
}
Else {
    Write-Log 'Microsoft ODBC Driver 17 installation not found' -Level Error
}
