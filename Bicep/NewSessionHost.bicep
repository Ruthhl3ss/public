//General Variables
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

//Availability Parameters
param availabilityOption string = 'AvailabilityZone'
param availabilityZone int = 2

//SharedImageGallery Parameters
param galleryResourceGroup string = ''
param galleryName string = ''
param galleryImageDefinitionName string = ''

//SessionHostParameters
param sessionhostprefix string = 'NielsKok-'
param sessionhostinstances int = 2
param sessionhostdisktype string = 'Premium_LRS'
param sessionhostsize string = 'Standard_DS4_v2'
param enableAcceleratedNetworking bool = true
param vmInitialNumber int = 1

//Domain Join Parameters
param administratorAccountUsername string = ''
@secure()
param administratorAccountPassword string
param vmAdministratorAccountUsername string = ''
@secure()
param vmAdministratorAccountPassword string

param ouPath string = ''
param domain string = ''

//Virtual Network Properties
param vnetResourceGroup string = ''
param vnetName string = ''
param subnetName string = ''

// Location
param location string = resourceGroup().location

//HostPool parameters
param hostpoolToken string = ''
param hostpoolname string = ''


param ResourceTags object = {
  Owner: 'Nielskok.tech'
  Costcenter: 'AzureVirtualDesktop'
  Tier: 'Development'
}

var emptyArray = []
var isVMAdminAccountCredentialsProvided = ((!(vmAdministratorAccountUsername == '')) && (!(vmAdministratorAccountPassword == '')))
var vmAdministratorUsername = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountUsername : first(split(administratorAccountUsername, '@')))
var vmAdministratorPassword = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountPassword : administratorAccountPassword)
var imageReference = resourceId(galleryResourceGroup,'Microsoft.Compute/galleries/images/versions', '${galleryName}', '${galleryImageDefinitionName}','latest')
var subnetId = resourceId(vnetResourceGroup,'Microsoft.Network/virtualNetworks/subnets','${vnetName}','${subnetName}')


resource nic 'Microsoft.Network/networkInterfaces@2018-11-01' = [for i in range(0, sessionhostinstances): {
  name: '${sessionhostprefix}${(i + vmInitialNumber)}-nic'
  location: location
  tags: ResourceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }

}]

resource vm 'Microsoft.Compute/virtualMachines@2018-10-01' = [for i in range(0, sessionhostinstances): {
  name: '${sessionhostprefix}${(i + vmInitialNumber)}-VM'
  location: location
  tags: ResourceTags
  properties: {
    hardwareProfile: {
      vmSize: sessionhostsize
    }
    osProfile: {
      computerName: '${sessionhostprefix}${(i + vmInitialNumber)}-VM'
      adminUsername: vmAdministratorUsername
      adminPassword: vmAdministratorPassword
    }
    storageProfile: {
      imageReference: {
        id: imageReference
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: sessionhostdisktype
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${sessionhostprefix}${(i + vmInitialNumber)}-nic')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
  }
  zones: ((availabilityOption == 'AvailabilityZone') ? array(availabilityZone) : emptyArray)
  dependsOn: [
    nic
  ]
}]

resource vm_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, sessionhostinstances): {
  name: '${sessionhostprefix}${(i + vmInitialNumber)}-VM/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolname
        registrationInfoToken: hostpoolToken
      }
    }
  }
  dependsOn: [
    vm
  ]
}]

resource vm_joindomain 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, sessionhostinstances): {
  name: '${sessionhostprefix}${(i + vmInitialNumber)}-VM/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domain
      ouPath: ouPath
      user: administratorAccountUsername
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: administratorAccountPassword
    }
  }
  dependsOn: [
    vm_DSC
  ]
}]
