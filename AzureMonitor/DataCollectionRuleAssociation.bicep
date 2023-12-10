
param virtualmachinename string = 'AVD-DEV-2-VM'
param datacollectionrulename string = 'NielsKok.Tech_AutomatedMonitoring'
param datacollectionruleassociationname string = 'NielsKok.Tech_AutomatedMonitoring_Association'

resource virtualmachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualmachinename
}

resource datacollectionrule 'Microsoft.Insights/dataCollectionRules@2022-06-01' existing = {
  name: datacollectionrulename
}

resource datacollectionruleassociate 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: datacollectionruleassociationname
  scope: virtualmachine
  properties: {
    dataCollectionRuleId: datacollectionrule.id
    description: 'Data Collection Rule Association for Virtual Machine in Azure Monitor'
  }
}
