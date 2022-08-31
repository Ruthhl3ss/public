$Path = Get-Item "C:\Users\Public\Desktop\test.txt"

If (Test-Path -Path $Path) {
    Exit 0
    Write-Host "File exists, file doesn't need to be created"
}
else {
    Exit 1
    Write-Host "File does not exist, file needs to be created"
}