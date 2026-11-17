<#
.SYNOPSIS
Sets IsCloudManaged to true for all synced Entra ID users that are not yet cloud managed.

.DESCRIPTION
Retrieves all Entra ID users that originate from on-premises (onPremisesSyncEnabled eq true), reads
onPremisesSyncBehavior/isCloudManaged for each user via Microsoft Graph v1.0 and, when the value is false,
PATCHes it to true. Supports -WhatIf. Failures per user are reported as warnings and the script throws at
the end when one or more users failed.

Required Graph permission (least privileged): User-OnPremisesSyncBehavior.ReadWrite.All
Plus User.Read.All to list users.

.PARAMETER AccessToken
Microsoft Graph access token (plain text JWT) with the permissions listed above. Audience must be https://graph.microsoft.com.

.EXAMPLE
.\Set-EntraUserCloudManaged.ps1 -AccessToken $accessToken -Verbose -WhatIf

Shows which users would be changed without changing them.

.EXAMPLE
$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
.\Set-EntraUserCloudManaged.ps1 -AccessToken $accessToken -Verbose

Sets all non-cloud-managed synced users to cloud managed, using a token from the Az session.
#>

#region Parameters
[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [Parameter(Mandatory = $true, HelpMessage = "Microsoft Graph access token as plain text.")]
  [ValidateNotNull()]
  [string]$AccessToken
)
#endregion Parameters

#region Import Modules
# No modules required.
#endregion Import Modules

#region Execution
$changedCount = 0
$failedCount = 0
$skippedCount = 0
$users = [System.Collections.Generic.List[object]]::new()

Write-Verbose -Message "Building request headers."
try {
  $headers = @{
    "Authorization"    = "Bearer $AccessToken"
    "ConsistencyLevel" = "eventual"
  }
}
catch {
  throw "Failed to build request headers: $($_.Exception.Message)"
}
Write-Verbose -Message "Done."

Write-Verbose -Message "Retrieving synced users."
try {
  $nextUri = "https://graph.microsoft.com/v1.0/users?`$filter=onPremisesSyncEnabled eq true&`$select=id,userPrincipalName&`$top=999"
  while ($nextUri) {
    $response = Invoke-RestMethod -Method Get -Uri $nextUri -Headers $headers -ErrorAction Stop
    $users.AddRange(@($response.value))
    $nextUri = $response."@odata.nextLink"
  }
}
catch {
  throw "Failed to retrieve synced users: $($_.Exception.Message)"
}
Write-Verbose -Message "Done."
Write-Verbose -Message "Found $($users.Count) synced users."

foreach ($user in $users) {
  $uri = "https://graph.microsoft.com/v1.0/users/$($user.id)/onPremisesSyncBehavior"

  Write-Verbose -Message "Reading IsCloudManaged for $($user.userPrincipalName)."
  try {
    $syncBehavior = Invoke-RestMethod -Method Get -Uri "$uri`?`$select=isCloudManaged" -Headers $headers -ErrorAction Stop
  }
  catch {
    Write-Warning -Message "Failed to read IsCloudManaged for $($user.userPrincipalName): $($_.Exception.Message)"
    $failedCount++
    continue
  }
  Write-Verbose -Message "Done."

  if ($syncBehavior.isCloudManaged -eq $true) {
    $skippedCount++
    continue
  }

  if (-not $PSCmdlet.ShouldProcess($user.userPrincipalName, "Set IsCloudManaged to true")) {
    continue
  }

  Write-Verbose -Message "Setting IsCloudManaged to true for $($user.userPrincipalName)."
  try {
    $body = @{ "isCloudManaged" = $true } | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
    $changedCount++
    Write-Output "Set to cloud managed: $($user.userPrincipalName)"
  }
  catch {
    Write-Warning -Message "Failed to set IsCloudManaged for $($user.userPrincipalName): $($_.Exception.Message)"
    $failedCount++
  }
  Write-Verbose -Message "Done."
}

Write-Output "Changed: $changedCount, already cloud managed: $skippedCount, failed: $failedCount."

if ($failedCount -gt 0) {
  throw "$failedCount user(s) failed. See warnings above."
}
#endregion Execution
