## Logging Funtion
function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\ProgramData\AppDeployment\SQLODBC\InstallationLog.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }
        else {
            # Nothing to see here yet.
            }
        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

## Create Folders
if (!(Test-Path 'C:\ProgramData\AppDeployment')) {
    New-Item -Path 'C:\ProgramData\AppDeployment' -ItemType Directory
    Write-Log 'C:\ProgramData\AppDeployment directory not found, creating directory' -Level info
}
if (!(Test-Path 'C:\ProgramData\AppDeployment\SQLODBC')) {
    New-Item -Path 'C:\ProgramData\AppDeployment\SQLODBC' -ItemType Directory
    Write-Log 'C:\ProgramData\AppDeployment directory not found, creating directory' -Level info
}

# VC Redist installation
if (Test-Path 'C:\ProgramData\AppDeployment\SQLODBC\VC_redist.x64.exe') {
    Write-Log 'VC_redist.x64.exe File found and installing' -Level Info

    C:\ProgramData\AppDeployment\SQLODBC\VC_redist.x64.exe /Q

    Start-Sleep 10

    #Check If Installation has succeeded
    $InstalledApplications = Get-WmiObject Win32_Product

    if ($InstalledApplications.IdentifyingNumber -contains '{6CD9E9ED-906D-4196-8DC3-F987D2F6615F}') {
        Write-Log 'Microsoft Visual C++ 2017 X64 Runtime installed succesfully' -Level info
    }
    Else {
        Write-Log 'Microsoft Visual C++ 2017 X64 Runtime installation not found' -Level Error
    }
}
else {
    Write-Log 'VC_redist.x64.exe File not found' -Level Error
}

# SQL ODBC Driver installation
if (Test-Path 'C:\ProgramData\AppDeployment\SQLODBC\msodbcsql.msi') {
    Write-Log 'Microsoft ODBC Driver 17 File found and installing' -Level Info

    Start-Process -FilePath 'msiexec.exe' -ArgumentList '/quiet /passive /qn /i C:\ProgramData\AppDeployment\SQLODBC\msodbcsql.msi IACCEPTMSODBCSQLLICENSETERMS=YES' -Wait

    #Check If Installation has succeeded
    $InstalledApplications = Get-WmiObject Win32_Product

    if ($InstalledApplications.identifyingNumber -contains '{7453C0F5-03D5-4412-BB8F-360574BE29AF}') {
        Write-Log 'Microsoft ODBC Driver 17 installed succesfully' -Level info
    }
    Else {
        Write-Log 'Microsoft ODBC Driver 17 installation not found' -Level Error
    }
}
else {
    Write-Log 'Microsoft ODBC Driver 17 File not found' -Level Error
}