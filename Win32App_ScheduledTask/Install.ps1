$Scriptname = "ScripttoRun.ps1" #name of the script to run in the scheduled task. Put in to root folder of this package.
$Foldername = "ScheduledTasks" #Foldername in C:\Program Files\
$ScheduledTaskUser = "SYSTEM" #This is the user that is used to run the scheduled task, default set as system
$ScheduledTaskName = "NielsKokTechExample" #name of the scheduled task
$ScheduledTime = "AtLogOn" #use "AtLogOn" or a time in format (example): 15:00 to run it at 3 pm

#Start Logging
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($ScheduledTaskName)_Install.log" -Append

switch ($ScheduledTime) {
    AtLogOn {  
        $Time = New-ScheduledTaskTrigger -AtLogOn
    }
    Default {
        $Time = New-ScheduledTaskTrigger -Once -At $ScheduledTime
    }
}

$ApplicationFolder = "C:\Program Files\$($Foldername)"

If (!(Test-Path $ApplicationFolder)) {
    New-Item -Path $ApplicationFolder -ItemType Directory
}
else {
    Write-host "Folder $($ApplicationFolder) already exists"

}
#Copying Items to ProgramData
Copy-Item -Path * -Destination $ApplicationFolder -Recurse -Force

$ScriptLocation = "$ApplicationFolder\$Scriptname"


try {

    Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue -OutVariable task

    if (!$task) {

        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -file `"$ScriptLocation`""
        Register-ScheduledTask -TaskName $ScheduledTaskName -Trigger $Time -User $ScheduledTaskUser -Action $Action -Force

    }
    else {
        Write-Output "Scheduled Task already exists."
    }

}
catch {

    Throw "Failed to install package $($Foldername)"
}

Stop-Transcript