<#
.SYNOPSIS
Imports an AppLocker configuration from an XML file into Intune.
.DESCRIPTION
This script imports an AppLocker configuration from a specified XML file into Intune.
.EXAMPLE
Import-ApplockerConfig -Applockerxmlfile "C:\Path\To\Your\AppLockerConfig.xml" -ApplockerPolicyName "MyAppLockerPolicy"

.PARAMETER Applockerxmlfile
The path to the AppLocker XML file that contains the configuration to be imported.
.PARAMETER ApplockerPolicyName
The name of the AppLocker policy to be created in Intune.
.NOTES
This script requires the Microsoft.Graph.Authentication module to be installed and available.
This script connects to Microsoft Graph with the required permissions to create device configurations.

Author: Niels Kok: 12-07-2025

#>

[CmdletBinding()]
param (
  [Parameter()][System.Object]$Applockerxmlfile,
  [Parameter()][System.String]$ApplockerPolicyName
)

#region  <---------------------------- Prerequisites ----------------------------->

# Check if the required modules are installed
$requiredModules = @("Microsoft.Graph.Authentication")

foreach ($module in $requiredModules) {
  if (-Not (Get-Module -ListAvailable -Name $module)) {
    Write-Error "The required module is not installed: $module"
    return
  }
}

#region  <---------------------------- Extracting RuleCollections ----------------------------->

#Check if the XML file exists
if (-Not (Test-Path $Applockerxmlfile)) {
  Write-Error "The specified AppLocker XML file does not exist: $Applockerxmlfile"
  return
}

# Load the XML content
try {
  [xml]$applockerConfig = Get-Content -Path $Applockerxmlfile -ErrorAction Stop
}
catch {
  Write-Error "Failed to read the AppLocker XML file: $_"
  return
}

Write-Output "Successfully loaded AppLocker XML file: $Applockerxmlfile"

# Create base object for AppLocker Policy

$applockerPolicyObject = [PSCustomObject]@{
  '@odata.context'                            = 'https://graph.microsoft.com/beta/$metadata#deviceManagement/deviceConfigurations/$entity'
  '@odata.type'                               = '#microsoft.graph.windows10CustomConfiguration'
  roleScopeTagIds                             = @('0')
  deviceManagementApplicabilityRuleOsEdition  = $null
  deviceManagementApplicabilityRuleOsVersion  = $null
  deviceManagementApplicabilityRuleDeviceMode = $null
  description                                 = $null
  displayName                                 = $ApplockerPolicyName
  omaSettings                                 = @()
}

# Select only the EXE RuleCollection and convert it to XML
$exeRuleCollection = $applockerConfig.AppLockerPolicy.RuleCollection | Where-Object { $_.Type -eq "EXE" }

Write-Output "Starting to process the AppLocker XML file for EXE RuleCollection."

If ($exeRuleCollection.Count -eq 0) {
  Write-Output "No EXE RuleCollection found in the provided AppLocker XML file, moving on to MSI RuleCollection."

}
else {

  Write-Output "Found EXE RuleCollection in the provided AppLocker XML file, proceeding to extract it."
  # Create a new XML document with only the selected part
  $selectedXml = New-Object System.Xml.XmlDocument
  $root = $selectedXml.CreateElement("AppLockerPolicy")
  $selectedXml.AppendChild($root) | Out-Null

  foreach ($rule in $exeRuleCollection) {
    $importedNode = $selectedXml.ImportNode($rule, $true)
    $root.AppendChild($importedNode) | Out-Null
  }

  Write-Output "Constructing EXE PS Object for Graph API."

  $applockerPolicyObject.omaSettings += [PSCustomObject]@{
    description            = $null
    omaUri                 = './Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/EXE/Policy'
    displayName            = 'EXE'
    '@odata.type'          = '#microsoft.graph.omaSettingString'
    isEncrypted            = $false
    secretReferenceValueId = $null
    value                  = $selectedXml.AppLockerPolicy.RuleCollection.OuterXml
  }
}

# Select only the MSI RuleCollection and convert it to XML
$msiRuleCollection = $applockerConfig.AppLockerPolicy.RuleCollection | Where-Object { $_.Type -eq "MSI" }
if ($msiRuleCollection.Count -eq 0) {
  Write-Output "No MSI RuleCollection found in the provided AppLocker XML file, moving on to Script RuleCollection."
}
else {
  Write-Output "Found MSI RuleCollection in the provided AppLocker XML file, proceeding to extract it."
  # Create a new XML document with only the selected part
  $selectedXmlMsi = New-Object System.Xml.XmlDocument
  $rootMsi = $selectedXmlMsi.CreateElement("AppLockerPolicy")
  $selectedXmlMsi.AppendChild($rootMsi) | Out-Null

  foreach ($rule in $msiRuleCollection) {
    $importedNode = $selectedXmlMsi.ImportNode($rule, $true)
    $rootMsi.AppendChild($importedNode) | Out-Null
  }

  Write-Output "Constructing MSI PS Object for Graph API."

  $applockerPolicyObject.omaSettings += [PSCustomObject]@{
    description            = $null
    omaUri                 = './Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/MSI/Policy'
    displayName            = 'MSI'
    '@odata.type'          = '#microsoft.graph.omaSettingString'
    isEncrypted            = $false
    secretReferenceValueId = $null
    value                  = $selectedXml.AppLockerPolicy.RuleCollection.OuterXml
  }
}

