
if (!(Test-Path C:\ProgramData\DevOpsInstallFolder)) {
    New-Item C:\ProgramData\DevOpsInstallFolder -ItemType Directory
}

if (!(Test-Path C:\ProgramData\DevOpsInstallFolder\Scripts)) {
    New-Item C:\ProgramData\DevOpsInstallFolder\Scripts -ItemType Directory
}

$ArtifactsDownloadScriptcontents = {

    


}
$ArtifactsDownloadScriptcontents = 'C:\ProgramData\DevOpsInstallFolder\Scripts\Sysprepscript.ps1'

if (!(Test-Path $ArtifactsDownloadScriptcontents)) {
    New-Item $ArtifactsDownloadScriptcontents -ItemType File

    Add-Content -Path $ArtifactsDownloadScriptcontents -Value $SysPrepScriptcontents
}

