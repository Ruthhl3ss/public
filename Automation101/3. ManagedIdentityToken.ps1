#Connect to Az Account with the Managed Identity
Connect-AzAccount -Identity

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token

Get-AzAccessToken -ResourceTypeName MSGraph