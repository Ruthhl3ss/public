param (
		[Parameter(Mandatory=$true)]
        [string]$DynamicGroupName,
        [Parameter(Mandatory=$true)]
        [string]$OrderID,
		[Parameter(Mandatory=$true)]
		[string]$AutopilotProfileName		
    )


# ***************************************************************************************
# 									Check for module part	
# ***************************************************************************************

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



# ***************************************************************************************
# 									Authentication part	
# ***************************************************************************************

## Get a auth token from the Intune Powershell Enterprise Application	
$myToken = Get-MsalToken -ClientId d1ddf0e4-d672-4dae-b554-9d5bdfd93547 -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Interactive


# ***************************************************************************************
# 									Create group part	
# ***************************************************************************************
##DynamicGroupRule Properties:
$DynamicGroupRule = "(device.devicePhysicalIds -any _ -eq ""[OrderID]:$OrderID"")"
		
# Creating group
$Group_URL = "https://graph.microsoft.com/beta/groups/"	
$group = @{
	"displayName" = $DynamicGroupName;
	"description" = "This is used Windows 10 Autopilot Device with the OrderID $OrderID";
	"groupTypes" = @("DynamicMembership");
	"mailEnabled" = $False;
	"mailNickname" = "AutoPilotGroup-$OrderID";
	"membershipRule" = $DynamicGroupRule;
	"membershipRuleProcessingState" = "On";
	"securityEnabled" = $True
}	

$requestBody = $group | ConvertTo-Json #-Depth 5
$Create_group = Invoke-RestMethod -Headers @{Authorization = "Bearer $($myToken.AccessToken)" }  -Uri $Group_URL -Method POST -Body $requestBody -ContentType 'application/json'
$Group_ID = $Create_group.id

# Write-Host "Group created! Save this Object ID: $($CreateDynamicGroup.Id) in a notepad for later use" -ForegroundColor Green
Write-Host "Group created: $Group_ID!" -ForegroundColor Green


# ***************************************************************************************
# 									Create profile part	
# ***************************************************************************************
$AutopilotProfileDescription = "$AutopilotProfileName Azure AD Join AutoPilot Profile"
$Profile_Body = @{
	"@odata.type"                          = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"
	displayName                            = "$($AutopilotProfileName)"
	description                            = "$($AutopilotProfileDescription)"
	language                               = 'os-default'
	extractHardwareHash                    = $false
	enableWhiteGlove                       = $true
	outOfBoxExperienceSettings             = @{
		"@odata.type"             = "microsoft.graph.outOfBoxExperienceSettings"
		hidePrivacySettings       = $true
		hideEULA                  = $true
		userType                  = 'Standard'
		deviceUsageType           = 'singleuser'
		skipKeyboardSelectionPage = $false
		hideEscapeLink            = $true
	}
	enrollmentStatusScreenSettings         = @{
		'@odata.type'                                    = "microsoft.graph.windowsEnrollmentStatusScreenSettings"
		hideInstallationProgress                         = $true
		allowDeviceUseBeforeProfileAndAppInstallComplete = $true
		blockDeviceSetupRetryByUser                      = $false
		allowLogCollectionOnInstallFailure               = $true
		customErrorMessage                               = "An error has occured. Please contact your IT Administrator"
		installProgressTimeoutInMinutes                  = "45"
		allowDeviceUseOnInstallFailure                   = $true
	}
} | ConvertTo-Json		
		
$Profile_URL = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
$Create_Profile = Invoke-RestMethod -Headers @{Authorization = "Bearer $($myToken.AccessToken)" }  -Uri $Profile_URL -Method POST -Body $Profile_Body -ContentType 'application/json'
$Get_Profile_ID = $Create_Profile.ID



# ***************************************************************************************
# 									Assign profile part	
# ***************************************************************************************
$Assignment_Body = @"
{"target":{"@odata.type":"#microsoft.graph.groupAssignmentTarget","groupId":"$Group_ID"}}
"@

$Profile_Assignment_URL = "$Profile_URL/$($Get_Profile_ID)/assignments"
Invoke-RestMethod -Headers @{Authorization = "Bearer $($myToken.AccessToken)" }  -Uri $Profile_Assignment_URL -Method POST -Body $Assignment_Body -ContentType 'application/json'
Write-Host "Profile created and assign to the group!" -ForegroundColor Green
	
	
	
	
	
		