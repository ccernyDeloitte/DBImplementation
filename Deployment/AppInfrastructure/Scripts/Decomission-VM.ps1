<#
This is the windows version of VM Decom. 
Needs to be adapted for *nix
#>

param
(
[Parameter(Mandatory)]	[string]$PodDomainServiceAccountPassword,
	[Parameter(Mandatory)]	[string]$PodDomainServiceAccount,
	[Parameter(Mandatory)]	[string[]]$MachineNames,
	[Parameter(Mandatory)]	[string]$ResourceGroupName

)

for($i=0; $i -lt $MachineNames.length; $i++) 
{
  $environmentId,$rest =($MachineNames[$i]).split("\D")
  # set appropriate domain depending on EnvironmentID variable
  if($environmentId -eq 'USAZUAUDDE' -or $environmentId -eq 'EUAZUAUDDE' -or $environmentId -eq 'APAZUAUDDE')
  {
	$Domain = 'usclouddev.us.deloitte.com'
  }
  elseif($environmentId -eq 'USAZUAUD' -or $environmentId -eq 'EUAZUAUD' -or $environmentId -eq 'APAZUAUD')
  {
	$Domain = 'uscloudprod.us.deloitte.com'
  }
    
  foreach ($MachineName in $MachineNames)
  {
    # Un-Join Domain and Remove from STARS, puppet and shutdown the machine
    &"$PSScriptRoot\CloudScript.exe" "UNINSTALL" $PodDomainServiceAccount $PodDomainServiceAccountPassword
  }
}