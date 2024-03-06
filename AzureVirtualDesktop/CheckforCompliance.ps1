
[CmdletBinding()]
param (
    [Parameter()][string]$DeviceNames,
    [Parameter()][string]$Hostpoolname,
    [Parameter()][string]$ResourceGroupName

)

$Devices = $DeviceNames -split ","
# Disable new sessions for all devices in the hostpool
$Devices | ForEach-Object -Parallel {
    
    $Result = Update-AzWvdSessionHost -HostPoolName $($using:Hostpoolname) -ResourceGroupName $($using:ResourceGroupName) -Name $_ -AllowNewSession:$false
    Write-Output "Set AllowNewSessions to $($Result.AllowNewSession) for device $_"
    
} -ThrottleLimit 10

# Get the token for the MSGraph API
$Aztoken = (Get-AzAccessToken -ResourceTypeName MSGraph).token
# Create the header for the MSGraph API
$Authheader = @{Authorization = "Bearer $($Aztoken)" }

# Check if the device is compliant and allow new sessions if it is
$Devices | ForEach-Object -Parallel {

    Do {
        $url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceName+eq+'$($_)'"

        $ComplianceState = (Invoke-RestMethod -Uri $url -Headers $($using:Authheader) -Method Get).value.complianceState

        Start-Sleep -Seconds 15

        Write-Output "Device $_ is not compliant, state is $ComplianceState"
    }

    while ($ComplianceState -ne "Compliant")

    Write-Output "Device $_ is compliant, allowing new session, state is $ComplianceState"

    $Result = Update-AzWvdSessionHost -HostPoolName $($using:Hostpoolname) -ResourceGroupName $($using:ResourceGroupName) -Name $_ -AllowNewSession:$true
    Write-Output "Set AllowNewSessions to $($Result.AllowNewSession) for device $_"

} -ThrottleLimit 10