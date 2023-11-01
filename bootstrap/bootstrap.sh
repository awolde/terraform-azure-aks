SUBSCRIPTION=<sub-id>
RESOURCE_GROUP_NAME=rg-appname-dev-001
STORAGE_ACCOUNT_NAME=storgnametfdev001
CONTAINER_NAME=tfstate
LOCATION=centralus
ENV=Dev

az account set --subscription $SUBSCRIPTION

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --tags Env=""  Appname="tfo" AppOwner="Fname Lname"  CreationDate="06-12-2023"

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --tags Env=""  Appname="tfo" AppOwner="Fname Lname"  CreationDate="06-12-2023"

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
