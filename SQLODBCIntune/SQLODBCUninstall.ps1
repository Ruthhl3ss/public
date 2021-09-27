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

# VC Redist Uninstallation
if (Test-Path 'C:\ProgramData\AppDeployment\SQLODBC\VC_redist.x64.exe') {
    Write-Log 'VC_redist.x64.exe File found and Uninstalling' -Level Info

    Start-Process -FilePath 'C:\ProgramData\AppDeployment\SQLODBC\VC_redist.x64.exe' -ArgumentList '/uninstall /quiet /norestart' -Wait

}
else {
    Write-Log 'VC_redist.x64.exe File not found' -Level Error
}

# SQL ODBC Driver Uninstallation
if (Test-Path 'C:\ProgramData\AppDeployment\SQLODBC\msodbcsql.msi') {
    Write-Log 'Microsoft ODBC Driver 17 File found and Uninstalling' -Level Info

    Start-Process -FilePath 'msiexec.exe' -ArgumentList '/quiet /passive /qn /uninstall C:\ProgramData\AppDeployment\SQLODBC\msodbcsql.msi' -Wait
}
else {
    Write-Log 'Microsoft ODBC Driver 17 File not found' -Level Error
}