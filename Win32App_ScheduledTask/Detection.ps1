$ScheduledTaskName = "NielsKokTechExample" #name of the scheduled task

$Task = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue -OutVariable task

If ($null -ne $Task){
    Write-Output "Scheduled Task Found"
}
else {
    Write-Output "Scheduled Task not Found"
    Exit 1
}