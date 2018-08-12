#Requires -Version 3.0
#Requires -Modules AzureRM

<#
.Synopsis
	Validates and optionally deploys the arm template, assumes .azure\azureProfile-prospa-demo.json exists to authenticate, otherwise prompts for login

.Example
	& .\Demo-Deploy -ResourceGroup "demo-rg-test" -SubscriptionId 123 -Location "Australia East" -AzureDeployJsonFilePath "C:\azuredeploy.json" -AzureDeployParametersJsonFilePath "C:\azuredeploy.demo.parameters.json" -DeployAfterValidation "yes"

.PARAMETER SubscriptionId
	The Azure subscription id

.PARAMETER Location
	The Azure location of the resource group, defaults to "Australia East"

.PARAMETER ResourceGroup
	The name of the resource group to deploy to

.PARAMETER AzureDeployJsonFilePath
	If not provided attempts to use an azuredeploy.json file in the scripts directory as the parameter file to deploy/validate

.PARAMETER AzureDeployParametersJsonFilePath
	If not provided attempts to use an azuredeploy.parameters.demo.json file in the scripts directory as the parameter file to deploy/validate

.PARAMETER DeployAfterValidation
	"yes" to deploy the template once it has been validated successfully

#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)]
	[string] $ResourceGroup,
	[Parameter(Mandatory=$true)]
	[string] $SubscriptionId,
	[Parameter(Mandatory=$false)]
	[string] $Location = "Australia East",
	[Parameter(Mandatory=$false)]
	[string] $AzureDeployJsonFilePath,
	[Parameter(Mandatory=$false)]
	[string] $AzureDeployParametersJsonFilePath,
	[Parameter(Mandatory=$false)]
	[string] $DeployAfterValidation = "no"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {

	param ($ValidationOutput, [int] $Depth = 0)
	Set-StrictMode -Off
	return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

function Validate-Template($templateFile, $resourceGroup, $templateParametersFile) {
	
	$ErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName ($resourceGroup) `
																				  -TemplateFile $templateFile `
																				  -TemplateParameterFile $templateParametersFile)

	if ($ErrorMessages) {
		Write-Error ('Validation returned the following errors:' + @($ErrorMessages))
		return $false
	}
	else {
		Write-Host 'Template is valid.'
		return $true
	}
}

function Deploy-Template($templateFile, $resourceGroup, $templateParametersFile) {	

	New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $templateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
										-ResourceGroupName ($resourceGroup) `
										-TemplateFile $templateFile `
										-TemplateParameterFile $templateParametersFile `
										-Force -Verbose `
										-ErrorVariable ErrorMessages

	if ($ErrorMessages) {
		Write-Error ('Template deployment returned the following errors:' + (@(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })))
	}
}

function Ensure-ResourceGroup($resourceGroup, $location, $tags) {

	$existingResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName ( $resourceGroup)  -ErrorAction SilentlyContinue *>&1

	# Create the resource group if it doesn't already exist
	if (!($existingResourceGroup)) {  
		New-AzureRmResourceGroup -Name ($resourceGroup) -Location $location -Tag $tags
	}
}

$azureProfile = Join-Path $env:USERPROFILE '.azure\azureProfile-prospa-demo.json'

if (-not(Test-Path $azureProfile)) {
	Login-AzureRmAccount
} else {
	Import-AzureRmContext -Path $azureProfile
}

if ($AzureDeployJsonFilePath) {
	$deploymentFileExists = Test-Path $AzureDeployJsonFilePath
	if ($deploymentFileExists -eq $false) {
		Write-Error "Deployment file doesn't exist"
		return
	} else {
		$templateFile = [System.IO.Path]::GetFullPath($AzureDeployJsonFilePath)
	}
} else {
	$templateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, 'azuredeploy.json'))
}

if ($AzureDeployParametersJsonFilePath) {
	$deploymentParametersFileExists = Test-Path $AzureDeployParametersJsonFilePath
	if ($deploymentParametersFileExists -eq $false) {
		Write-Error "Deployment Parameters file doesn't exist"
		return
	} else {
		$templateParametersFile = [System.IO.Path]::GetFullPath($AzureDeployParametersJsonFilePath)
	}
} else {
	$templateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, 'azuredeploy.parameters.demo.json'))
}

Select-AzureRmSubscription -SubscriptionId $SubscriptionId

Ensure-ResourceGroup -resourceGroup ($ResourceGroup)-location $Location -tags @{ environment="demo" } 

$isValid = Validate-Template -templateFile $AzureDeployJsonFilePath -resourceGroup ($ResourceGroup) -templateParametersFile $templateParametersFile

if ($isValid -and $DeployAfterValidation -eq 'yes') {
	Deploy-Template -templateFile $templateFile -resourceGroup ($ResourceGroup) -templateParametersFile $templateParametersFile
}
