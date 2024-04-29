// This is a parameter that will be passed into the Bicep file when it is deployed. 
// It is the name of the Azure OpenAI service that will be used in this deployment.
@description('Azure OpenAI Resource Name.')
param aoaiServiceName string

// This line is loading a JSON file that contains a list of principal IDs. 
// These IDs will be used to assign roles to the principals (users or service principals) in Azure.
var principalIds = loadJsonContent('../artifacts/userPrincipalIds.json')

// These commented lines are showing the IDs of different roles that can be assigned in Azure. 
// These IDs are used in the role assignments below.
//'Cognitive Services Contributor': resourceId('Microsoft.Authorization/roleAssignments', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')
//'Cognitive Services OpenAI Contributor': resourceId('Microsoft.Authorization/roleAssignments', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
//'Cognitive Services OpenAI User': resourceId('Microsoft.Authorization/roleAssignments', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
//'Cognitive Services User': resourceId('Microsoft.Authorization/roleAssignments', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// This is an existing resource block for the Azure Cognitive Services account. 
// It is using the parameter aoaiServiceName as the name of the resource.
resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aoaiServiceName
}

// This is a resource block that is creating role assignments for each principal ID in the contributorPrincipalIds list. 
// It is assigning the 'Cognitive Services Contributor' role to each principal.
resource contributorRoleID 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds.contributorPrincipalIds:  {
  // The name of the role assignment is a GUID that is generated from the principal ID, the role ID, and the cognitive service ID.
  name: guid(principalId, '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68', cognitiveService.id)
  // The scope of the role assignment is the cognitive service.
  scope: cognitiveService
  properties: {
    // The roleDefinitionId is the ID of the role that is being assigned.
    roleDefinitionId: resourceId('Microsoft.Authorization/roleAssignments', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')
    // The principalId is the ID of the principal that the role is being assigned to.
    principalId: principalId
  }
}]

// This is a similar resource block to the one above, but it is assigning the 'Cognitive Services User' role to each principal in the userPrincipalIds list.
resource userRoleID 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds.userPrincipalIds:  {
  name: guid(principalId, 'a97b65f3-24c7-4388-baec-2e87135dc908', cognitiveService.id)
  scope: cognitiveService
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleAssignments', 'a97b65f3-24c7-4388-baec-2e87135dc908')
    principalId: principalId
  }
}]


