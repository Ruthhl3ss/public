#Fill this variable with the Winget package ID
$PackageName = "Adobe.Acrobat.Reader.64-bit"

$InstalledApps = winget list --id $PackageName

if ($InstalledApps) {
    Write-Host "$($PackageName) is installed"
    Exit 0
}
else {
    Write-Host "$($PackageName) not detected"
    Exit 1
}