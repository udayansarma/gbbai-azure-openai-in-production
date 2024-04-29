@description('Location for all resources.')
@allowed([
  'australiaeast'
  'canadaeast'
  'eastus'
  'westus'
  'eastus2'
  'francecentral'
  'japaneast'
  'northcentralus'
  'southcentralus'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
  'westeurope'
])
param location string

@allowed([
  'gpt-4'
  'gpt-4-32k'
  'gpt-35-turbo'
  'gpt-35-turbo-16k'
])
param aoai_model_type string[]

param aoai_model_version string[]

@description('''The capacity of the deployment in 1000 units. 
The number of items in the array should match the number of deployments.
For e.g to provision 30K TPM, set capacity to 30. Max value of capacity is 300.
''')
param capacity int[]

@description('Azure OpenAI deployment name.')
param aoai_deployments_name string[]

param prefix string

//****************************************************************************************
// Variables
//****************************************************************************************

//param resourceGroup string
var aoaiServiceName = '${prefix}-aoai2-${location}'

// Change the type of the resource group resource
// resource deployResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
//   name: resourceGroup
// }

// // For all subsequent resources we will set the scope to be the Resource Group we're creating here.
// targetScope = 'subscription'
// resource deployResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: resourceGroup
//   location: location
//   properties: {}
// }

module aoai './modules/aoai.bicep' = {
  name: 'aoai-deployment'
  // Remove the scope property
  params: {
    location: location
    aoaiServiceName: aoaiServiceName
    deployments: [
      {
        name: aoai_deployments_name[0]
        model: {
          format: 'OpenAI'
          name: aoai_model_type[0]
          version: aoai_model_version[0]
        }
        raiPolicyName: 'CustomRaiPolicy_1'
        sku: {
          name: 'Standard'
          capacity: capacity[0]
        }
      }
      {
        name: aoai_deployments_name[1]
        model: {
          format: 'OpenAI'
          name: aoai_model_type[1]
          version: aoai_model_version[1]
        }
        raiPolicyName: 'CustomRaiPolicy_1'
        sku: {
          name: 'Standard'
          capacity: capacity[1]
        }
      }
    ]
  }
}

module aoairole './modules/aoairoles.bicep' = {
  name: 'aoai-role-deployment'
  // Remove the scope property
  params: {
    aoaiServiceName: aoaiServiceName
  }
  dependsOn: [
    aoai
  ]
}
