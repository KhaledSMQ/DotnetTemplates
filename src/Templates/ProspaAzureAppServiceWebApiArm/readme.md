# Deploying Resources On Azure

## Pre-requisites
1. [Azure CLI 2.0 Installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Azure subscription created

Login into your azure subscription by typing `az login` (note that you maybe need to use `az account set` to set the subscription to use). Refer to [this article](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli) for more details


# Deploying resources using create-resources script

The `create-resources.cmd ` script is a basic script to allow easy deployment of one ARM template in one resource group. You can deploy to an existing resource group or to create one.

## Deploying to a existing resource group

Type `create-resources [pathfile-to-arm-template] resourcegroup` from command-prompt. Called this way the script will:

1. Search for `path-to-arm-template.json` and `path-to-arm-template.parameters.json` files
2. If they exist, will deploy them in the `resourcegroup` specified (that resource group in Azure has to exist).

## Deploying to a new resource group

Type `create-resources [pathfile-to-arm-template] resourcegroup -c location`. Called this way the script will:

1. Search for `path-to-arm-template.json` and `path-to-arm-template.parameters.json` files
2. If they exist, will create the `resourcegroup` specified in the `location` specified.
3. Finally will deploy `path-to-arm-template.json` and `path-to-arm-template.parameters.json` files in the `resourcegroup`