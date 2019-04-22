param
(
	[Parameter(Mandatory)]	[string]$PodDomainServiceAccountPassword,
	[Parameter(Mandatory)]	[string]$PodDomainServiceAccount,
	[Parameter(Mandatory)]	[string]$VmAdminPassword,
	[Parameter(Mandatory)] 	[string]$ServerTemplate,
	[Parameter(Mandatory=$false)] 	[string]$ServerParameterFile,
	[Parameter(Mandatory)]	[string]$ServerNames,
	[Parameter(Mandatory)] 	[string]$Location,
	[Parameter(Mandatory=$false)]  [hashtable]$Overrides,
	[Parameter(Mandatory=$false)]  [hashtable]$SecureOverrides,
	[Parameter(Mandatory=$false)] [string]$SubnetOverride,
	[switch] $Validate,
	[switch] $Build,
	[switch] $UTCTimeZone,
	[Parameter(Mandatory = $True)] [ValidateSet("Linux","Windows")] [string]$OSType
)

# Check to see if we are trying to reuse any VM names that have already been created in a different resource group
$vms = Get-AzureRmVm

# take the space delimited strings in $ServerNames and convert to arrays
# If there's no space then there's just element and it goes into a single element array,
# type safe cast

# test comment

if(!($ServerNames)) {
  Write-Output 'ServerName not defined, exiting...'
	Exit 1
} else {
	if ( $OSType -eq "Linux") {
		[array] $serverNamesList = $ServerNames.split(' ').ToLower()
	} else {
		[array] $serverNamesList = $ServerNames.split(' ')
	}
}

#Getting the server count from the length of ServerNames array.
$ServerCount = $serverNamesList.length

foreach ($serverName in $ServerNames)
{
	if ($vms.Name -contains $serverName)
	{
		$existingVmRg = ($vms | Where-Object {$_.Name -eq $serverName}).ResourceGroupName
		
		if($existingVmRg -ne $env:ResourceGroupName)
		{
			"The server name $serverName already exists in $existingVmRg"
			"See https://symphonyvsts.visualstudio.com/Symphony.Infastructure/_wiki/wikis/Symphony.Infastructure.wiki?wikiVersion=GBwikiMaster&pagePath=%2FSymphony%20Infrastructure%20Wiki%2FIAAS%20Infrastructure%2F01%20Creation for usage details"
			"This likely means the systemId is not unique"
			exit 0
		}
	}
}

"PodDomainServiceAccount $PodDomainServiceAccount"
"env:ResourceGroupName $env:ResourceGroupName"
"ServerParameterFile $ServerParameterFile"

$storageAccount = Get-AzureRmStorageAccount | Where-Object -FilterScript {$_.StorageAccountName -match '^devopstools.*std'}
$storageAccountName = $storageAccount.StorageAccountName
$storageAccountKey = (Get-AzureRmStorageAccountKey -AccountName $storageAccountName -ResourceGroupName $storageAccount.ResourceGroupName).Value[0]
$serverTemplatePath = resolve-path -Path $ServerTemplate
$parameterFilePath =  resolve-path -Path $ServerParameterFile

if(-not ( $env:ResourceGroupName -and $ServerParameterFile -and $env:Application -and $env:LifeCycle)) {
  Write-Output -InputObject 'You must set the following environment variables to test this script interactively.'
  Write-Output -InputObject '$env:ResourceGroupName - Name of the resource group to create the VMs in.  If it does not exist, it will be created'
  Write-Output -InputObject '$env:ParameterFile - Parameter file used to run the template'
  Write-Output -InputObject '$env:Application - Aplication that owns the servers'
  Write-Output -InputObject '$env:LifeCycle - Life cycle of the servers: DEV, QA, LOAD, STAGE, PROD or BCP'
  Write-Output -InputObject 'Exiting...'
  exit 1
}

@"
ServerTemplate: $serverTemplatePath
parameterFilePath: $parameterFilePath
"@

# to support variable overrides, we need to move all environment variables to script variables
$ResourceGroupName = $env:ResourceGroupName
$release_environmentname = $env:release_environmentname
$environmentId = $env:environmentId
$application = $env:Application
$environment = $env:Lifecycle



