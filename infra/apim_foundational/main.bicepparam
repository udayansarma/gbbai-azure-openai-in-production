using './main.bicep'

// General parameters
var prefix = 'dev-aoai'
param location = 'eastus'
param apiManagementServiceName = '${prefix}-${location}-apim-004'
param publisherEmail = 'admin@contoso.com'
param publisherName = 'ContosoAdmin'
param sku = 'Developer'
param skuCount  = 1

// OpenAI account parameters
param aoaiPrimaryAccount = 'dev-aoai-aoai2-eastus'
param aoaiSecondaryAccount = 'dev-aoai-aoai-northcentralus'
param aoaiTertiaryAccount = 'dev-aoai-aoai-canadaeast'
param aoaiQuaternaryAccount = 'dev-aoai-aoai2-eastus2'

// OpenAI deployment parameters
param aoaiPrimaryLLMDeployment = 'gpt-35-turbo'
param aoaiSecondaryLLMDeployment = 'gpt-35-turbo'
param aoaiTertiaryLLMDeployment = 'gpt-35-turbo'
param aoaiQuaternaryLLMDeployment = 'gpt-35-turbo'
