
############################################################################
# Start Region: Azure Virtual Desktop
############################################################################
$TenantID = ""
$ClientID = ""
$ClientSecret = Read-Host -Prompt "Enter Client Secret"
$SubscriptionID = ""
$Hostpoolname = ""
$HostpoolRG = ""
$Sessionhostrgname = ""

Write-Output "Checking for module Az.Avd...."

$InstalledModules = Get-InstalledModule
$Modules = @(
    "Az.Avd"
    "Az.DesktopVirtualization"
    "Az.Accounts"
    "Az.Resources"
)
foreach ($Module in $Modules) {
    If ($InstalledModules.name -notcontains $Module) {
        try {
            Write-Output "Installing module $Module"
            Install-Module $Module -Force
        }
        catch {
            Write-Output "Failed to install module $Module"
            Write-Error $_.Exception.Message
        }
    }
    Else {
        Write-Output "$Module Module already installed"
    }
}


Write-Output "Connecting to Azure Virtual Desktop...."

Connect-Avd -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret -SubscriptionID $SubscriptionID

Write-Output "Connected to Azure Virtual Desktop"

Write-Output "Getting Sessionhosts...."

$Sessionhosts = Get-AvdSessionHostResources -HostpoolName $Hostpoolname -ResourceGroupName $HostpoolRG

Write-Output "Got Sessionhosts"

Write-Output "Connecting to Azure...."

$SecurePassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientID, $SecurePassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

Write-Output "Connected to Azure"

foreach ($Sessionhost in $Sessionhosts) {
    #Remove Sessionhost from Hostpool
    Write-Output "Removing $($Sessionhost.VMResources.Name) from Hostpool $HostPoolName"
    Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRG -Name $Sessionhost.VMResources.Name -Force

    # Getting Resources
    $DiskResources = Get-AzVM -ResourceGroupName $Sessionhostrgname -Name $SessionHost.VMResources.Name -status
    $NicResources = Get-AzVM -ResourceGroupName $Sessionhostrgname -Name $SessionHost.VMResources.Name

    # Removing VM's
    Write-Output "Removing VM $($SessionHost.VMResources.Name) from Resource Group $($Sessionhostrgname)"
    Get-AzVM -ResourceGroupName $Sessionhostrgname -Name $SessionHost.VMResources.Name | Remove-AzVM -Force

    # Removing NICs
    $Nicname = $NicResources -split ("/")
    Write-Output "Removing NIC $($Nicname[6]) from Resource Group $($Sessionhostrgname)"
    Remove-AzResource -resourceId $NicResources.NetworkProfile.NetworkInterfaces.Id -Force
            
    # Removing disks
    Write-Output "Removing disks $($DiskResources.Disks.Name) from VM from Resource Group $($ResourceGroupName)"
    Get-AzDisk -ResourceGroupName $Sessionhostrgname -Name $DiskResources.Disks.Name | Remove-AzDisk -Force
}

############################################################################
# End Region: Azure Virtual Desktop
############################################################################

############################################################################
# Start Region: Azure AD & Intune
############################################################################

Write-Output "Connecting to Graph API...."

$body = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $ClientID
    Client_Secret = $ClientSecret
}

$connection = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token `
    -Method POST `
    -Body $body

$Token = $connection.access_token
$Headers = @{Authorization = "Bearer $($Token)" }

Write-Output "Connected to Graph API"
Write-Output ""
Write-Output "This is the token: $($Token)"
Write-Output ""

foreach ($Sessionhost in $Sessionhosts) {
    #Entra ID
    Write-Output "Trying to get device object from Entra ID for Sessionhost: $($SessionHost.VMResources.Name)"
    try {
        $params = @{
            uri     = "https://graph.microsoft.com/beta/devices?`$filter=displayName+eq+'$($SessionHost.VMResources.Name)'"
            Method  = "Get"
            Headers = $Headers
        }
    
        $Deviceobject = Invoke-RestMethod @params
    
        Write-Output "This is the Entra ID device object id : $($Deviceobject.value.id) for Sessionhost: $($SessionHost.VMResources.Name)"
    }
    catch {
        Write-Output "Failed to get device object from Entra ID"
        Write-Error $_.Exception.Message
    }

    Write-Output "Trying to remove device object from Entra ID for Sessionhost: $($SessionHost.VMResources.Name)"

    try {
        $params = @{
            uri     = "https://graph.microsoft.com/beta/devices/$($Deviceobject.value.id)"
            Method  = "Delete"
            Headers = $Headers
        }

        Invoke-RestMethod @params

        Write-Output "Removed device object from Entra ID for Sessionhost: $($SessionHost.VMResources.Name)"
    }
    catch {
        Write-Output "Failed to remove device object for sessionhost: $($SessionHost.VMResources.Name) from Entra ID"
        Write-Error $_.Exception.Message
    }

    #Intune
    Write-Output "Trying to get device object from Intune for Sessionhost: $($SessionHost.VMResources.Name)"

    try {
        $params = @{
            uri     = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=deviceName+eq+'$($SessionHost.VMResources.Name)'"
            Method  = "Get"
            Headers = $Headers
        }

        $Deviceobject = Invoke-RestMethod @params

        Write-Output "This is the Intune device object id: $($Deviceobject.value.id) for Sessionhost: $($SessionHost.VMResources.Name)"
    }
    catch {
        Write-Output "Failed to get device object for sessionhost: $($SessionHost.VMResources.Name) from Intune"
        Write-Error $_.Exception.Message
    }

    try {
        $params = @{
            uri     = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Deviceobject.value.id)"
            Method  = "Delete"
            Headers = $Headers
        }

        Invoke-RestMethod @params

        Write-Output "Removed device object from Intune for Sessionhost: $($SessionHost.VMResources.Name)"
    }
    catch {
        Write-Output "Failed to remove device object from Intune"
        Write-Error $_.Exception.Message
    }
}

############################################################################
# End Region: Azure AD & Intune
############################################################################
