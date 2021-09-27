#Check If Installation has succeeded
$InstalledApplications = Get-WmiObject Win32_Product

if ($InstalledApplications.IdentifyingNumber -contains '{65835E57-3712-4382-990A-8D39008A8E0B}') {
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
