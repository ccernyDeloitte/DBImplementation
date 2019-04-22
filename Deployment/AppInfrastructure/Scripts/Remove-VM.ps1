Param ( 
    [parameter(mandatory)] [String]$ResourceGroup,
    [parameter(mandatory)] [String[]]$VMNames
) 

foreach ($VMName in $VMNames)
{
    Write-Output "ResourceGroup=$ResourceGroup"
    Write-Output "VM=$VMName"

    $environmentId,$rest =($VMName).split("\D")
    # set appropriate domain depending on EnvironmentID variable
    if($environmentId -eq 'USAZUAUDDE' -or $environmentId -eq 'EUAZUAUDDE' -or $environmentId -eq 'APAZUAUDDE')
    {
	    $Domain = 'usclouddev.us.deloitte.com'
    }
    elseif($environmentId -eq 'USAZUAUD' -or $environmentId -eq 'EUAZUAUD' -or $environmentId -eq 'APAZUAUD')
    {
	    $Domain = 'uscloudprod.us.deloitte.com'
    }
 
    # Remove the VM's and then remove the datadisks, osdisk, NICs 
    Get-AzureRmVM -ResourceGroupName $ResourceGroup | Where Name -Match $VMName | foreach { 

        $DataDisks = @($_.StorageProfile.DataDisks.Name) 
        $OSDisk = @($_.StorageProfile.OSDisk.Name)  
 
        if ($pscmdlet.ShouldProcess("$($_.Name)", "Removing VM, Disks and NIC: $($_.Name)")) 
        { 
            Write-Output "Removing VM: $($_.Name)" 
            $_ | Remove-AzureRmVM -Force -Confirm:$false 
 
            $_.NetworkProfile.NetworkInterfaces | ForEach-Object { 
                $NICName = Split-Path -Path $_.ID -leaf 
                Write-Output "Removing NIC: $NICName" 
                Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -Name $NICName | Remove-AzureRmNetworkInterface -Force 
            } 
 
            # Support to remove managed disks 
            if($_.StorageProfile.OsDisk.ManagedDisk ) { 
                ($DataDisks + $OSDisk) | ForEach-Object { 
                    Write-Output "Removing Disk: $_" 
                    Get-AzureRmDisk -ResourceGroupName $ResourceGroup -DiskName $_ | Remove-AzureRmDisk -Force 
                } 
            } 
            # Support to remove unmanaged disks (from Storage Account Blob) 
            else { 
                # This assumes that OSDISK and DATADisks are on the same blob storage account 
                # Modify the function if that is not the case. 
                $saname = ($_.StorageProfile.OsDisk.Vhd.Uri -split '\.' | Select -First 1) -split '//' |  Select -Last 1 
                $sa = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $saname 
         
                # Remove DATA disks 
                $_.StorageProfile.DataDisks | foreach { 
                    $disk = $_.Vhd.Uri | Split-Path -Leaf 
                    Write-Output "Removing Data Disk: $disk" 
                    Get-AzureStorageContainer -Name vhds -Context $Sa.Context | Get-AzureStorageBlob -Blob  $disk | Remove-AzureStorageBlob   
                } 
         
                # Remove OSDisk disk 
                $disk = $_.StorageProfile.OsDisk.Vhd.Uri | Split-Path -Leaf 
                Write-Output "Removing OSDisk: $disk"
                Get-AzureStorageContainer -Name vhds -Context $Sa.Context | Get-AzureStorageBlob -Blob  $disk | Remove-AzureStorageBlob
            }
        }
    }
}
