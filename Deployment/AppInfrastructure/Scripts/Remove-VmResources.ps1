param
(
	[Parameter(Mandatory)] [string] $ResourceGroupName,
	[Parameter(Mandatory)] [array] $VMNames
)


if($VMNames -eq $null)
{
  throw 'VMNames not defined'
}

$vmNamesList = $VMNames.split(' ')
$list = New-Object System.Collections.ArrayList

foreach ($vmName in $vmNamesList) {
	#get vm
	$vm = (Get-AzureRmResource -ResourceGroupName "$ResourceGroupName" -ResourceType "Microsoft.Compute/virtualMachines" -ResourceName "$vmName")
	if ($vm -eq $null) {
		throw "VM not found."
	}
	$list.Add($vm.ResourceId) | Out-Null

	#get disks
	$disks = (Find-AzureRmResource -ResourceGroupNameEquals "$ResourceGroupName" -ResourceType "Microsoft.Compute/disks" -ResourceNameContains "$vmName")
	if ($disks -ne $null) {
		foreach ($disk in $disks) {
			if ($disk -ne $null) {
				$list.Add($disk.ResourceId) | Out-Null
			}
		}
	}

	#get nic
	$nic = (Find-AzureRmResource -ResourceGroupNameEquals "$ResourceGroupName" -ResourceType "Microsoft.Network/networkInterfaces" -ResourceNameContains "$vmName")
	if ($nic -ne $null) {
		$list.Add($nic.ResourceId) | Out-Null
	}
}

#commenting out avail set
#get avail set
#$avset = (Find-AzureRmResource -ResourceGroupNameEquals "$ResourceGroupName" -ResourceType "Microsoft.Compute/availabilitySets")
#if ($avset -ne $null) {
#	$list.Add($avset.ResourceId) | Out-Null
#}


#remove
foreach ($item in $list) {
	Write-Host "Removing [$item]..."

	try {
		Remove-AzureRmResource -ResourceId "$item" -Force | Out-Null
	}
	catch {
		Write-Host "Error occured while removing [$item]."
	}
}
Write-Host "Done."
