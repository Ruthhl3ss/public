###############################################
############### Connect to Graph ##############
###############################################

Import-Module MSAL.PS


# Token voor Configuration Profiles, Update Policies
$authResult = Get-MsalToken -ClientId d1ddf0e4-d672-4dae-b554-9d5bdfd93547 -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Interactive
$AuthHeaders = @{
          'Content-Type'='application/json'
          'Authorization'="Bearer " + $authResult.AccessToken
          'ExpiresOn'=$authResult.ExpiresOn
         
}

###############################################
############## Import Policy ##################
###############################################

#Policy File
$PolicyFile = "E:\GIT\Demo\Settings Catalog\Windows 10 - Disable News Interests.json"

$Content = Get-Content -LiteralPath $PolicyFile

#$requestBody = $Content | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, settingCount, creationSource | ConvertTo-Json -Depth 100

$JSON_Convert = $Content | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, settingCount, creationSource 
$JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5


#Create Policy
$graphApiVersion = "Beta"
$Resource = "deviceManagement/configurationPolicies"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/"
Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Post -Body $JSON_Output -ContentType "application/json"

###############################################
############## Assign Policy ##################
###############################################

$AssignBodyJSONPath = "E:\GIT\Demo\Settings Catalog\Assignments\Windows 10 - Disable News Interests.json"

$configurationPolicyAssignments = Get-Content -LiteralPath $AssignBodyJSONPath | ConvertFrom-Json

# Create the base requestBody
$requestBody = @{
    assignments = @()
}
# Add assignments to restore to the request body
foreach ($configurationPolicyAssignment in $configurationPolicyAssignments) {
    $requestBody.assignments += @{
        "target" = $configurationPolicyAssignment.target
    }
}

# Convert the PowerShell object to JSON
$requestBody = $requestBody | ConvertTo-Json -Depth 100

# Get the Configuration Policy we are restoring the assignments for
$graphApiVersion = "Beta"
$Resource = "deviceManagement/configurationPolicies"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
$configurationPolicyObject = (Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Get).value | Where-Object name -eq "$($JSON_Convert.Name)"

#Assign Policy
$graphApiVersion = "Beta"
$Resource = "deviceManagement/configurationPolicies"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$($configurationPolicyObject.id)/assign"
Invoke-RestMethod -Uri $uri -Headers $AuthHeaders -Method Post -Body $requestBody -ContentType "application/json"