#set the value for Geo
if($Location -eq 'East US' -or $Location -eq 'East US 2' -or $Location -eq 'West US' -or $Location -eq 'West US 2')
{
	$Geo = 'AME'
	$Country = 'US'
}
elseif($Location -eq 'West Europe' -or $Location -eq 'North Europe')
{
	$Geo = 'EMA'
	$Country = 'Europe'
}
elseif($Location -eq 'East Asia' -or $Location -eq 'Southeast Asia')
{
	$Geo = 'APA'
	$Country = 'SEA'
}

# set appropriate domain depending on EnvironmentID variable
if($environmentId -eq 'USAZUAUDDE' -or $environmentId -eq 'EUAZUAUDDE' -or $environmentId -eq 'APAZUAUDDE') {
	$Domain = 'usclouddev.us.deloitte.com'
} elseif($environmentId -eq 'USAZUAUD' -or $environmentId -eq 'EUAZUAUD' -or $environmentId -eq 'APAZUAUD') {
	$Domain = 'uscloudprod.us.deloitte.com'
}

# Set the subnet VNET
Import-Module $PSScriptRoot\Util-Functions.psm1
# Subnet override allows for targetting a different subnet - appends characters to be consumed by the lookup table in util functions
if($SubnetOverride) {
	$subnetLocation = $location + $SubnetOverride
} else {
	$subnetLocation = $location
}
$subnet = Get-RegionNetwork -EnvironmentId $environmentId -Location $subnetLocation

#Set the stars POD prefix
$pod = Get-StarsPOD -Location $location

#Set stars life cycle and validate
$lifeCycle = Get-StarsLifeCycle -lifeCycle $env:LifeCycle

if(-not($lifeCycle)) {
  Write-Output -InputObject 'You must enter a valid life cycle value.'
  Write-Output -InputObject 'Valid values are DEV, QA, LOAD, STAGE, PROD or BCP'
  Write-Output -InputObject 'Exiting...'
  exit 1
}

#Set the timezone based on the flag for UTC or the location
if($UTCTimeZone) {
	$timeZone = "Coordinated Universal Time"
} else {
	$timeZone = Get-TimeZone($Location)
}

# Set the Backup Parameters based on Location
$BackupParametersList = Get-RegionBackupParameters -EnvironmentId $environmentId -Location $Location
$RecoveryVault = $BackupParametersList[0]
$RecoveryVaultResourceGroup = $BackupParametersList[1]


# setup initial command hashtable - key names should match parameter names 
$Params = @{
	ResourceGroupName=$ResourceGroupName
	TemplateFile=$serverTemplatePath
	TemplateParameterFile=$parameterFilePath
	ServerNames=$serverNamesList
	ServerCount=$ServerCount
	PodDomainServicePassword=$PodDomainServiceAccountPassword
	#Environment=$release_environmentname
	EnvironmentID=$environmentId
	Geo=$Geo
	Environment=$Environment
	Country=$Country
	PodDomainServiceUser=$PodDomainServiceAccount
	DevOpsStorageAccountAccessKey=$storageAccountKey
	VmAdminPassword=$VmAdminPassword
	DevOpsStorageAccountName=$storageAccountName
	Domain=$Domain
	Application=$application
	Location=$location
	SubnetRef=$subnet
	StarsPod = $pod
	StarsLifeCycle = $lifeCycle
	TimeZone = $timeZone
	# Backup VM Parameters
	BACExistingVirtualMachinesResourceGroup = $ResourceGroupName
	BACRecoveryServicesVaultName = $RecoveryVault
	BACRecoveryServicesVaultResourceGroup = $RecoveryVaultResourceGroup
	}
	
# if Overrides hashtable is specified, we need to override all parameters that are normally used, or add additional parameters
if($Overrides)
{
  foreach($key in $Overrides.Keys)
  {
    if($Params.ContainsKey($key))
    {
		# overwrite value
		"Setting $key in overrides"	
		 $Params[$key] = $Overrides[$key]
    }
    else
    {
		# add value
		"Adding $key in overrides"	
		$Params += @{$key=$Overrides[$key]}
    }
  }
}