# Select only the Script RuleCollection and convert it to XML
$scriptRuleCollection = $applockerConfig.AppLockerPolicy.RuleCollection | Where-Object { $_.Type -eq "Script" }
if ($scriptRuleCollection.Count -eq 0) {
  Write-Output "No Script RuleCollection found in the provided AppLocker XML file, moving on to DLL RuleCollection."
}
else {
  Write-Output "Found Script RuleCollection in the provided AppLocker XML file, proceeding to extract it."
  # Create a new XML document with only the selected part
  $selectedXmlScript = New-Object System.Xml.XmlDocument
  $rootScript = $selectedXmlScript.CreateElement("AppLockerPolicy")
  $selectedXmlScript.AppendChild($rootScript) | Out-Null

  foreach ($rule in $scriptRuleCollection) {
    $importedNode = $selectedXmlScript.ImportNode($rule, $true)
    $rootScript.AppendChild($importedNode) | Out-Null
  }

  Write-Output "Constructing Script PS Object for Graph API."
  $applockerPolicyObject.omaSettings += [PSCustomObject]@{
    description            = $null
    omaUri                 = './Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/Script/Policy'
    displayName            = 'Script'
    '@odata.type'          = '#microsoft.graph.omaSettingString'
    isEncrypted            = $false
    secretReferenceValueId = $null
    value                  = $selectedXml.AppLockerPolicy.RuleCollection.OuterXml
  }

}

# Select only the DLL RuleCollection and convert it to XML
$dllRuleCollection = $applockerConfig.AppLockerPolicy.RuleCollection | Where-Object { $_.Type -eq "DLL" }
if ($dllRuleCollection.Count -eq 0) {
  Write-Output "No DLL RuleCollection found in the provided AppLocker XML file, moving on to Appx RuleCollection."
}
else {
  Write-Output "Found DLL RuleCollection in the provided AppLocker XML file, proceeding to extract it."
  # Create a new XML document with only the selected part
  $selectedXmlDll = New-Object System.Xml.XmlDocument
  $rootDll = $selectedXmlDll.CreateElement("AppLockerPolicy")
  $selectedXmlDll.AppendChild($rootDll) | Out-Null

  foreach ($rule in $dllRuleCollection) {
    $importedNode = $selectedXmlDll.ImportNode($rule, $true)
    $rootDll.AppendChild($importedNode) | Out-Null
  }

  Write-Output "Constructing DLL JSON Object for Graph API."
  $applockerPolicyObject.omaSettings += [PSCustomObject]@{
    description            = $null
    omaUri                 = './Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/DLL/Policy'
    displayName            = 'DLL'
    '@odata.type'          = '#microsoft.graph.omaSettingString'
    isEncrypted            = $false
    secretReferenceValueId = $null
    value                  = $selectedXml.AppLockerPolicy.RuleCollection.OuterXml
  }

}

# Select only the Appx RuleCollection and convert it to XML
$appxRuleCollection = $applockerConfig.AppLockerPolicy.RuleCollection | Where-Object { $_.Type -eq "Appx" }
if ($appxRuleCollection.Count -eq 0) {
  Write-Output "No Appx RuleCollection found in the provided AppLocker XML file."
}
else {
  Write-Output "Found Appx RuleCollection in the provided AppLocker XML file, proceeding to extract it."
  # Create a new XML document with only the selected part
  $selectedXmlAppx = New-Object System.Xml.XmlDocument
  $rootAppx = $selectedXmlAppx.CreateElement("AppLockerPolicy")
  $selectedXmlAppx.AppendChild($rootAppx) | Out-Null

  foreach ($rule in $appxRuleCollection) {
    $importedNode = $selectedXmlAppx.ImportNode($rule, $true)
    $rootAppx.AppendChild($importedNode) | Out-Null
  }

  Write-Output "Constructing Appx PS Object for Graph API."
  $applockerPolicyObject.omaSettings += [PSCustomObject]@{
    description            = $null
    omaUri                 = './Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/StoreApps/Policy'
    displayName            = 'StoreApps'
    '@odata.type'          = '#microsoft.graph.omaSettingString'
    isEncrypted            = $false
    secretReferenceValueId = $null
    value                  = $selectedXml.AppLockerPolicy.RuleCollection.OuterXml
  }
}

#endregion

#region  <---------------------------- Graph API ----------------------------->

#Connect to Microsoft Graph with the required permissions

$scopes = @(
  "https://graph.microsoft.com/DeviceManagementConfiguration.ReadWrite.All",
  "https://graph.microsoft.com/DeviceManagementManagedDevices.ReadWrite.All"
)

$response = Connect-MgGraph -Scopes $scopes -NoWelcome

# Get the Access Token
$Parameters = @{
  Method     = "GET"
  URI        = "/v1.0/me"
  OutputType = "HttpResponseMessage"
}

$Response = Invoke-MgGraphRequest @Parameters
$Headers = $Response.RequestMessage.Headers
$Token = $Headers.Authorization.Parameter
$script:Authheader = @{Authorization = "Bearer $($Token)" }

# Set the URL for creating the AppLocker policy in Intune

$url = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/"


# Create the AppLocker policy in Intune

try {
  Invoke-RestMethod -Uri $url -Method Post -Headers $script:Authheader -Body ($applockerPolicyObject | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
}
catch {
  Write-Error "Failed to create AppLocker policy: $_"
}