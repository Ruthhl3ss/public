#Fill this variable with the Winget package ID
$PackageName = "Adobe.Acrobat.Reader.64-bit"

$ResolveWingetPath = Resolve-Path  "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
if ($ResolveWingetPath){
    $WingetPath = $ResolveWingetPath[-1].Path
}

$config
cd $wingetpath

$InstalledApps = .\winget.exe winget list --id $PackageName

if ($InstalledApps) {
    Write-Host "$($PackageName) is installed"
    Exit 0
}
else {
    Write-Host "$($PackageName) not detected"
    Exit 1
}