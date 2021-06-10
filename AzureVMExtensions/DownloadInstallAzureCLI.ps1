Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi; Start-Sleep -Seconds 5; az extension add --upgrade -n azure-devops

#az config set extension.use_dynamic_install=yes_without_prompt