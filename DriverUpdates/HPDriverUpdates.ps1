Start-Transcript -Path C:\Windows\Temp\HPIA.log

Install-PackageProvider -name NuGet -force

Install-Module -Name PowershellGet -Force

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

$ImageAssistant = Get-Childitem -Path C:\Windows\Temp\HPIA -Recurse | Where-Object name -Like "HPImageAssistant.exe*"

Start-Process -FilePath $($ImageAssistant.fullname) -ArgumentList "/Operation:Analyze /Action:Install /Selection:All /Silent /Category:Drivers,Software /ReportFolder:'C:\Windows\Temp' /SoftpaqDownloadFolder:$($UpdatePath)"

Stop-Transcript