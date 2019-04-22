
function Get-RegionNetwork
{
	param([Parameter(Mandatory)][String] $EnvironmentId,
          [Parameter(Mandatory)][String] $Location)

	$networks = @{
		USAZUAUDDEeastus = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AUDIT_PREPROD_RG_Network/providers/Microsoft.Network/virtualNetworks/AUDIT_PREPROD_Virtual_Network/subnets/AUDIT_PREPROD_GeneralSubnet1'
		USAZUAUDDEwestus = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AZRG-USW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azuswnpdvnt01/subnets/azuswnpdsbn01'
		USAZUAUDDEnortheurope = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AZRG-EUN-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeunnpdvnt01/subnets/azeunnpdsbn01'
		USAZUAUDDEwesteurope = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AZRG-EUW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeuwnpdvnt01/subnets/azeuwnpdsbn01'
		USAZUAUDDEeastasia = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AZRG-APE-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapenpdvnt01/subnets/azapenpdsbn01'
		USAZUAUDDEsoutheastasia = '/subscriptions/d7ac9c0b-155b-42a8-9d7d-87e883f82d5d/resourceGroups/AZRG-APS-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapsnpdvnt01/subnets/azapsnpdsbn01'
		EUAZUAUDDEwestus = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-USW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azuswnpdvnt01/subnets/azuswnpdsbn01'
		EUAZUAUDDEeastus = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-USE-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azusenpdvnt01/subnets/azusenpdsbn01'
		EUAZUAUDDEnortheurope = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-EUN-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeunnpdvnt01/subnets/azeunnpdsbn01'
		EUAZUAUDDEwesteurope = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-EUW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeuwnpdvnt01/subnets/azeuwnpdsbn01'
		EUAZUAUDDEeastasia = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-APE-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapenpdvnt01/subnets/azapenpdsbn01'
		EUAZUAUDDEsoutheastasia = '/subscriptions/429c67ab-6761-4617-a512-a4743395cede/resourceGroups/AZRG-APS-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapsnpdvnt01/subnets/azapsnpdsbn01'
		APAZUAUDDEwestus = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-USW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azuswnpdvnt01/subnets/azuswnpdsbn01'
		APAZUAUDDEeastus = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-USE-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azusenpdvnt01/subnets/azusenpdsbn01'
		APAZUAUDDEnortheurope = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-EUN-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeunnpdvnt01/subnets/azeunnpdsbn01'
		APAZUAUDDEwesteurope = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-EUW-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azeuwnpdvnt01/subnets/azeuwnpdsbn01'
		APAZUAUDDEeastasia = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-APE-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapenpdvnt01/subnets/azapenpdsbn01'
		APAZUAUDDEsoutheastasia = '/subscriptions/579d5d7f-d0b3-4cc6-9c61-6715b876a8fe/resourceGroups/AZRG-APS-AUD-ITS-NPD/providers/Microsoft.Network/virtualNetworks/azapsnpdvnt01/subnets/azapsnpdsbn01'
		USAZUAUDwestus = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AUDIT_PRODBCP_RG_Network/providers/Microsoft.Network/virtualNetworks/AUDIT_PRODBCP_Virtual_Network/subnets/AUDIT_PRODBCP_GeneralSubnet1'
		USAZUAUDeastus = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AUDIT_PROD_RG_Network/providers/Microsoft.Network/virtualNetworks/AUDIT_PROD_Virtual_Network/subnets/AUDIT_PROD_GeneralSubnet1'
		USAZUAUDnortheurope = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AZRG-EUN-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeunprdvnt01/subnets/azeunprdsbn01'
		USAZUAUDwesteurope = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AZRG-EUW-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeuwprdvnt01/subnets/azeuwprdsbn01'
		USAZUAUDeastasia = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AZRG-APE-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapeprdvnt01/subnets/azapeprdsbn01'
		USAZUAUDsoutheastasia = '/subscriptions/8c71ef53-4473-4862-af36-bae6e40451b2/resourceGroups/AZRG-APS-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapsprdvnt01/subnets/azapsprdsbn01'
		EUAZUAUDwestus = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-USW-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azuswprdvnt01/subnets/azuswprdsbn01'
		EUAZUAUDeastus = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-USE-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azuseprdvnt01/subnets/azuseprdsbn01'
		EUAZUAUDnortheurope = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-EUN-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeunprdvnt01/subnets/azeunprdsbn01'
		EUAZUAUDwesteurope = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-EUN-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeuwprdvnt01/subnets/azeuwprdsbn01'
		EUAZUAUDeastasia = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-APE-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapeprdvnt01/subnets/azapeprdsbn01'
		EUAZUAUDsoutheastasia = '/subscriptions/62c1dd5c-d918-4a4d-b0ee-18d5e7d5071b/resourceGroups/AZRG-APS-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapsprdvnt01/subnets/azapsprdsbn01'
		APAZUAUDwestus = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-USW-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azuswprdvnt01/subnets/azuswprdsbn01'
		APAZUAUDeastus = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-USE-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azuseprdvnt01/subnets/azuseprdsbn01'
		APAZUAUDnortheurope = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-EUN-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeunprdvnt01/subnets/azeunprdsbn01'
		APAZUAUDwesteurope = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-EUW-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azeuwprdvnt01/subnets/azeuwprdsbn01'
		APAZUAUDeastasia = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-APE-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapeprdvnt01/subnets/azapeprdsbn01'
		APAZUAUDsoutheastasia = '/subscriptions/b2fcc9cc-5757-42d3-980c-d92d66bab682/resourceGroups/AZRG-APS-AUD-ITS-PRD/providers/Microsoft.Network/virtualNetworks/azapsprdvnt01/subnets/azapsprdsbn01'
	}
	$trimmedLocation = $Location.Trim().Replace(' ', '').ToLower()
	$key = "$EnvironmentId$trimmedLocation"

	return $networks[$key]
	#return "-$key-"
}



