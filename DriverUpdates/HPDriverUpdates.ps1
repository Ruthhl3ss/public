Start-Transcript -Path "C:\Windows\Temp\HPIA.log"

Install-Module -Name "HPCMSL" -Force -AcceptLicense

$HPImageAssistantExtractPath = "C:\Windows\Temp\HPIA"

If (!(Test-Path -Path $HPImageAssistantExtractPath)){
    New-Item -Path $HPImageAssistantExtractPath -ItemType Directory
}

$UpdatePath = "C:\Windows\Temp\HPIA\Updates"

If (!(Test-Path -Path $UpdatePath)){
    New-Item -Path $UpdatePath -ItemType Directory
}

Install-HPImageAssistant -Extract -DestinationPath $HPImageAssistantExtractPath -ErrorAction Stop

#$ImageAssistant = Get-Childitem -Path C:\Windows\Temp\HPIA -Recurse | Where-Object name -Like "HPImageAssistant.exe*"

C:\Windows\Temp\HPIA\HPImageAssistant.exe /Operation:Analyze /Action:Install /Selection:All /Silent /Category:Drivers,Software /ReportFolder:'C:\Windows\Temp' /SoftpaqDownloadFolder:$($UpdatePath)

$Process = Get-Process -Name HPImageAssistant -ErrorAction SilentlyContinue

Do {
    
    Write-Output "HP ImageAssistant is still running"
    Start-Sleep 30

    $Process = Get-Process -Name HPImageAssistant -ErrorAction SilentlyContinue
    
}
While ($Process -ne $null)

Stop-Transcript