configuration SetPageFile
{
    
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }
    #Get LogicDisks for machine with Temporary Disks
        $LogicalDisks = Get-WmiObject Win32_LogicalDisk | Where-Object VolumeName -EQ 'Temporary Storage'

        #Set Pagefile on Temp disk if exists
        If ($LogicalDisks){
            
            Write-Host "Setting PageFile on $($LogicalDisks.DeviceID)"
            $pagefileset = Get-WmiObject win32_pagefilesetting | Where-Object{$_.caption -like "$($LogicalDisks.DeviceID)*"}
            $pagefileset.InitialSize = 6144
            $pagefileset.MaximumSize = 24576
            $pagefileset.Put() | Out-Null

        }
    }
}