if($SecureOverrides)
{
  foreach($key in $SecureOverrides.Keys)
  {
    if($Params.ContainsKey($key))
    {
		# overwrite value
		"Setting $key in secure overrides"	
		$Params[$key] = (ConvertTo-SecureString -String $SecureOverrides[$key] -AsPlainText -Force)
    }
    else
    {
		# add value
		"Adding $key in secure overrides"
		$Params += @{$key=(ConvertTo-SecureString -String $SecureOverrides[$key] -AsPlainText -Force)}
    }
  }
}

#encrypt passwords
$Params['PodDomainServicePassword'] = (ConvertTo-SecureString -String $PodDomainServiceAccountPassword -AsPlainText -Force)
$Params['VmAdminPassword'] = (ConvertTo-SecureString -String $VmAdminPassword -AsPlainText -Force)
$Params['DevOpsStorageAccountAccessKey'] = (ConvertTo-SecureString -String $storageAccountKey -AsPlainText -Force)

Write-Host '------------ PARAMETERS -------------'
$Params | Format-Table -AutoSize
Write-Host '-------------------------------------'

#validating the machine does not exist on other Resource Group
$vms = Get-AzureRmVM | where-object {$_.Name -In $serverNamesList -and $_.ResourceGroupName -ne $env:ResourceGroupName}
if($vms.Count -gt 0) {
	Write-Output -InputObject 'The machines being created already exist on a different resource group'
	$vms | Format-Table
	Write-Output -InputObject 'Terminating the process...'
	exit 1
}

if($Validate -or $Build) {
  $resourceGroupObject = Get-AzureRmResourceGroup -Name $env:ResourceGroupName -ErrorAction SilentlyContinue
  if(!$resourceGroupObject) {
    Write-Output -InputObject "Creating $($env:ResourceGroupName) Resource Group at $Location"
    New-AzureRmResourceGroup -Name $env:ResourceGroupName -Location $Location -Force
  }
}

if($Validate) {
  if($ServerCount -gt 0)  {
    'Validating Template'
    "Template: $ServerTemplate"
    #Test-AzureRmResourceGroupDeployment -ResourceGroupName $env:ResourceGroupName -TemplateFile $serverTemplatePath -TemplateParameterFile $parameterFilePath -ServerNames $serverNamesList -ServerCount $ServerCount -PodDomainServicePassword (ConvertTo-SecureString -String $PodDomainServiceAccountPassword -AsPlainText -Force)  -Environment $env:release_environmentname -EnvironmentID $env:environmentId -PodDomainServiceUser $PodDomainServiceAccount -DevOpsStorageAccountAccessKey (ConvertTo-SecureString -String $storageAccountKey -AsPlainText -Force) -VmAdminPassword (ConvertTo-SecureString -String $VmAdminPassword -AsPlainText -Force) -DevOpsStorageAccountName $storageAccountName
    Test-AzureRmResourceGroupDeployment @Params
  }
}

if($Build) {
  if($ServerCount -gt 0)  {
    'Running Template'
    "Template: $ServerTemplate"
    #New-AzureRmResourceGroupDeployment -ResourceGroupName $env:ResourceGroupName -TemplateFile $serverTemplatePath -TemplateParameterFile $parameterFilePath -ServerNames $serverNamesList -ServerCount $ServerCount -PodDomainServicePassword (ConvertTo-SecureString -String $PodDomainServiceAccountPassword -AsPlainText -Force)  -Environment $env:release_environmentname -EnvironmentID $env:environmentId -PodDomainServiceUser $PodDomainServiceAccount -DevOpsStorageAccountAccessKey (ConvertTo-SecureString -String $storageAccountKey -AsPlainText -Force) -VmAdminPassword (ConvertTo-SecureString -String $VmAdminPassword -AsPlainText -Force) -DevOpsStorageAccountName $storageAccountName
    New-AzureRmResourceGroupDeployment @Params
  }
}