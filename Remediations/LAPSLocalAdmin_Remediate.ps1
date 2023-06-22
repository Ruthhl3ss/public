Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\LAPSLocalAdmin_Remediate.log" -Append

$LAPSAdmin = "Username"

$Query = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True"

If ($Query.Name -notcontains $LAPSAdmin) {

    Write-Output "User: $LAPSAdmin does not existing on the device, creating user"
    
    try {
        Net User /Add $LAPSAdmin
        Write-Output "Added Local User $LAPSAdmin"

        net localgroup administrators $LAPSAdmin /add
        Write-Output "Added Local User $LAPSAdmin to Administrators"
        Exit 0

    }
    catch {
        Write-Error "Couldn't create user"
        Exit 1
    }

}
Else {
    Write-Output "User $LAPSAdmin exists on the device"
    Exit 0
}

Stop-Transcript