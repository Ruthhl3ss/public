$Path = "C:\Users\Public\Desktop\test.txt"

$Test = Test-Path -Path $Path -ErrorAction SilentlyContinue

If ($Test -eq $False) {
    try {
        New-Item -Path $Path -ItemType File
        Exit 0
    }
    catch {
        Write-Error $_
        Exit 1
    }
}