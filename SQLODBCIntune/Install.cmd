if not exist "C:\ProgramData\AppDeployment" md "C:\ProgramData\AppDeployment"
if not exist "C:\ProgramData\AppDeployment\SQLODBC" md "C:\ProgramData\AppDeployment\SQLODBC"
xcopy "msodbcsql.msi" "C:\ProgramData\AppDeployment\SQLODBC\" /Y
xcopy "VC_redist.x64.exe" "C:\ProgramData\AppDeployment\SQLODBC\" /Y
xcopy "SQLODBCInstall.ps1" "C:\ProgramData\AppDeployment\SQLODBC\" /Y
xcopy "SQLODBCUninstall.ps1" "C:\ProgramData\AppDeployment\SQLODBC\" /Y
xcopy "SQLODBCDetection.ps1" "C:\ProgramData\AppDeployment\SQLODBC\" /Y
Powershell.exe -Executionpolicy bypass -File "C:\ProgramData\AppDeployment\SQLODBC\SQLODBCInstall.ps1"

