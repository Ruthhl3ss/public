$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$Name = "CloudKerberosTicketRetrievalEnabled"
$value = 1

Remove-ItemProperty -Path $registryPath -Name $name