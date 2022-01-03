## Parameters

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ImagergName,
    [Parameter()]
    [string]
    $SharedImageGalleryName,
    [Parameter()]
    [string]
    $SharedImageGalleryRG,
    [Parameter()]
    [string]
    $SharedImageGalleryDefinitionName,
    [Parameter()]
    [string]
    $SPNAPPID,
    [Parameter()]
    [string]
    $SPNSecret,
    [Parameter()]
    [string]
    $SubscriptionID,
    [Parameter()]
    [string]
    $AzureTenantID
)
#Connect to Azure and the proper subscription

$secret = ConvertTo-SecureString -String $SPNSecret -AsPlainText -Force
$username = $SPNAPPID

Write-Host("setting up credential")

$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $username, $secret 

Connect-AzAccount -Credential $Credential -Tenant $AzureTenantID -ServicePrincipal

Start-Sleep 5

Select-AzSubscription -SubscriptionId $SubscriptionID

## Gather Managed Image From Resource Group
$imageName = Get-AzResource -ResourceGroupName $ImagergName | Where-Object ResourceType -EQ Microsoft.Compute/images

## Split Managed Image Name to version name, Example: Split: Windows10_20210901.3 to 20210901.3

$InputString = $imageName.Name
$ImageNameArray = $InputString.Split("_")
$GalleryImageVersionName = "1."+$ImageNameArray[1]

## Variables

$location = 'West Europe'
$ImageEndOfLifeDate = (Get-Date).AddDays(30)

## Get Image info

$managedImage = Get-AzImage `
   -ImageName $imageName.Name `
   -ResourceGroupName $ImagergName

## Get Image Definition Info

$ImageDefinition = Get-AzGalleryImageDefinition `
    -ResourceGroupName $SharedImageGalleryRG `
    -GalleryName $SharedImageGalleryName `
    -GalleryImageDefinitionName $SharedImageGalleryDefinitionName

## Create Upload Job

$region1 = @{Name='West Europe';ReplicaCount=2}
$targetRegions = @($region1)
$job = New-AzGalleryImageVersion `
      -GalleryImageDefinitionName $imageDefinition.Name `
      -GalleryImageVersionName $GalleryImageVersionName `
      -GalleryName $SharedImageGalleryName `
      -ResourceGroupName $imageDefinition.ResourceGroupName `
      -Location $location `
      -TargetRegion $targetRegions  `
      -SourceImageId $managedImage.Id.ToString() `
      -PublishingProfileEndOfLifeDate $ImageEndOfLifeDate `
      -asJob

## Wait for upload to complete
$Count = 1

do {
    #Starting Count
    $Count
    $Count++

    Write-Host "Shared Image Gallery Upload not yet completed, Starting Sleep for 60 Seconds"
    Start-Sleep 60

    if ($Count -ge 75) { 
        Write-Host "Shared Image Gallery Upload FAILED"
        Break
    }
} while ($job.State -eq "Running")

if ($job.State -eq "Completed") {
    Write-Host "Shared Image Gallery Upload completed"

    ## Remove ResourceGroup with Managed Image

    Write-Host "Removing Managed Image + Resourcegroup"

    Remove-AzResource -ResourceId $imageName.ResourceId -Force

    Remove-AzResourceGroup -Name $ImagergName -Force
}