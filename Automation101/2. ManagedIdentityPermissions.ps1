$DestinationTenantId = "TENANT ID"
$MsiName = "MANAGED IDENTITY NAAM" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).

$oPermissions = @(
  "Directory.ReadWrite.All"
  "Group.ReadWrite.All"
  "DeviceManagementServiceConfig.ReadWrite.All"
  "DeviceManagementManagedDevices.ReadWrite.All"
  "Mail.Send"
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.

$oMsi = Get-AzADServicePrincipal -Filter "displayName eq '$MsiName'"
$oGraphSpn = Get-AzADServicePrincipal -Filter "appId eq '$GraphAppId'"

$oAppRole = $oGraphSpn.AppRole | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberType -contains "Application")}

Connect-MgGraph -TenantId $DestinationTenantId -Scopes "AppRoleAssignment.ReadWrite.All", "Directory.Read.All", "Application.Read.All"

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $oMSI.Id
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }
  
  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment
}