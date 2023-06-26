Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\LAPSLocalAdmin_Remediate.log" -Append

$LAPSAdmin = "Username"

$Query = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True"

If ($Query.Name -notcontains $LAPSAdmin) {

    Write-Output "User: $LAPSAdmin does not existing on the device, creating user"
    
    try {
        # Define the length of the password
        $length = 14

        # Define the characters to be used in the password
        $characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+=-"

        # Create a random password
        $password = ""
        for ($i = 1; $i -le $length; $i++) {
            $randomIndex = Get-Random -Minimum 0 -Maximum $characters.Length
            $password += $characters[$randomIndex]
        }

        Net User /Add $LAPSAdmin $password
        Write-Output "Added Local User $LAPSAdmin"

        $Group = Get-WmiObject -Query "Select * From Win32_Group Where LocalAccount = TRUE And SID = 'S-1-5-32-544'"

        $GroupName = $Group.Name

        net localgroup $GroupName $LAPSAdmin /add
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
