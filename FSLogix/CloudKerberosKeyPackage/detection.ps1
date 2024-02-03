$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$Name = "CloudKerberosTicketRetrievalEnabled"
$value = 1

$Regkey = Get-ItemProperty -Path $registryPath -Name $name -ErrorAction SilentlyContinue

if ($Regkey.CloudKerberosTicketRetrievalEnabled -eq $value) {
    Write-Output "RegKey Found"
}
else {
    Write-Output "RegKey not Found"
    Exit 1
}