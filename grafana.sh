#Variables
SUBSCRIPTION_NAME="K+C Americas Sandbox"
RESOURCE_GROUP="rg-grafana"
LOCATION="East US"
STORAGE_ACCOUNT="sarsgrafana001"
APP_SERVICE_PLAN="GrafanaPlan"
WEB_APP_NAME="grafana-testing-rs001"

#Try this:
#az login --tenant xxxxxxx
#az account set -subscription XXXXX

#Login
az login
#Select Azure Subscription
az account set --subscription "$SUBSCRIPTION_NAME"
#Create a resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"
#Create storage account
az storage account create --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location "$LOCATION" \
    --sku Standard_LRS
#Get storage account key
storage_key=$(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query '[0].value' --output tsv)
#Create a container inside of the storage account
az storage container create --name grafana --account-name $STORAGE_ACCOUNT
#Create an App Service Plan
az appservice plan create --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --sku B1 --is-linux
#Create a web app
az webapp create --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --deployment-container-image-name grafana/grafana
#Create mount storage account
az webapp config storage-account add \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --custom-id GrafanaData \
    --storage-type AzureBlob \
    --share-name grafana \
    --account-name $STORAGE_ACCOUNT \
    --access-key $storage_key \
    --mount-path /var/lib/grafana/
#Configure environment variables for the docker image
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-azure-monitor-datasource,briangann-gauge-panel
#Assign Log Analytics Reader role to Grafana Azure AD App
az ad sp create-for-rbac -n grafana-testing-rs001 --role "Log Analytics Reader" --scope /subscriptions/514cd396-f281-41a1-b376-6d348b606151
