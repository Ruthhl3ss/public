
# First Option Intune Backup and Restore Module
Connect-MSGraph

#Pad naar de settings catalog map
$JSONPath = "E:\GIT\Demo\"

#Importeren module
Import-Module IntuneBackupAndRestore

#Creeer een backup van de settings catalog
Invoke-IntuneBackupConfigurationPolicy -Path $JSONPath

#Creeer een backup van de assignments
Invoke-IntuneBackupConfigurationPolicyAssignment -Path $JSONPath

#Import Policy in Intune
Invoke-IntuneRestoreConfigurationPolicy -Path $JSONPath

#Assign Policy to group
Invoke-IntuneRestoreConfigurationPolicyAssignment -Path $JSONPath

