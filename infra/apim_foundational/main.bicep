@description('The unique name of the API Management service instance. This is auto-generated using the resource group ID.')
param apiManagementServiceName string

@description('The email address of the owner of the service. This is used for administrative purposes.')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service. This is used for administrative purposes.')
@minLength(1)
param publisherName string

@description('The pricing tier of this API Management service. This determines the cost and features available.')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string

@description('The instance size of this API Management service. This determines the capacity of the service.')
@allowed([
  1
  2
])
param skuCount int

@description('The Azure region where all resources will be deployed.')
param location string 

@description('The primary account for the Azure OpenAI service.')
param aoaiPrimaryAccount string

@description('The secondary account for the Azure OpenAI service.')
param aoaiSecondaryAccount string

@description('The primary deployment for the Azure OpenAI service.')
param aoaiPrimaryLLMDeployment string

@description('The secondary deployment for the Azure OpenAI service.')
param aoaiSecondaryLLMDeployment string

@description('The tertiary account for the Azure OpenAI service.')
param aoaiTertiaryAccount string

@description('The tertiary deployment for the Azure OpenAI service.')
param aoaiTertiaryLLMDeployment string

@description('The quaternary account for the Azure OpenAI service.')
param aoaiQuaternaryAccount string

@description('The quaternary deployment for the Azure OpenAI service.')
param aoaiQuaternaryLLMDeployment string

// @description('The API definition for the Azure OpenAI service.')
// param apidef string

// @description('The retry logic for the Azure OpenAI service.')
// param retrylogic string

@description('The API Management service resource. This is the main resource for managing APIs.')
resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

@description('The primary backend for the API Management service. This connects to the primary Azure OpenAI service.')
resource primarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'primary'
  parent: apiManagementService
  properties: {
    description: 'Primary LLM deployment endpoint'
    protocol: 'http'
    url: 'https://${aoaiPrimaryAccount}.openai.azure.com/openai/deployments/${aoaiPrimaryLLMDeployment}'
  }
}

@description('The secondary backend for the API Management service. This connects to the secondary Azure OpenAI service.')
resource secondarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'secondary'
  parent: apiManagementService
  properties: {
    description: 'Secondary LLM deployment endpoint'
    protocol: 'http'
    url: 'https://${aoaiSecondaryAccount}.openai.azure.com/openai/deployments/${aoaiSecondaryLLMDeployment}'
  }
}

@description('The tertiary backend for the API Management service. This connects to the tertiary Azure OpenAI service.')
resource tertiarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'tertiary'
  parent: apiManagementService
  properties: {
    description: 'Tertiary LLM deployment endpoint'
    protocol: 'http'
    url: 'https://${aoaiTertiaryAccount}.openai.azure.com/openai/deployments/${aoaiTertiaryLLMDeployment}'
  }
}

@description('The quaternary backend for the API Management service. This connects to the quaternary Azure OpenAI service.')
resource quaternarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'quaternary'
  parent: apiManagementService
  properties: {
    description: 'Quaternary LLM deployment endpoint'
    protocol: 'http'
    url: 'https://${aoaiQuaternaryAccount}.openai.azure.com/openai/deployments/${aoaiQuaternaryLLMDeployment}'
  }
}

@description('The API resource for the API Management service. This defines the API endpoints and operations.')
resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  name: 'CompletionsAPI'
  parent: apiManagementService
  properties: {
    format: 'openapi'
    value: loadTextContent('../../assets/aoai_api/openAIOpenAPI2023-12-01-preview.json')
    path: 'openai'
  }
}

@description('The policy resource for the API. This defines the behavior of the API, such as rate limiting and caching.')
resource policy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'xml'
    value: loadTextContent('../../assets/apim_policies/backoff.xml')
  }
}
