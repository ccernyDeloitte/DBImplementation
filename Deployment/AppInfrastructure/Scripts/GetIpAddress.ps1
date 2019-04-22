param(
		[Parameter(Mandatory)]	[string]$PodDomainServiceAccountPassword,
		[Parameter(Mandatory)]	[string]$PodDomainServiceAccount,
		[Parameter(Mandatory)]	[string[]]$MachineNames

)

for ($i=0; $i -lt $MachineNames.length; $i++) {
	$NetworkInterfaceName=($MachineNames[$i])+"-nic"
	$VMIpAddress = ((Get-AzureRmNetworkInterface | where {$_.Name -eq $NetworkInterfaceName }).IpConfigurations).PrivateIpAddress
    Write-Host "##vso[task.setvariable variable=VMIpAddress]IPAddress"
	$VMIpAddress
	}