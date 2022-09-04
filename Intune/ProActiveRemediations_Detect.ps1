$Path = Test-Path -Path "C:\Users\Public\Desktop\test.txt"

If ($Path -eq $True) {
    Write-Host "File exists, file doesn't need to be created"
    Exit 0
}
else {
    Write-Host "File does not exist, file needs to be created"
    Exit 1
}