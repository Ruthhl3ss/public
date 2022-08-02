## Variables

$PNPSiteConnection = ""
$LibrarytoUploadReport = ""
$TeamsWebhookURL = ""
$tenantid = ""
$LinktoManagedDeviceReport = ""


########################################################
# Get Windows Managed Device Part
########################################################

$Conn = Get-AutomationConnection -Name "AzureRunAsConnection"
$Cert = Get-Item "Cert:\CurrentUser\My\$($Conn.CertificateThumbprint)"
$Token = Get-MsalToken -ClientId $Conn.ApplicationId -TenantId $Conn.TenantId -ClientCertificate $Cert
$AccessToken = $Token.AccessToken

$FilePath = "C:\Temp\Windows_10-11_Intune_Devices.csv"

## Get all the managed devices in the tenant
$URL = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/"
$ManagedDevices = Invoke-RestMethod -Headers @{Authorization = "Bearer $($AccessToken)" }  -Uri $URL -Method GET

$ManagedDevices.value | Select-Object DeviceName, emailAddress, EnrolledDateTime | Export-Csv $FilePath

if (Test-path $FilePath){
	Write-Output "Export for Managed Devices Succeeded"
}

########################################################
# Add file to SharePoint Part
########################################################
# Get the service principal connection details
$spConnection = Get-AutomationConnection -Name AzureRunAsConnection
# Connect to PnPOnline
$Pnpconnection = Connect-PnPOnline -ClientId $spConnection.ApplicationID -Url $PNPSiteConnection -Tenant $tenantid -Thumbprint $spConnection.CertificateThumbprint
# Test connection
(get-pnptenantsite).count


$Values = @{"Title" = 'Windows 10-11 Intune Devices (CSV)'}
# Add the file to the General folder
$FileAddStatus = (Add-PnPFile -Folder $LibrarytoUploadReport -Path $FilePath -Connection $PnpConnection -Values $Values)

########################################################
# Teams Notification Part
########################################################

Import-Module PSTeams 
$TeamsID = $TeamsWebhookURL
$Button1 = New-TeamsButton -Name 'View Managed Devices Report' -Link $LinktoManagedDeviceReport
$Section = New-TeamsSection `
	-ActivityText "There are currently $(($ManagedDevices.value).count) managed Windows 10-11 Devices"`
    -Buttons $Button1 
Send-TeamsMessage `
    -URI $TeamsID `
    -MessageTitle 'New Report' `
    -MessageText 'Managed Devices Report voor Windows 10-11' `
    -Color DodgerBlue `
    -Sections $Section

