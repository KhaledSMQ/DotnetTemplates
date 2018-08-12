@echo off
if %1.==. GOTO error
if %2.==. GOTO error
if %3.==. GOTO error
if NOT %4.==-c. GOTO deployresources
if %5.==. GOTO error
echo Creating resource group %3 in '%5'
call az group create --name %3 --location %5
:deployresources
echo Deploying ARM template '%1.json' in resource group %3
call az group deployment create --resource-group %3 --parameters @%1.%2.parameters.json --template-file %1.json
GOTO end
:error
echo.
echo Usage: 
echo create-resources arm-file resource-group-name [-c location]
echo arm-file: Path to ARM template WITHOUT .json extension. An parameter file with same name plus '.parameters' MUST exist in same folde
echo resource-grop-name: Name of the resource group to use or create
echo -c: If appears means that resource group must be created. If -c is specified, must use enter location
echo.
echo Examples:
echo create-resources path_and_filename staging testgroup (Deploys path_and_filename.json with parameters specified in path_and_filename.parameters.json file).
echo create-resources path_and_filename staging newgroup -c aueast (Deploys path_and_filename.json (with parameters specified in path_and_filename.parameters.json file) in a NEW resource group named newgroup in the aueast location)
:end
