param loganalyticsname string = 'nkoavdmonitoring'
param loganalyticsrgname string = 'rg_we_loganalytics'
param datacollectionrulename string = 'NielsKok.Tech_AutomatedMonitoring'
param location string = 'westeurope'

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: loganalyticsname
  scope: resourceGroup(loganalyticsrgname)
}

resource datacollectionrule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: datacollectionrulename
  location: location
  properties: {
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          loganalytics.id
        ]
      }
    ]
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: loganalyticsname
          workspaceResourceId: loganalytics.id
        }
      ]
    }
  }
}
