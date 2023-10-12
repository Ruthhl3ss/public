#Connect to Az Account with the Managed Identity
Connect-AzAccount -Identity

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token

$Headers = @{
    'Authorization' = $token
    "Content-Type"  = 'application/json'
}

$Result = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities" -Headers $Headers -Method Get

$Result.Value

<#
$Result.value | Select-Object serialNumber,deploymentProfileAssignmentStatus,deploymentProfileAssignmentDetailedStatus,groupTag | Format-List




#>