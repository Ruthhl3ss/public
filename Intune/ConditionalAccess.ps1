
Connect-AzureAD

$NamedLocationPolicy = "Country named location policy"
#Create Named location Policy
New-AzureADMSNamedLocationPolicy -OdataType "#microsoft.graph.countryNamedLocation" `
         -DisplayName $NamedLocationPolicy `
         -CountriesAndRegions "CA","BE","FR","DE","NL","ES","GB","SE","CH","AT" `
         -IncludeUnknownCountriesAndRegions $false

# Gather Policy ID for later use
$NamedLocationPolicyID = Get-AzureADMSNamedLocationPolicy | Where-Object displayName -eq $NamedLocationPolicy

#########################################################################
### 1. Block Legacy Authentication
#########################################################################


$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "All"
     
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
     
$conditions.ClientAppTypes = @('ExchangeActiveSync', 'Other')
     
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = "block"

$name = "C001 - Block Legacy Authentication All Apps"
$state = "Disabled"
 
New-AzureADMSConditionalAccessPolicy `
    -DisplayName $name `
    -State $state `
    -Conditions $conditions `
    -GrantControls $controls

#########################################################################
### 2. Require MultiFactor Authentication for all location except trusted
#########################################################################

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "All"
     
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"

$conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
$conditions.Locations.IncludeLocations = 'All'
$conditions.Locations.ExcludeLocations = 'AllTrusted'

$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls 
$controls._Operator = "OR"
$controls.BuiltInControls = "Mfa"


$name = "C002 - Require MultiFactor Authentication All Apps"
$state = "Disabled"
 
New-AzureADMSConditionalAccessPolicy `
    -DisplayName $name `
    -State $state `
    -Conditions $conditions `
    -GrantControls $controls

#########################################################################
### 3. Block Countries except naming policy
#########################################################################

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "All"
     
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"

$conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
$conditions.Locations.IncludeLocations = 'All'
$conditions.Locations.ExcludeLocations = $NamedLocationPolicyID.Id

$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = "block"

$name = "C003 - Require Allowed Countries All Apps"
$state = "Disabled"
 
New-AzureADMSConditionalAccessPolicy `
    -DisplayName $name `
    -State $state `
    -Conditions $conditions `
    -GrantControls $controls

#########################################################################
### 4. Require MFA To Register Device
#########################################################################

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeUserActions = "urn:user:registerdevice"

$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"

$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls 
$controls._Operator = "OR"
$controls.BuiltInControls = "Mfa"

$name = "C004 - Require MFA To Register Device"
$state = "Disabled"
 
New-AzureADMSConditionalAccessPolicy `
    -DisplayName $name `
    -State $state `
    -Conditions $conditions `
    -GrantControls $controls

##### Test

$Policy = Get-AzureADMSConditionalAccessPolicy -PolicyId 566b83b7-ab14-4010-aff6-e993e3eb4f17
$Policy.Conditions.Applications


###############################################################################
# 1. GRANT - Require_Managed_Device_for_Windows_or_Mac_client_app_access##
################################################################################




###################################################################
# 2. GRANT - Require_MDM_Managed_Devices_For_Mobile_App_Access	         
###################################################################



#######################################################################
# 3. GRANT - Require_MAM_approved_app_Unmanaged_Devices_for_mobile_access_ExceptExchange##
########################################################################



#######################################################################
# 4. GRANT - Require_MAM_approved_app_for_mobile access_OnlyExchange
##########################################################################



#########################################################################
#5. GRANT- Require_MFA_Weblogin_From_NonManaged_devices     		#
##########################################################################




#########################################
# 8.BLOCK - Unsupported_devices_platforms##
##########################################



###############################
# 10. BLOCK - Activesync	   ##
################################

###############################
# 11. Block_PersistentMode 		##
################################


#######################################################
# 12. BLOCK - Sharepoint_Downloads_From_NonCompliant_Devices##
#########################################################


#############################################################
# 13. BLOCK - Exchangeonline_Downloads_From_NonManaged_devices##
##############################################################



#####################################
# 14. BLOCK - PowerShell_Access_NonManaged_devices
######################################


#####################################
# 15. REQUIRE - Inspect_MCAS_Unmanaged  ##
######################################