#Variables
$rgName = "AutomationDemo"
$location = "westeurope"
$automationAccountName = "AutomationAccount"

#Log in
Connect-AzAccount

#Select subscription
Get-AzSubscription -SubscriptionName "SUBSCRIPTION NAME" | Select-AzSubscription

#Create a new resource group
New-AzResourceGroup -Name $rgName -Location $location

#Create Automation Account
New-AzAutomationAccount -Name $automationAccountName -Location $location -ResourceGroupName $rgName

#Assign System Identity
Set-AzAutomationAccount -Name $automationAccountName -AssignSystemIdentity -ResourceGroupName $rgName




<#
#Add Modules
$moduleName = "Microsoft.Graph.Authentication"
$moduleVersion = "2.6.1"
New-AzAutomationModule -AutomationAccountName $automationAccountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

#Add Modules
$moduleName = <ModuleName>
$moduleVersion = <ModuleVersion>
New-AzAutomationModule -AutomationAccountName $automationAccountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"
#>