function Get-StarsPOD
{
	param([Parameter(Mandatory)][String] $Location)

	$Pods = @{
		eastus = 'POD'
		westus = 'POD'
		northeurope = 'EMAPOD'
		westeurope = 'EMAPOD'
		eastasia = 'APAPOD'
		southeastasia = 'APAPOD'
	}
	$key = $Location.Trim().Replace(' ', '').ToLower()

	return $Pods[$key]
	#return "-$key-"
}

function Get-StarsLifeCycle
{
	param([Parameter(Mandatory)][String] $lifeCycle)

	$Environments = @{
		DEV = 'Development'
		QA = 'Quality Assurance'
		LOAD = 'Quality Assurance'
		STAGE = 'Staging'
		PROD= 'Production'
		BCP= 'Business Continuity'
	}
	$key = $lifeCycle.Trim().Replace(' ', '').ToUpper()

	return $Environments[$key]
	#return "-$key-"
}

function Get-TimeZone ($location) {

	$key = $Location.Trim().Replace(' ', '').ToLower()

    switch ($key)
    {
		"eastus" {return "Eastern Standard Time"}
		"westus" {return "Pacific Standard Time"}
		"northeurope" {return "GMT Standard Time"}
		"westeurope"  {return "W. Europe Standard Time"}
		"southeastasia" {return "Singapore Standard Time"}
		"eastasia" {return "China Standard Time"}
		default {return "Coordinated Universal Time"}

    }
} 

