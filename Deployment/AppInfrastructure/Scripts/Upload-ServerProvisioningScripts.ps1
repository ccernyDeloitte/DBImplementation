<#
 This is specific to Argus
 Upload scripts used for VM provisioning to the storage account
 These will be uploaded to the created VMs via the ARM templates
 
 Fils to Upload
 ├───argus-provisioning
 │       SetUp_KiraBackEndVM.sh
 │       SetUp_KiraWebAPI.sh
 │       SetUp_KiraWorkerVM.sh
 │       SetUp_PostgresqlVM.sh
 │       SetUp_VMBaseConfig.sh

 Target Location
  - Storage account: devopstoolsamestd
  - Container: https://devopstoolsamestd.blob.core.windows.net/argus-provisioning
  - Status: Primary: Available, Secondary: Available
  - Location: East US (Primary), West US (Secondary)
  - Subscription: US_AUDIT_PREPROD
  - Subscription ID: d7ac9c0b-155b-42a8-9d7d-87e883f82d5d
  - Primary blob service endpoint: https://devopstoolsamestd.blob.core.windows.net/
  - Secondary blob service endpoint: https://devopstoolsamestd-secondary.blob.core.windows.net/
  - Replication status: Live
  - KIND: Storage (general purpose v1)
  - SKU: Standard_RAGRS

#>

$storageAccount = Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -match '^devopstools.*std'}
$storageContainer = Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -match '^devopstools.*std'} | Get-AzureStorageContainer | Where-Object {$_.Name -eq 'arguslegacy-vm-provisioning'}
$filesToUpload = Get-ChildItem -Path $(resolve-path -Path $PSScriptRoot\..\arguslegacy-vm-provisioning\)
foreach ($file in $filesToUpload)
{
	Write-Output "Uploading scripts $($file.FullName) to: $($storageAccount.StorageAccountName)"
	$storageContainer | Set-AzureStorageBlobContent -File $file.FullName -Blob $file.Name -Force
}
