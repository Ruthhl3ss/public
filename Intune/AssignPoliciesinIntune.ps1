
#Parameter block

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $AzureADGroup

)
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

#####################################################################################
#Run Part
#####################################################################################

#Assign Delivery Optimization, Wifi, Update Rings, Endpoint protection, Custom
$ConfigurationPolicys = Get-ConfigurationPolicys

foreach ($Configurationpolicy in $ConfigurationPolicys){
  Write-Host "Assigning Configuration Policy's $($Configurationpolicy.displayName)"
  $policyid = $Configurationpolicy.id
  $policyuri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations('$policyid')/assign"
  $JSON = "{'assignments':[{'id':'','target':{'@odata.type':'#microsoft.graph.groupAssignmentTarget','groupId':'$($AzureADGroup)'}}]}"
  Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
}

#Assign Administrative Templates
$AdministrativePolicys = Get-AdministrativeTemplatePolicys

foreach ($AdministrativePolicy in $AdministrativePolicys){
  Write-Host "Assigning Administrative Template $($AdministrativePolicy.displayName)"
  $policyid = $AdministrativePolicy.id
  $policyuri = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations('$policyid')/assign"
  $JSON = "{'assignments':[{'id':'','target':{'@odata.type':'#microsoft.graph.groupAssignmentTarget','groupId':'$($AzureADGroup)'}}]}"
  Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
}

#Assign Powershell Scripts
$IntunePowershellScripts = Get-IntunePowershellscripts

foreach ($IntunePowershellScript in $IntunePowershellScripts){
  Write-Host "Assigning Intune Powershell Script $($IntunePowershellScript.displayName)"
  $policyid = $IntunePowershellScript.id
  $policyuri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts('$policyid')/assign"
  $JSON = "{'deviceManagementScriptGroupAssignments':[{'@odata.type':'#microsoft.graph.deviceManagementScriptGroupAssignment','targetGroupId': '$AzureADGroup','id': '$policyid'}]}"
  Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
}

#Assign Compliance Policies
$CompliancePolicys = Get-CompliancePolicys

foreach ($CompliancePolicy in $CompliancePolicys){
  Write-Host "Assigning Compliance Policy $($CompliancePolicy.displayName)"
  $policyid = $CompliancePolicy.id
  $policyuri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies('$policyid')/assign"
  $JSON = "{'assignments':[{'id':'','target':{'@odata.type':'#microsoft.graph.groupAssignmentTarget','groupId':'$($AzureADGroup)'}}]}"
  Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
}

#Assign Security Baselines
$SecurityBaseLinePolicys = Get-SecurityBaseLinePolicys

foreach ($SecurityBaseLinePolicy in $SecurityBaseLinePolicys){
  Write-Host "Assigning Security Baseline Policy $($SecurityBaseLinePolicy.displayName)"
  $policyid = $SecurityBaseLinePolicy.id
  $policyuri = "https://graph.microsoft.com/beta/deviceManagement/intents('$policyid')/assign"
  $JSON = "{'assignments':[{'id':'','target':{'@odata.type':'#microsoft.graph.groupAssignmentTarget','groupId':'$($AzureADGroup)'}}]}"
  Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
}