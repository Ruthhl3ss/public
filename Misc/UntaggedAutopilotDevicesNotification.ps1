#Connect to Az Account with the Managed Identity
Connect-AzAccount -Identity

#Extract the access token from the AzAccount authentication context and use it to connect to Microsoft Graph
$Aztoken = (Get-AzAccessToken -ResourceTypeName MSGraph).token
$Authheader = @{Authorization = "Bearer $($Aztoken)"}

# Get all autopilot devices
$URL = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities"
$DevicesResponse = Invoke-RestMethod -Method GET -uri $URL -Headers $Authheader

#Looping through MS Graph pages if more then a 100 results
$Devices = $DevicesResponse.value

$DevicesNextLink = $DevicesResponse."@odata.nextLink"

while ($DevicesNextLink -ne $null){

    $DevicesResponse = (Invoke-RestMethod -Uri $DevicesNextLink -Headers $Authheader -Method Get)
    $DevicesNextLink = $DevicesResponse."@odata.nextLink"
    $Devices += $DevicesResponse.value

}

# Set the group tags you want to check for
$Grouptags = @(
    "Personal"
    "Shared"
    "Kiosk"
)
# mail addresses
$fromAddress = ""
$toAddress = ""

# Create a list to store the untagged devices
$UntaggedDevices = New-Object System.Collections.Generic.List[System.Object]

# Loop through all autopilot devices
foreach ($device in $Devices) {
    
    if ($Grouptags -notcontains $device.groupTag) {
        Write-Output "Device $($device.serialNumber) is not tagged, adding to list"
        $UntaggedDevices.Add($device)
    }
}

If ($UntaggedDevices.count -ge 1){
    Write-Output "There are untagged autopilot devices, sending e-mail"

    ###########################################################################
    ## SEND MAIL SECTION
    ###########################################################################

    $Body = $UntaggedDevices | Select-Object -Property serialNumber, groupTag, deploymentProfileAssignmentStatus
    # The mail subject and it's message
    $mailSubject = 'Untagged Autopilot Devices'
    $Emailbody = @"

    There are untagged Autopilot devices:

    $($Body)

    Thanks,
    Nielskok.Tech Automation
"@

    foreach ($address in $toAddress){
        # Send Mail via Grpah
        $params = @{
        "URI"         = "https://graph.microsoft.com/v1.0/users/$fromAddress/sendMail"
        "Headers"     = @{
            "Authorization" = ("Bearer {0}" -F $Aztoken)
        }
        "Method"      = "POST"
        "ContentType" = 'application/json'
        "Body" = (@{
            "message" = @{
            "subject" = $mailSubject
            "body"    = @{
                "contentType" = 'Text'
                "content"     = $Emailbody
            }
            "toRecipients" = @(
                @{
                "emailAddress" = @{
                    "address" = $address
                }
                }
            )
            }
        }) | ConvertTo-JSON -Depth 10
        }
        Write-Output -Message 'Sending mail via Graph...'
        Invoke-RestMethod @params -Verbose
    }
    Write-Output -Message 'All Done!'
}
else {
    Write-Output "No Untagged Autopilot Devices found"
}