
if (!(Test-Path C:\ProgramData\DevOpsInstallFolder)) {
    New-Item C:\ProgramData\DevOpsInstallFolder -ItemType Directory
}

if (!(Test-Path C:\ProgramData\DevOpsInstallFolder\Scripts)) {
    New-Item C:\ProgramData\DevOpsInstallFolder\Scripts -ItemType Directory
}

$SysPrepScriptcontents = {

    if( Test-Path C:\windows\system32\Sysprep\unattend.xml ){ Remove-Item C:\windows\system32\Sysprep\unattend.xml -Force}
        C:\Windows\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /quit;
        while($true) { $imageState = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State | Select-Object ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }
}
$Sysprepscriptpath = 'C:\ProgramData\DevOpsInstallFolder\Scripts\Sysprepscript.ps1'

if (!(Test-Path $Sysprepscriptpath)) {
    New-Item $Sysprepscriptpath -ItemType File

    Add-Content -Path $Sysprepscriptpath -Value $SysPrepScriptcontents
}

