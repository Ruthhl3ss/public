#Check If Installation has succeeded
$InstalledApplications = Get-WmiObject Win32_Product

if ($InstalledApplications.IdentifyingNumber -contains '{6CD9E9ED-906D-4196-8DC3-F987D2F6615F}') {
    Write-Host 'Microsoft Visual C++ 2017 X64 Runtime installed succesfully'
}
Else {
    Write-Error 'Microsoft Visual C++ 2017 X64 Runtime installation not found'
}

if ($InstalledApplications.identifyingNumber -contains '{7453C0F5-03D5-4412-BB8F-360574BE29AF}') {
    Write-Host 'Microsoft ODBC Driver 17 installed succesfully'
}
Else {
    Write-Error 'Microsoft ODBC Driver 17 installation not found'
}
