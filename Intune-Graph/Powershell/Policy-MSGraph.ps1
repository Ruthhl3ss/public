###############################################
############### Connect to Graph ##############
###############################################

$apiVersion = "Beta"
# Second Option MSGraph
Connect-MSGraph

Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet

###############################################
############## Import Policy ##################
###############################################

$ConfigBodyJSONPath = "E:\GIT\Demo\Settings Catalog\Windows 10 - Disable News Interests.json"

$ConfigBodyJSONPathContent = Get-Content -LiteralPath $ConfigBodyJSONPath -Raw | ConvertFrom-Json

$requestBody = $requestBody = $ConfigBodyJSONPathContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, settingCount, creationSource | ConvertTo-Json -Depth 100


Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/configurationPolicies" -ErrorAction Stop
    [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "Settings Catalog"
            "Name"   = $ConfigBodyJSONPath.Fullname
            "Path"   = "Settings Catalog\$($ConfigBodyJSONPath.Name)"
    }
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
$configurationPolicyObject = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/configurationPolicies" | Get-MSGraphAllPages | Where-Object name -eq "$($ConfigBodyJSONPathContent.Name)"

# Restore the assignments
Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/configurationPolicies/$($configurationPolicyObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Settings Catalog Assignments"
                "Name"   = $configurationPolicyObject.name
                "Path"   = "Settings Catalog\Assignments\$($configurationPolicy.Name)"
}