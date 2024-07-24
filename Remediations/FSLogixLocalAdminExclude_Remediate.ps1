Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\FSLogixExclude_Remediate.log" -Append

$Groups = @(
    "FSLogix ODFC Exclude List"
    "FSLogix Profile Exclude List"
)

$AdminToExclude = "YourAdminUser"

foreach ($Group in $Groups){

    Write-Output "Checking group $Group"

    $Query = net localgroup $($Group)

    $Members = $Query[6..($Query.Length-3)]

    if ($Members -notcontains $AdminToExclude) {
        Write-Output "User: $AdminToExclude is not member, adding to group"
        
        net localgroup $Group $AdminToExclude /add

    }

}

Stop-Transcript