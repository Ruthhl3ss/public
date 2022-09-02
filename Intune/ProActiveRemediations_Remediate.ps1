$Path = Get-Item "C:\Users\Public\Desktop\test.txt"

If (!(Test-Path -Path $Path)) {
    try {
        New-Item -Path $Path -ItemType File
    }
    catch {
        Write-Error $_
    }
}