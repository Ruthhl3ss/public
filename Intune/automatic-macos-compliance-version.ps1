[CmdletBinding()]
param (
  [Parameter(HelpMessage = 'The target operating system')]
  [string]$operatingSystem = "macOS",
  [Parameter(HelpMessage = 'The number of releases to skip')]
  [Int64]$releaseOffset = 2,
  [Parameter(mandatory = $true, HelpMessage = 'Output folder for compliance version file')]
  [string]$outputFolder
)

begin {

  #Get the latest Apple release version
  $uri = "https://gdmf.apple.com/v2/pmv"

  Write-Output "trying to get all releases from apple.com"
  try {
    $response = Invoke-RestMethod -Uri $uri -Method Get
  }
  catch {
    Write-Error "Failed to retrieve releases from Apple: $_"
  }
  Write-Output "Done."

  #Select
  $complianceVersion = $response.AssetSets.$($operatingSystem).ProductVersion | Sort-Object -Descending | Select-Object -Skip $releaseOffset -First 1

  Write-Output "Minimum compliance version will be set to $complianceVersion"

}

process {

  Write-Output "Setting the compliance version to $complianceVersion"

  #Json Body for Intune Compliance Policy
  $CompliancePolicy = @"
{
    "@odata.context": "https://graph.microsoft.com/beta/$metadata#deviceManagement/deviceCompliancePolicies/$entity",
    "@odata.type": "#microsoft.graph.macOSCompliancePolicy",
    "description": null,
    "displayName": "MacOS-Compliance-version-$complianceVersion",
    "version": 1,
    "passwordRequired": true,
    "passwordBlockSimple": true,
    "passwordExpirationDays": 6500,
    "passwordMinimumLength": 10,
    "passwordMinutesOfInactivityBeforeLock": null,
    "passwordPreviousPasswordBlockCount": null,
    "passwordMinimumCharacterSetCount": null,
    "passwordRequiredType": "deviceDefault",
    "osMinimumVersion": "$complianceVersion",
    "osMaximumVersion": null,
    "osMinimumBuildVersion": null,
    "osMaximumBuildVersion": null,
    "systemIntegrityProtectionEnabled": true,
    "deviceThreatProtectionEnabled": false,
    "deviceThreatProtectionRequiredSecurityLevel": "unavailable",
    "advancedThreatProtectionRequiredSecurityLevel": "unavailable",
    "storageRequireEncryption": true,
    "gatekeeperAllowedAppSource": "macAppStoreAndIdentifiedDevelopers",
    "firewallEnabled": true,
    "firewallBlockAllIncoming": false,
    "firewallEnableStealthMode": true
}
"@

  #Create the output folder if it does not exist
  if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
  }

  #Write the compliance version to a file
  $complianceVersionFile = Join-Path -Path $outputFolder -ChildPath "macOS-compliance-version-$complianceVersion.json"
  $CompliancePolicy | Out-File -FilePath $complianceVersionFile -Encoding utf8

  Write-Output "Compliance version file created at: $complianceVersionFile"

}

end {

}