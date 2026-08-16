<#
.SYNOPSIS
    Onboards a Windows host to Azure Arc and registers it as a hybrid (Arc-enabled) session host
    in an Azure Virtual Desktop host pool, using non-interactive Entra ID access-token authentication.

.DESCRIPTION
    Combines the former onboard-hosts-to-arc.ps1 and onboard-hosts-to-avd.ps1 scripts into a single,
    parameterized, non-interactive onboarding flow:

      1. Downloads and installs the Azure Connected Machine agent (if not already installed) and runs
         'azcmagent connect' to Arc-enable this host, authenticating with an Entra ID access token
         (azcmagent's '--access-token' auth mode) instead of a service principal secret or interactive
         login.
      2. Waits for the resulting Microsoft.HybridCompute/machines resource to appear in Azure.
      3. Authenticates to Az PowerShell with the same access token (Connect-AzAccount -AccessToken),
         generates a short-lived AVD host pool registration token (New-AzWvdRegistrationInfo), and
         installs the AVD extension (New-AzConnectedMachineExtension) on the now Arc-enabled machine,
         which joins it to the host pool as a session host.

    All values that were previously hardcoded or read from $env: variables in the source scripts are
    now parameters. Where both source scripts had an equivalent setting (subscription, resource group,
    region), the parameters were unified or given non-conflicting names — see PARAMETERS below.

    Before connecting, the script checks that Az.Accounts, Az.DesktopVirtualization, and
    Az.ConnectedMachine are installed, installing (CurrentUser scope, from PSGallery) and importing
    any that are missing.

.PARAMETER AccessToken
    Entra ID access token for the Azure Resource Manager resource (https://management.azure.com/),
    belonging to a principal with rights to onboard Arc machines and manage the target AVD host pool.
    Used both for 'azcmagent connect --access-token' and for 'Connect-AzAccount -AccessToken'.

    Access tokens are short-lived (typically ~60-90 minutes) - request one immediately before running
    this script. To obtain one:

        # Az.Accounts >= 5.0.0 / Az >= 14.0.0 (Get-AzAccessToken returns a SecureString by default)
        $secureToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
        $accessToken = ConvertFrom-SecureString -SecureString $secureToken -AsPlainText

        # Older Az.Accounts versions (plain-text Token property)
        $accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token

    Or acquire one for a service principal via client-credentials flow (e.g. with MSAL.PS or
    'az account get-access-token' after 'az login --service-principal').

.PARAMETER AccountId
    The identity that AccessToken belongs to: the object ID, UPN, or application (client) ID of the
    signed-in user or service principal. Required by 'Connect-AzAccount -AccessToken' to populate the
    resulting Azure context.

.PARAMETER TenantId
    Entra ID tenant ID that owns the subscription, host pool, and target Arc machine resource.

.PARAMETER SubscriptionId
    Subscription ID containing the host pool and the resource group the Arc machine will be created in.

.PARAMETER HostPoolResourceGroupName
    Resource group containing the AVD host pool (HostPoolName).

.PARAMETER ArcResourceGroupName
    Resource group the Arc-enabled server (Microsoft.HybridCompute/machines) resource will be created
    in. Defaults to HostPoolResourceGroupName if not specified, matching the source scripts where both
    groups were the same resource group.

.PARAMETER HostPoolName
    Name of the AVD host pool to register this host with.

.PARAMETER ArcMachineName
    Name to register the Arc machine resource under. Defaults to the local computer name.

.PARAMETER Location
    Azure region for both the Arc connectivity check and the Arc machine resource (e.g. "westeurope").

.PARAMETER Cloud
    Azure cloud instance to onboard the Arc agent to. One of AzureCloud, AzureUSGovernment,
    AzureChinaCloud. Defaults to AzureCloud.

.PARAMETER CorrelationId
    Optional GUID identifying the onboarding mechanism, used only for Microsoft telemetry purposes
    (see 'azcmagent connect --correlation-id'). Omitted from the connect command if not supplied.

.PARAMETER RegistrationTokenValidityHours
    How many hours the generated AVD host pool registration token remains valid for. Defaults to 24.

.PARAMETER ExtensionType
    Type of the Arc extension to install for AVD registration. Defaults to "CloudDeviceExtension".

.PARAMETER ExtensionPublisher
    Publisher of the Arc extension to install. Defaults to "Microsoft.AzureVirtualDesktop".

.PARAMETER ExtensionName
    Name to give the installed Arc extension resource. Defaults to "AzureVirtualDesktop".

.PARAMETER EnableAutomaticUpgrade
    Whether the Arc agent should automatically upgrade itself when a new version is available.
    Defaults to $true (matching the source script, which always passed --enable-automatic-upgrade).
    Pass -EnableAutomaticUpgrade:$false to disable.

.PARAMETER ArcConnectionTimeoutSeconds
    How long to wait for the Arc machine resource to appear in Azure after 'azcmagent connect'
    succeeds locally, before giving up. Defaults to 300 seconds.

.PARAMETER ArcConnectionPollIntervalSeconds
    How often to poll for the Arc machine resource while waiting. Defaults to 15 seconds.

.EXAMPLE
    $secureToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
    $accessToken = ConvertFrom-SecureString -SecureString $secureToken -AsPlainText

    .\automated-ah-onboarding.ps1 `
        -AccessToken "string" `
        -AccountId "string" `
        -TenantId "string" `
        -SubscriptionId "string" `
        -HostPoolResourceGroupName "string" `
        -HostPoolName "string" `
        -Location "string"

    Onboards the local machine using a token obtained from the caller's own Az context, letting
    ArcResourceGroupName default to the value of "HostPoolResourceGroupName" and ArcMachineName default to $env:COMPUTERNAME.

.EXAMPLE
    .\automated-ah-onboarding.ps1 `
        -AccessToken $accessToken `
        -AccountId $servicePrincipalAppId `
        -TenantId $tenantId `
        -SubscriptionId $subscriptionId `
        -HostPoolResourceGroupName "string" `
        -ArcResourceGroupName "string" `
        -HostPoolName "string" `
        -ArcMachineName "string" `
        -Location "string" `
        -Cloud "AzureCloud" `
        -CorrelationId "42520a22-fba5-434a-ae59-b79967e49927" `
        -EnableAutomaticUpgrade:$false

    Onboards a remote-named host into a separate Arc resource group, with automatic agent upgrades
    disabled and a correlation ID attached for telemetry.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$AccessToken,

  [Parameter(Mandatory)]
  [string]$AccountId,

  [Parameter(Mandatory)]
  [string]$TenantId,

  [Parameter(Mandatory)]
  [string]$SubscriptionId,

  [Parameter(Mandatory)]
  [string]$HostPoolResourceGroupName,

  [string]$ArcResourceGroupName,

  [Parameter(Mandatory)]
  [string]$HostPoolName,

  [string]$ArcMachineName = $env:COMPUTERNAME,

  [Parameter(Mandatory)]
  [string]$Location,

  [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureChinaCloud')]
  [string]$Cloud = 'AzureCloud',

  [string]$CorrelationId,

  [int]$RegistrationTokenValidityHours = 24,

  [string]$ExtensionType = 'CloudDeviceExtension',

  [string]$ExtensionPublisher = 'Microsoft.AzureVirtualDesktop',

  [string]$ExtensionName = 'AzureVirtualDesktop',

  [switch]$EnableAutomaticUpgrade = $true,

  [int]$ArcConnectionTimeoutSeconds = 300,

  [int]$ArcConnectionPollIntervalSeconds = 15
)

if (-not $ArcResourceGroupName) {
  $ArcResourceGroupName = $HostPoolResourceGroupName
}
#Set the ExecutionPolicy to bypass to make sure the script may run
Set-ExecutionPolicy ByPass

# --- Step 0: ensure required Az modules are installed and imported ---
$modules = @('Az.Accounts', 'Az.DesktopVirtualization', 'Az.ConnectedMachine')
foreach ($m in $modules) {
  if (-not (Get-Module -ListAvailable -Name $m)) {
    Install-Module $m -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
  }
  Import-Module $m -ErrorAction Stop
}

try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

  # --- Step 1: install the Azure Connected Machine agent ---
  $azcmagentPath = Join-Path $env:SystemRoot 'AzureConnectedMachineAgent'
  if (-not (Test-Path -Path $azcmagentPath)) {
    New-Item -Path $azcmagentPath -ItemType Directory | Out-Null
    Write-Output "Directory '$azcmagentPath' created"
  }

  $tempPath = Join-Path $azcmagentPath 'temp'
  if (-not (Test-Path -Path $tempPath)) {
    New-Item -Path $tempPath -ItemType Directory | Out-Null
    Write-Output "Directory '$tempPath' created"
  }

  $installerPath = Join-Path $tempPath 'AzureConnectedMachineAgent.msi'
  $installLogPath = Join-Path $tempPath 'installationlog.txt'

  # Download the installer directly, bypassing the gbl.his.arc.azure.com bootstrap script (its
  # geo-redirect returns 400 Bad Request when run inside a PSSession/WinRM host process, which
  # doesn't pick up the same proxy/WPAD context as an interactive session)
  Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/AzureConnectedMachineAgent' -TimeoutSec 60 -OutFile $installerPath

  $msiArgs = @('/i', "`"$installerPath`"", '/qn', '/l*v', "`"$installLogPath`"")
  $installProcess = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
  if ($installProcess.ExitCode -ne 0) {
    throw "AzureConnectedMachineAgent installation failed with exit code $($installProcess.ExitCode). See '$installLogPath' for details."
  }
  Start-Sleep -Seconds 5

  # --- Step 2: connect the agent to Azure Arc, authenticating with the access token ---
  $azcmagentArgs = @(
    'connect'
    '--access-token', $AccessToken
    '--tenant-id', $TenantId
    '--subscription-id', $SubscriptionId
    '--resource-group', $ArcResourceGroupName
    '--location', $Location
    '--cloud', $Cloud
  )
  if ($EnableAutomaticUpgrade) {
    $azcmagentArgs += '--enable-automatic-upgrade'
  }
  if ($CorrelationId) {
    $azcmagentArgs += '--correlation-id', $CorrelationId
  }

  $azcmagentExe = Join-Path $env:ProgramW6432 'AzureConnectedMachineAgent\azcmagent.exe'
  & $azcmagentExe @azcmagentArgs
  if ($LASTEXITCODE -ne 0) {
    throw "azcmagent connect failed with exit code $LASTEXITCODE."
  }

  # --- Step 3: authenticate Az PowerShell with the same access token ---
  Connect-AzAccount -AccessToken $AccessToken -AccountId $AccountId -Tenant $TenantId -ErrorAction Stop | Out-Null
  Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null

  # --- Step 4: wait for the Arc machine resource to appear before installing the AVD extension ---
  $deadline = (Get-Date).AddSeconds($ArcConnectionTimeoutSeconds)
  $connectedMachine = $null
  do {
    $connectedMachine = Get-AzConnectedMachine -ResourceGroupName $ArcResourceGroupName -Name $ArcMachineName -ErrorAction SilentlyContinue
    if (-not $connectedMachine -or $connectedMachine.Status -ne 'Connected') {
      Start-Sleep -Seconds $ArcConnectionPollIntervalSeconds
      $connectedMachine = $null
    }
  } while (-not $connectedMachine -and (Get-Date) -lt $deadline)

  if (-not $connectedMachine) {
    throw "Timed out after $ArcConnectionTimeoutSeconds seconds waiting for Arc machine '$ArcMachineName' in resource group '$ArcResourceGroupName' to reach status 'Connected'."
  }

  # --- Step 5: generate an AVD host pool registration token ---
  $expiresUtc = (Get-Date).ToUniversalTime().AddHours($RegistrationTokenValidityHours).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
  $regInfo = New-AzWvdRegistrationInfo -ResourceGroupName $HostPoolResourceGroupName -HostPoolName $HostPoolName -ExpirationTime $expiresUtc -ErrorAction Stop
  $registrationToken = $regInfo.Token

  # --- Step 6: install the AVD extension on the Arc machine to complete session host registration ---
  $settings = @{ isCloudDevice = $false }
  $protectedSettings = @{ registrationToken = $registrationToken }

  New-AzConnectedMachineExtension `
    -Name $ExtensionName `
    -ResourceGroupName $ArcResourceGroupName `
    -MachineName $ArcMachineName `
    -Location $Location `
    -Publisher $ExtensionPublisher `
    -ExtensionType $ExtensionType `
    -Setting $settings `
    -ProtectedSetting $protectedSettings `
    -ErrorAction Stop

  Write-Output "Host '$ArcMachineName' onboarded to Azure Arc and registered to AVD host pool '$HostPoolName'."
}
catch {
  $logBody = @{
    subscriptionId = $SubscriptionId
    resourceGroup  = $ArcResourceGroupName
    tenantId       = $TenantId
    location       = $Location
    correlationId  = $CorrelationId
    authType       = 'accessToken'
    operation      = 'onboarding'
    messageType    = $_.FullyQualifiedErrorId
    message        = "$_"
  }
  try {
    Invoke-WebRequest -UseBasicParsing -Uri 'https://gbl.his.arc.azure.com/log' -Method 'PUT' -Body ($logBody | ConvertTo-Json) | Out-Null
  }
  catch {
    # Best-effort telemetry only - ignore failures logging the failure.
  }
  Write-Host -ForegroundColor Red $_.Exception
  exit 1
}
