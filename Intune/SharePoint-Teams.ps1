

######################################
# Change Sharepoint Settings         #
######################################
Connect-AzureAD

$name = get-azureaddomain | Where-Object {($_.name -like '*.onmicrosoft.com') -and ($_.name -notlike '*.mail.onmicrosoft.com')} | Select-Object name
$name.name
$ShortName = $name.Name.Replace(".onmicrosoft.com","")
$sharepointadmincenter = "https://"+$shortname+"-admin.sharepoint.com"

Connect-SPOService -url $sharepointadmincenter
Set-SPOTenantSyncClientRestriction  -ExcludedFileExtensions "exe;bat;msi;dll;vbs;vbe"
set-spotenant -sharingcapability externalusersharingonly
set-spotenant -defaultsharinglinktype direct
set-spotenant -LegacyAuthProtocolsEnabled $false
set-spotenant -RequireAcceptingAccountMatchInvitedAccount $true
Set-SPOBrowserIdleSignOut -Enabled $true -WarnAfter (New-TimeSpan -Seconds 2700) -SignOutAfter (New-TimeSpan -Seconds 3600)
set-spotenant -PreventExternalUsersFromResharing $true
set-spotenant -DisplayStartASiteOption $False
set-spotenant -DisallowInfectedFileDownload  $true
set-spotenant -NotifyOwnersWhenItemsReshared $True
set-spotenant -NotifyOwnersWhenInvitationsAccepted $True
set-spotenant -OwnerAnonymousNotification $True
set-spotenant -OneDriveForGuestsEnabled $false


get-AzureADMSAuthorizationPolicy | Set-AzureADMSAuthorizationPolicy -GuestUserRoleId '2af84b1e-32c8-42b7-82bc-daa82404023b'

Connect-IPPSSession
Set-PolicyConfig -EnableLabelCoauth $True -EnableSpoAipMigration $True


####################
New-AzureADPolicy -Type AuthenticatorAppSignInPolicy -Definition '{"AuthenticatorAppSignInPolicy":{"Enabled":true}}' -isOrganizationDefault $true -DisplayName AuthenticatorAppSignIn


###############################################
# limited the group creaters for teams       #
#############################################

$GroupName = “Group_creators”
$AllowGroupCreation = "False"

#Connect-AzureAD

$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
      $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

if($GroupName)
{
    $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
}

Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

(Get-AzureADDirectorySetting -Id $settingsObjectID).Values

#####################
#Install-module MicrosoftTeams

import-module MicrosoftTeams
Connect-MicrosoftTeams
Set-CsTeamsClientConfiguration -AllowEgnyte $false
set-CsTeamsClientConfiguration -allowbox $false
set-CsTeamsClientConfiguration -allowdropbox $false
set-CsTeamsClientConfiguration -allowgoogledrive $false
set-CsTeamsClientConfiguration -allowsharefile $false
set-CsTeamsClientConfiguration -AllowEmailIntoChannel $true
set-CsTeamsClientConfiguration -AllowGuestUser $true
set-CsTeamsAppPermissionPolicy -GlobalCatalogAppsType blockedapplist
 
###################
# Dont allow users to add creditcards themselfs.
###############

#Install-Module MSCommerce -force
Import-Module -Name MSCommerce 
Connect-MSCommerce
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase | Where-Object { $_.PolicyValue -eq “Enabled”} | ForEach-Object { 
Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $_.ProductID -Enabled $false  }