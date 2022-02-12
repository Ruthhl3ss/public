
#####################################################################################
# Functions for retrieving configuration policy etc.. information via Graph API.
#####################################################################################
Function Get-AdministrativeTemplatePolicys(){
 
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/groupPolicyConfigurations"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value

}

Function Get-ConfigurationPolicys(){
 
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/deviceConfigurations"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value

}

Function Get-IntunePowershellscripts(){
  
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/deviceManagementScripts"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value
  
}

Function Get-CompliancePolicys(){
  
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/deviceCompliancePolicies"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value
  
}

Function Get-SecurityBaseLinePolicys(){
  
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/intents"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  $Policys = (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value
  #Selecting Windows 10 Security Baseline from all Policy's 
  $Policys | Where-Object displayName -Like "*Baseline*"

}

Function Get-AutoPilotProfile(){

  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
  (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).Value

} 


#####################################################################################
## Check for Modules
#####################################################################################

#Checking for correct modules and installing them if needed
$InstalledModules = Get-InstalledModule
$Module_Name = "MSAL.PS"
If ($InstalledModules.name -notcontains $Module_Name) {
	Write-Host "Installing module $Module_Name"
	Install-Module $Module_Name -Force
}
Else {
	Write-Host "$Module_Name Module already installed"
}		

#Importing Module
Write-Host "Importing Module $Module_Name"
Import-Module $Module_Name

#####################################################################################
## Login Part
#####################################################################################

Write-Host "Getting token for Authentication"

# Token voor Configuration Profiles, Update Policies
$authResult = Get-MsalToken -ClientId d1ddf0e4-d672-4dae-b554-9d5bdfd93547 -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Interactive
$AuthHeaders = @{
          'Content-Type'='application/json'
          'Authorization'="Bearer " + $authResult.AccessToken
          'ExpiresOn'=$authResult.ExpiresOn
         
}

## Remove Administrative Templates

$AdministrativePolicys = Get-AdministrativeTemplatePolicys

foreach ($AdministrativePolicy in $AdministrativePolicys){
    Write-Host "Remove Administrative Policy $($AdministrativePolicy.displayName)"
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/groupPolicyConfigurations"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($AdministrativePolicy.id)"
    Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Configuration Policies

$ConfigurationPolcies = Get-ConfigurationPolicys

foreach ($ConfigurationPolcy in $ConfigurationPolcies){
    Write-Host "Remove Administrative Policy $($ConfigurationPolcy.displayName)"
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceConfigurations"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($ConfigurationPolcy.id)"
    Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Compliance Policies

$CompliancePolicyies = Get-CompliancePolicys

foreach ($CompliancePolicy in $CompliancePolicyies) {
  Write-Host "Remove Compliance Policy $($CompliancePolicy.displayName)"
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/deviceCompliancePolicies"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($CompliancePolicy.id)"
  Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Powershell Scripts

$IntunePowershellScripts = Get-IntunePowershellscripts

foreach ($IntunePowershellScript in $IntunePowershellScripts) {
  Write-Host "Remove Intune Powershell Script $($IntunePowershellScript.displayname)"
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/deviceManagementScripts"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($IntunePowershellScript.id)"
  Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Security Baselines

$SecurityBaseLinePolicies = Get-SecurityBaseLinePolicys

foreach ($SecurityBaselinePolicy in $SecurityBaseLinePolicies) {
  Write-Host "Remove Security Baseline Policys $($SecurityBaselinePolicy.displayName)"
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/intents"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($SecurityBaselinePolicy.id)"
  Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Autopilot Profiles
# Delete Assingments first

$AutopilotProfiles = Get-AutoPilotProfile

foreach ($AutoPilotProfile in $AutopilotProfiles) {
    Write-Host "Removing AutoPilot Assignments $($AutoPilotProfile.displayName)"
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($AutopilotProfile.id)/assignments"
    Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete
}

## Remove Profiles
$AutopilotProfiles = Get-AutoPilotProfile

foreach ($AutopilotProfile in $AutopilotProfiles) {
  
  Write-Host "Remove AutoPilot Profile $($AutopilotProfile.displayname)"
  $graphApiVersion = "Beta"
  $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)/$($AutopilotProfile.id)"
  Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Delete

}


