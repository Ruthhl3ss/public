#Function to perform Graph API requestss
function Invoke-APIRequest {
    param (
        [Parameter()][string]$uri,
        [Parameter()][string]$Token,
        [Parameter()][string]$Method = 'Get'
    )
    #Perform initial Graph Request
    $Headers = @{Authorization = "Bearer $($Token)" }

    $params = @{
        uri     = $uri
        Method  = $Method
        Headers = $Headers
    }

    $result = Invoke-RestMethod @params

    #Check if the result is null
    if ($null -eq $result) {
        Write-Error "No results returned exiting function"
        break
    }
    $AllPages = $result.value

    #Loop through the API pages if there is a next link
    $NextLink = $result."@odata.nextLink"

    while ($null -ne $NextLink) {

        $result = (Invoke-RestMethod -Uri $NextLink -Headers $Headers -Method Get)
        $NextLink = $result."@odata.nextLink"
        $AllPages += $result.value
    }

    return $AllPages
}

Connect-AzAccount

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$Token = (Get-AzAccessToken -ResourceTypeName MSGraph).token

#Get All Applications
$Applicationsparams = @{
    Token = $Token
    uri   = "https://graph.microsoft.com/beta/applications"
}
$Applications = Invoke-APIRequest @Applicationsparams

#Initialize array
$Permissionstable = @()

#Get APIPermissions (Quick & Dirty solution by grabbing a CSV file from my Github)
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Ruthhl3ss/public/main/AppRoles/APIPermissions.csv' -OutFile APIPermissions.csv

$APIPermissions = Import-csv -Path APIPermissions.csv

foreach ($Application in $Applications) {

    Write-Output "Examining Application: $($Application.displayName) "

    foreach ($permission in $Application.requiredResourceAccess.resourceAccess) {

        $APIPermissions | ForEach-Object {
            if ($permission.id -eq $_.id) {
                Write-Output "Application $($Application.displayName) has role: $($_.value)"
                
                $row = new-object PSObject -Property @{
                    ApplicationName = $($Application.displayName);
                    RoleName        = $($_.value)
                }

                $Permissionstable += $row
            }
        }
    }
}

$Permissionstable | Export-Csv -Path ExportedAPIPermissions.csv -NoTypeInformation

# OutGrid View option:
# $Permissionstable | Out-GridView