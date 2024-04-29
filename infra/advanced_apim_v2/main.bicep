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