# Encrypt VM Parameters
function Get-RegionEncryptionParameters
{
	param([Parameter(Mandatory)][String] $EnvironmentId,
			[Parameter(Mandatory)][String] $Location)
	
	$trimmedLocation = $Location.Trim().Replace(' ', '').ToLower()
	$key = "$EnvironmentId$trimmedLocation"

	# Check if environmentId is valid
	$acceptableNames = @('USAZUAUDDE','APAZUAUDDE','EUAZUAUDDE','USAZUAUD','APAZUAUD','EUAZUAUD')
	if ($EnvironmentId -notin $acceptableNames){
		Throw "EXPECTED ERROR: ServerName is not valid, please check that your environmentId variable is one of the following values: 'USAZUAUDDE','APAZUAUDDE','EUAZUAUDDE','USAZUAUD','APAZUAUD','EUAZUAUD'" 
	}

	# Obtain Envryption parameters, or error out if subscription-location condition pair not met
	if (($key -eq 'USAZUAUDnortheurope') -or
		($key -eq 'USAZUAUDwesteurope') -or
		($key -eq 'USAZUAUDeastasia') -or
		($key -eq 'USAZUAUDsoutheastasia') -or
		($key -eq 'EUAZUAUDwestus') -or
		($key -eq 'EUAZUAUDeastus') -or
		($key -eq 'EUAZUAUDeastasia') -or
		($key -eq 'EUAZUAUDsoutheastasia') -or
		($key -eq 'APAZUAUDwestus') -or
		($key -eq 'APAZUAUDeastus') -or
		($key -eq 'APAZUAUDnortheurope') -or
		($key -eq 'APAZUAUDwesteurope')){
		Throw "EXPECTED ERROR: You have chosen to deploy from one GEO's subscription to another GEO's location where the required KeyVault and RecoveryServicesVault location pairing for encryption and backup has not been created. As a result, you will not be able to perform a proper deployment, and this will fail as expected. If you would like to proceed with deployment anyway, please pass in the -noencrypt and -nobackup switches to deploy.ps1 script task to deplyo without encryption and backup, or contact the DevOps team to have the proper Key Vaults and Recovery Services Vaults created." 
	}
	else {
		# ENVIRONMENTIDlifecycle = keyVaultName
		$RegionEncryptionParameters = @{

					USAZUAUDDEwestus = 'AuditPreProdKeyVaultWUS'
					USAZUAUDDEeastus = 'AuditPreProdKeyVault'
					USAZUAUDDEnortheurope = 'AuditPreProdKeyVaultNEU'
					USAZUAUDDEwesteurope = 'AuditPreProdKeyVaultWEU'
					USAZUAUDDEeastasia = 'AuditPreProdKeyVaultEAA'
					USAZUAUDDEsoutheastasia = 'AuditPreProdKeyVaultSEA'

					EUAZUAUDDEwestus = 'EMAAuditPreProdKVWUS'
					EUAZUAUDDEeastus = 'EMAAuditPreProdKVEUS'
					EUAZUAUDDEnortheurope = 'EMAAuditPreProdKVNEU'
					EUAZUAUDDEwesteurope = 'EMAAuditPreProdKVWEU'
					EUAZUAUDDEeastasia = 'EMAAuditPreProdKVEAA'
					EUAZUAUDDEsoutheastasia = 'EMAAuditPreProdKVSEA'

					APAZUAUDDEwestus = 'APAAuditPreProdKVWUS'
					APAZUAUDDEeastus = 'APAAuditPreProdKVEUS'
					APAZUAUDDEnortheurope = 'APAAuditPreProdKVNEU'
					APAZUAUDDEwesteurope = 'APAAuditPreProdKVWEU'
					APAZUAUDDEeastasia = 'APAAuditPreProdKVEAA'
					APAZUAUDDEsoutheastasia = 'APAAuditPreProdKVSEA'

					USAZUAUDwestus = 'AuditProdBcpKeyVault'
					USAZUAUDeastus = 'AuditProdKeyVault'
					#USAZUAUDnortheurope = 'AuditProdKeyVaultNEU'
					#USAZUAUDwesteurope = 'AuditProdKeyVaultWEU'
					#USAZUAUDeastasia = 'AuditProdKeyVaultEAA'
					#USAZUAUDsoutheastasia = 'AuditProdKeyVaultSEA'

					#EUAZUAUDwestus = 'EMAAuditProdKVWUS'
					#EUAZUAUDeastus = 'EMAAuditProdKVEUS'
					EUAZUAUDnortheurope = 'EMAAuditProdKVNEU'
					EUAZUAUDwesteurope = 'EMAAuditProdKVWEU'
					#EUAZUAUDeastasia = 'EMAAuditProdKVEAA'
					#EUAZUAUDsoutheastasia = 'EMAAuditProdKVSEA'

					#APAZUAUDwestus = 'APAAuditProdKVWUS'
					#APAZUAUDeastus = 'APAAuditProdKVEUS'
					#APAZUAUDnortheurope = 'APAAuditProdKVNEU'
					#APAZUAUDwesteurope = 'APAAuditProdKVWEU'
					APAZUAUDeastasia = 'APAAuditProdKVEAA'
					APAZUAUDsoutheastasia = 'APAAuditProdKVSEA'

			}

		$keyVaultName = $RegionEncryptionParameters[$key]

		if (($EnvironmentId -eq 'USAZUAUDDE') -or ($EnvironmentId -eq 'EUAZUAUDDE') -or ($EnvironmentId -eq 'APAZUAUDDE')){
			$aadClientID = '4bc162b3-b7d9-4ebe-9cd3-a41399aa0c47'
			$aadKeyVault = 'Audit-SPN-PREPROD-APA-KV' # All 3 Geos share the same SPN Client ID and Secret for Pre-Prod
		}
		elseif ($EnvironmentId -eq 'USAZUAUD'){
			$aadClientID = '42cbf7a6-8773-4500-96b8-dd59cb5b68ca'
			$aadKeyVault = 'AuditProdKeyVault'
		}
		elseif ($EnvironmentId -eq 'EUAZUAUD'){
			$aadClientID = '018ab2d2-b0ee-4c6d-8e75-aae4cfc31a1f'
			$aadKeyVault = 'Audit-SPN-EMA-KV'
		}
		elseif ($EnvironmentId -eq 'APAZUAUD'){
			$aadClientID = '165eb76b-b044-43b6-a0a6-5cb1bf021aae'
			$aadKeyVault = 'Audit-SPN-APA-KV'
		}

		$aadClientSecret = (Get-AzureKeyVaultSecret -VaultName $aadKeyVault -Name 'ServicePrincipalKey').SecretValueText
	
		$keyEncryptionKeyURL = (Get-AzureKeyVaultKey -VaultName $keyVaultName -Name 'VMBitLockerKEK').Id
		$keyVaultResourceID = (Get-AzureRmKeyVault -VaultName $keyVaultName).ResourceId
		$keyVaultResourceGroup = (Get-AzureRmKeyVault -VaultName $keyVaultName).ResourceGroupName

		$EncryptionParameterList = @("$keyEncryptionKeyURL", "$keyVaultName", "$keyVaultResourceGroup", "$keyVaultResourceID", "$aadClientID", "$aadClientSecret")

		return $EncryptionParameterList
		#return "-$key-"
	}
}


