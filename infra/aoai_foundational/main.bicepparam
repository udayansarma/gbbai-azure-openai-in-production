using './main.bicep'

// General parameters
param prefix = 'dev-aoai'

// Parameters for 'eastus' location
param location = 'eastus'
param aoai_deployments_name = ['gpt35-turbo', 'gpt-35-turbo-16k']
param aoai_model_type  = ['gpt-35-turbo', 'gpt-35-turbo-16k']
param aoai_model_version = ['0613','0613']
param capacity = [10,10]

// Uncomment the following sections to set parameters for other locations

// Parameters for 'eastus2' location
// param location = 'eastus2'
// param aoai_deployments_name = ['gpt35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_type  = ['gpt-35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_version = ['0613','0613']
// param capacity = [20,25]

// Parameters for 'northcentralus' location
// param location = 'northcentralus'
// param aoai_deployments_name = ['gpt35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_type  = ['gpt-35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_version = ['0613','0613']
// param capacity = [20,25]

// Parameters for 'canadaeast' location
// param location = 'canadaeast'
// param aoai_deployments_name = ['gpt35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_type  = ['gpt-35-turbo', 'gpt-35-turbo-16k']
// param aoai_model_version = ['0613','0613']
// param capacity = [10,10]
