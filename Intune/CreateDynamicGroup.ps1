
## Creating Dynamic group
#Pop Up Menu in Powershell for input for GroupName & OrderID
#DynamicGroupName
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$title = 'Dynamic Group Name'
$msg   = 'Enter Dynamic Group Name:'
$DynamicGroupName = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
#OrderID
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$title = 'Order ID'
$msg   = 'Enter Order ID:'
$OrderID = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

#Checking for correct modules and installing them if needed
$InstalledModules = Get-InstalledModule
if ($InstalledModules.name -notcontains 'AzureADPreview' ) {
    Write-Host 'Installing module Azure AD Preview'
    Install-Module AzureADPreview -Force
}
else {
    Write-Host 'Azure AD Preview Module already installed'
}

#Importing Module
Write-Host 'Importing Module Azure AD Preview'
Import-Module AzureADPreview

#Connecting to Azure AD to Create the Group
Connect-AzureAD

##DynamicGroupRule Properties:
$DynamicGroupRule = "(device.devicePhysicalIds -any _ -eq ""[OrderID]:$OrderID"")"

#Create Dynamic Group
New-AzureADMSGroup -DisplayName $DynamicGroupName `
        -Description "This is used Windows 10 Autopilot Device with the OrderID $OrderID" `
        -MailNickname "AutoPilotGroup-$OrderID" `
        -MailEnabled $false `
        -SecurityEnabled $True `
        -GroupTypes "DynamicMembership" `
        -membershipRule $DynamicGroupRule `
        -membershipRuleProcessingState "On"