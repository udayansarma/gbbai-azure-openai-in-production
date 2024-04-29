# 🚀 How to Automate the deployment of AOAI with Bicep

This guide walks you through deploying Azure resources, including Azure OpenAI, Azure Cognitive Search, Azure Form Recognizer, and Azure Storage Account, using a Bicep template and Azure CLI. It assumes you have an .env file containing the necessary environment variables.

## 📋 Prerequisites

- Azure CLI installed and logged in to your Azure account. [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- An Azure subscription where you have permissions to create resources.
- A .env file with your project's environment variables defined.

#### 🌍 Load Environment Variables

Your .env file should contain the following variables:

```makefile
RESOURCE_PREFIX=yourResourcePrefix
```

Replace yourResourcePrefix, yourLocation, yourAuthType, yourAzureOpenAIResource, yourAzureOpenAIEmbeddingModel, yourAzureOpenAIEmbeddingModelName, yourAzureOpenAIEmbeddingModelVersion, yourAzureCognitiveSearch, yourAzureCognitiveSearchSku, yourFormRecognizerName, yourFormRecognizerLocation, and yourStorageAccountName with appropriate values for your project.

- For Unix-like systems (Linux/macOS), you can use:

        ```bash
        export $(grep -v '^#' .env | xargs)
        ```

- For Windows systems, you might need to manually set each environment variable using:

        ```powershell
        $env:RESOURCE_PREFIX="yourResourcePrefix"
        ```

#### Creating a Service Principal (Optional)

Before you can create a service principal, make sure you have met all the prerequisites above. Once you have, follow these steps:

1. **Login to Azure**

    Open your terminal and run:

    ```bash
    az login
    ```

Follow the instructions to complete the login process.

2. **Create a Resource Group (if not existent)**

    To create a resource group if it doesn't exist, you can use the following Azure CLI command:

    ```bash
    az group create --name $RESOURCE_GROUP --location $LOCATION
    ```

    Replace `<location>` with the desired location for your resource group.

3. **Creating a Service Principal (if not existent)**

    If you don't already have a Service Principal, you can create one by running the following command:

    ```bash
    az ad sp create-for-rbac --name YourServicePrincipalName
    ```

    Replace `YourServicePrincipalName` with a name of your choice for the service principal. This command will return a JSON object containing the service principal credentials. Here's how you interpret them:

    - `appId`: This is the CLIENT_ID, a unique identifier for the application registered in Azure AD.
    - `displayName`: This is the name of the service principal.
    - `password`: This is the secret key for the service principal, used for authentication.
    - `tenant`: This is the Tenant ID, a unique identifier for your Azure AD tenant.

    Note: The output does not include `SUBSCRIPTION_ID` and `RESOURCE_GROUP`.

    - `SUBSCRIPTION_ID`: This is a unique identifier for your Azure subscription. You can find this in the Azure portal, under "Subscriptions". Alternatively, you can also retrieve it using Azure CLI with the following command:

    ```bash
    az account show --query id --output tsv
    ```

    This command will return your subscription ID. If you have multiple Azure subscriptions, you should first set the desired subscription as the default using `az account set --subscription "Your Subscription Name"` before running `az account show`.   
    
    - `RESOURCE_GROUP`: This is the name of the resource group in your Azure subscription where you want to assign the role. This is chosen based on your organization's setup in Azure.

    When running the command to assign the role, replace `$CLIENT_ID` with the `appId` value from the output, `$SUBSCRIPTION_ID` with your Azure subscription ID, and `$RESOURCE_GROUP` with the name of your resource group.

4. **Assigning a Role to the Service Principal  (if not existent)**

    By default, a new service principal does not have permissions in your Azure subscription. You need to assign a role to the service principal to grant it access to resources in your subscription.

    To assign the 'Contributor' role to your service principal, run:

    ```bash
    az role assignment create --assignee $CLIENT_ID --role Contributor --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP
    ```

    Replace `CLIENT_ID` with the CLIENT_ID of your service principal, `SUBSCRIPTION_ID` with your subscription ID, and `RESOURCE_GROUP` with your resource group name.

 
    > **Note:** If you're using Git Bash on Windows and encountering issues with path translation, you can use the following workaround. Git Bash automatically translates Unix-style paths to Windows paths, which can cause issues with Azure CLI commands. To temporarily disable this path translation for a command, set the `MSYS_NO_PATHCONV` environment variable to `1`:

    ```bash
    MSYS_NO_PATHCONV=1 az role assignment create --assignee $CLIENT_ID --role Contributor --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/
    ```
    In this command, MSYS_NO_PATHCONV=1 disables path translation, allowing the Azure CLI command to run correctly.

    That's it! You've created a service principal and assigned it a role in your Azure subscription.

## 🚦 Steps for Deployment

Follow these steps to deploy your Azure resources using the Bicep template:

1. **Set up your environment variables:** Ensure your `.env` file is in the current directory and contains the necessary variables. These variables will be used as parameters for your Bicep deployment.

2. **Load environment variables:** Depending on your operating system, the command to load your environment variables from the `.env` file may vary.

    - For Unix-like systems (Linux/macOS), you can use:

        ```bash
        export $(grep -v '^#' .env | xargs)
        ```

    - For Windows systems, you might need to manually set each environment variable using:

        ```powershell
        $env:PROJECT_NAME="indexingapp"
        $env:ENVIRONMENT="dev"
        $env:RESOURCE_GROUP="rg-applications-$env:ENVIRONMENT"
        ```

3. **Authenticate with Azure:** Before deploying your Bicep template, authenticate with Azure using your service principal. Execute the following command:

    ```bash
    az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
    ```

    This command authenticates you with Azure using the service principal credentials defined in your `.env` file. It's crucial to ensure that the service principal has the necessary permissions to create and manage resources in your Azure subscription.

    > **Note:** As an alternative, you could use `az login` for interactive login. However, using a service principal is recommended for automation scenarios as it allows for non-interactive, script-based authentication.

4. **Deploy the Bicep Foundational:** Navigate to the directory containing your Bicep file (`yourBicepFileName.bicep`) and run the following Azure CLI command to start the deployment:

    ```bash
    az deployment sub create \
        --location $LOCATION \
        --template-file main.bicep \
        --parameters main.bicepparam
    ```

4. **Check the deployment output:** After the deployment completes, you can find the output values such as the Container Registry login server, Key Vault URI, and Application Insights Instrumentation Key printed in the terminal. These outputs can be used for further configurations or integrations.

Remember to replace `yourBicepFileName.bicep` with the actual name of your Bicep file and ensure all placeholders (`<YourResourceGroupName>`, `yourProjectName`, `yourEnvironment`) are replaced with actual values before executing the commands.

# 🎉 Conclusion

Congratulations! You've successfully navigated through the process of deploying Azure resources using a Bicep template and Azure CLI. This guide provided a step-by-step approach, utilizing environment variables from a .env file for configuration.

For further exploration and more detailed information on Bicep and Azure CLI, don't hesitate to refer to the [official Azure documentation](https://docs.microsoft.com/en-us/azure/developer/).

Before you go, remember to replace `yourBicepFileName.bicep` with the actual name of your Bicep file. Also, ensure all placeholders (`<YourResourceGroupName>`, `yourProjectName`, `yourEnvironment`) are replaced with actual values before executing the commands.

Thank you for following along with this guide. Happy coding! 🚀
