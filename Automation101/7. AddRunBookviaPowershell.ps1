
$rgName = "AutomationDemo"
$location = "westeurope"
$automationAccountName = "AutomationAccount"

$params = @{
    AutomationAccountName = $automationAccountName
    Name                  = 'Sample_TestRunbook'
    ResourceGroupName     = $rgName
    Type                  = 'PowerShell'
    Path                  = "/Users/nko/VSCodeWorkspaces/Demo/Demo/Automation101/1. AutomationAccount.ps1"
}
Import-AzAutomationRunbook @params