# Backup VM Parameters
function Get-RegionBackupParameters
{
	param([Parameter(Mandatory)][String] $EnvironmentId,
          [Parameter(Mandatory)][String] $Location)

	# ENVIRONMENTIDLocation = RecoveryVault, RecoveryVaultResourceGroup
	$RecoveryVault = @{
			USAZUAUDDEeastus = 'Audit-AME-EUS-NPD-Backup'
			USAZUAUDDEwestus = 'Audit-AME-WUS-NPD-Backup' 
			USAZUAUDDEnortheurope = 'Audit-AME-NEU-NPD-Backup' 
			USAZUAUDDEwesteurope = 'Audit-AME-WEU-NPD-Backup'
			USAZUAUDDEeastasia = 'Audit-AME-EAA-NPD-Backup'
			USAZUAUDDEsoutheastasia = 'Audit-AME-SEA-NPD-Backup' 
 
			EUAZUAUDDEwestus = 'Audit-EMA-WUS-NPD-Backup'
			EUAZUAUDDEeastus = 'Audit-EMA-EUS-NPD-Backup' 
			EUAZUAUDDEnortheurope = 'Audit-EMA-NEU-NPD-Backup' 
			EUAZUAUDDEwesteurope = 'Audit-EMA-WEU-NPD-Backup' 
			EUAZUAUDDEeastasia = 'Audit-EMA-EAA-NPD-Backup'
			EUAZUAUDDEsoutheastasia = 'Audit-EMA-SEA-NPD-Backup' 
 
			APAZUAUDDEwestus = 'Audit-APA-WUS-NPD-Backup'
			APAZUAUDDEeastus = 'Audit-APA-EUS-NPD-Backup' 
			APAZUAUDDEnortheurope = 'Audit-APA-NEU-NPD-Backup' 
			APAZUAUDDEwesteurope = 'Audit-APA-WEU-NPD-Backup'
			APAZUAUDDEeastasia = 'Audit-APA-EAA-NPD-Backup' 
			APAZUAUDDEsoutheastasia = 'Audit-APA-SEA-NPD-Backup' 
 
			USAZUAUDwestus = 'Audit-AME-WUS-BCP-Backup' 
			USAZUAUDeastus = 'Audit-AME-EUS-PRD-Backup' 
			#USAZUAUDnortheurope = 'Audit-AME-NEU-PRD-Backup'
			#USAZUAUDwesteurope = 'Audit-AME-WEU-PRD-Backup'
			#USAZUAUDeastasia = 'Audit-AME-EAA-PRD-Backup'
			#USAZUAUDsoutheastasia = 'Audit-AME-SEA-PRD-Backup'
 
			#EUAZUAUDwestus = 'Audit-EMA-WUS-PRD-Backup'
			#EUAZUAUDeastus = 'Audit-EMA-EUS-PRD-Backup'
			EUAZUAUDnortheurope = 'Audit-EMA-NEU-PRD-Backup' 
			EUAZUAUDwesteurope = 'Audit-EMA-WEU-PRD-Backup' 
			#EUAZUAUDeastasia = 'Audit-EMA-EAA-PRD-Backup'
			#EUAZUAUDsoutheastasia = 'Audit-EMA-SEA-PRD-Backup'
 
			#APAZUAUDwestus = 'Audit-APA-WUS-PRD-Backup'
			#APAZUAUDeastus = 'Audit-APA-EUS-PRD-Backup'
			#APAZUAUDnortheurope = 'Audit-APA-NEU-PRD-Backup'
			#APAZUAUDwesteurope = 'Audit-APA-WEU-PRD-Backup'
			APAZUAUDeastasia = 'Audit-APA-EAA-PRD-Backup' 
			APAZUAUDsoutheastasia = 'Audit-APA-SEA-PRD-Backup' 
	}

	$trimmedLocation = $Location.Trim().Replace(' ', '').ToLower()
	$key = "$EnvironmentId$trimmedLocation"

	$RecoveryVaultName = $RecoveryVault[$key]

	$RecoveryVaultResourceGroup = (Get-AzureRmRecoveryServicesVault -Name $RecoveryVaultName).ResourceGroupName

	$RecoveryVaultList = @("$RecoveryVaultName", "$RecoveryVaultResourceGroup")

	return $RecoveryVaultList
	#return "-$key-"
}