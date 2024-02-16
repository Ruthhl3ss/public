$ScheduledTaskName = "NielsKokTechExample" #name of the scheduled task

$Task = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue -OutVariable task

If ($null -ne $Task){
    Write-Output "Scheduled Task Found"
    Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
}
else {
    Write-Output "Scheduled Task not Found"
    Exit 1
}