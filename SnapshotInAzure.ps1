$tagRes = Find-AzureRmResource -TagName snap -TagValue snap
$vmInfo = Get-AzureRmVM -ResourceGroupName $tagRes.ResourceId.Split("//")[4] -Name $tagRes.ResourceId.Split("//")[8]
$location = $vmInfo.Location
$resourceGroupName = $vmInfo.ResourceGroupName
$timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
$Write-Output $resourceGroupName
				
				
				Get-AzResource
				

$tagRes = Get-AzResource -TagName snap -TagValue snap
$vmInfo = Get-AzVM -ResourceGroupName $tagRes.ResourceId.Split("/")[4] -Name $tagRes.ResourceId.Split("/")[8]
$location = $vmInfo.Location
$resourceGroupName = $vmInfo.ResourceGroupName
$timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
$snapshotName = $vmInfo.Name + $timestamp
$snapshot =  New-AzSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -Location $location  -CreateOption copy
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName ascanc1tiofi1rgbkp


New-AzSnapshot -Snapshot x -SnapshotName y -ResourceGroupName


#################################################################################################################################

$tagResList = Find-AzureRmResource -TagName snap -TagValue snap
foreach($tagRes in $tagResList) { 
		if($tagRes.ResourceId -match "Microsoft.Compute")
		{
			$vmInfo = Get-AzureRmVM -ResourceGroupName $tagRes.ResourceId.Split("//")[4] -Name $tagRes.ResourceId.Split("//")[8]
				$location = $vmInfo.Location
				$resourceGroupName = $vmInfo.ResourceGroupName
                $timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
                #Snapshot name of OS data disk
                $snapshotName = $vmInfo.Name + $timestamp
				#Create snapshot configuration
                $snapshot =  New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -Location $location  -CreateOption copy
				#Take snapshot
                New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName
				
				if($vmInfo.StorageProfile.DataDisks.Count -ge 1){
						#Condition with more than one data disks
						for($i=0; $i -le $vmInfo.StorageProfile.DataDisks.Count - 1; $i++){
							#Snapshot name of OS data disk
							$snapshotName = $vmInfo.StorageProfile.DataDisks[$i].Name + $timestamp 
							#Create snapshot configuration
							$snapshot =  New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $location  -CreateOption copy
							#Take snapshot
							New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName 
							
						}
					}
				else{
						Write-Host $vmInfo.Name + " doesn't have any additional data disk."
				}
		}
		else{
			$tagRes.ResourceId + " is not a compute instance"
		}
}
