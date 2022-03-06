#### Parameters edit these yourself:
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $TenantId = "Tenantnaam.onmicrosoft.com",
    [Parameter()]
    [string]
    $ClientID = "Client ID from your app registration",
    [Parameter()]
    [string]
    $StorageAccountName = "intunebackupnkotech",
    [Parameter()]
    [string]
    $RGName = "RG_WE_StorageAccounts",
    [Parameter()]
    [string]
    $ContainerName = "backup",
	[Parameter()]
    [string]
    $fromAddress = "Intune@lab.nielskok.tech",
	[Parameter()]
    [string]
    $toAddress = "niels@nielskok.tech"
)

$ClientSecret = Get-AutomationVariable -Name secret

###########################################################################
## DOWNLOAD BACKUP SECTION
###########################################################################
## Importing Modules
#Importing Modules
$Module_Name = "IntuneBackupAndRestore"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Microsoft.Graph.Intune"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Az.Accounts"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Az.Storage"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

Write-Host "Logging on to Azure with Az Account"
$Secret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientID, $Secret
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

#StorageContext
$StorageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $RGName -AccountName $StorageAccountName
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey.Value[0]
$ListBlobs = Get-AzStorageBlob -context $Ctx -Container $containerName

#Destination folder - change if different
$DestinationRootFolder = "C:\temp\IntuneBackup\"

#Create destination folder if it doesn't exist
If(!(test-path $DestinationRootFolder))
{
      New-Item -ItemType Directory -Force -Path $DestinationRootFolder
}

#Loop through the files in a container
foreach($bl in $ListBlobs)
{
       
    $BlobFullPath = $bl.Name
    #Get blob folder path
    $SourceFolder = $BlobFullPath.Substring( 0, $BlobFullPath.LastIndexOf("/")+1)
    #Build destination path based on blob path
    $DestinationFolder = ($DestinationRootFolder + $SourceFolder.Replace("/","\") ).Replace("\\","\")
    #Create local folders
    $NewFolder = New-Item -ItemType Directory -Force -Path $DestinationFolder
    $DestinationFilePath = $DestinationRootFolder + $BlobFullPath.Replace("/", "\")
    #Download file
    Get-AzStorageBlobContent -Container $containerName -Blob $BlobFullPath -Destination $DestinationFilePath -Context $Ctx -Force -AsJob
}

Write-Host ("Download completed...")

### Select folders
$SelectLatestFolders = Get-ChildItem -Path $DestinationRootFolder | Select-Object -Last 2

#First Backup
$OldPath = ($SelectLatestFolders | Select-Object -First 1).FullName
Write-Host "The reference (Old Backup) is path $($OldPath)"

#Seond Backup
$LatestPath = ($SelectLatestFolders | Select-Object -Last 1).FullName
Write-Host "The latest backup is path $($LatestPath)"


$Compare = Compare-IntuneBackupDirectories -ReferenceDirectory $OldPath -DifferenceDirectory $LatestPath
$Compare
###########################################################################
## SEND MAIL SECTION
###########################################################################

# Variables
# Authentication
$ApplicationID = $ClientID
$TenantDomainName = $TenantId
$AccessSecret = Get-AutomationVariable -Name secret

$Body = $Compare | Out-String
# The mail subject and it's message
$mailSubject = 'Intune Backup Change'
$Emailbody = @"

This are the changes in Intune:

"$($Body)"

"@



### Authenticate to Microsoft Graph
$Body = @{    
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
} 

$ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token" `
-Method POST -Body $Body

$token = $ConnectGraph.access_token

# Send Mail via Grpah
$params = @{
  "URI"         = "https://graph.microsoft.com/v1.0/users/$fromAddress/sendMail"
  "Headers"     = @{
    "Authorization" = ("Bearer {0}" -F $token)
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
            "address" = $toAddress
          }
        }
      )
    }
  }) | ConvertTo-JSON -Depth 10
}

Write-Output -Message 'Sending mail via Graph...'
Invoke-RestMethod @params -Verbose

Write-Output -Message 'All Done!'