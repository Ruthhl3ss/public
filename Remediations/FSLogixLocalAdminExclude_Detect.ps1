Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\FSLogixExclude_Detect.log" -Append

$Groups = @(
    "FSLogix ODFC Exclude List"
    "FSLogix Profile Exclude List"
)

$AdminToExclude = "YourAdminUser"

$Count = 0

foreach ($Group in $Groups){

    Write-Output "Checking group $Group"

    $Query = net localgroup $($Group)

    $Members = $Query[6..($Query.Length-3)]

    if ($Members -notcontains $AdminToExclude) {
        Write-Output "User: $AdminToExclude is not member, adding to count"
        $Count++
    }

}

if ($Count -ge 1) {
    Write-Output "User: $AdminToExclude need to be added to the exclude groups"
    Exit 1
}
else {
    Write-Output "User: $AdminToExclude is already member of both groups"
}

Stop-Transcript