###############################################GETTING USER INPUT#############################################
$rg_name = "asuse11dopsq1rg"
$dr_location = "eastus"
##############################################################################################################



###############################################SETTING SUBSCRIPTION#############################################
clear
Select-AzureRmSubscription -SubscriptionName DigitateSaasInternal
##############################################################################################################


################################Creating DR_RG/STORAGE_ACCOUNT/CONTAINER########################################
$dr = "bkp"
$STORAGE = "bkp"
$dr_rg_name = $rg_name+$dr
$storageAccountName = $dr_rg_name+$STORAGE
New-AzureRmResourceGroup -Name $dr_rg_name -Location $dr_location -Force
Start-Sleep -s 2
New-AzureRmStorageAccount -ResourceGroupName $dr_rg_name -Name $storageAccountName -Location $dr_location -SkuName Standard_RAGRS -Kind StorageV2
Start-Sleep -s 2
$destContainer = "drcontainer"
$context = (Get-AzStorageAccount -ResourceGroupName $dr_rg_name -AccountName $storageAccountName).context
New-AzureRmStorageContainer -Name $destContainer -StorageAccountName $storageAccountName -ResourceGroupName $dr_rg_name
##############################################################################################################


$vmInfo = Get-AzureRmVM -ResourceGroupName $rg_name
$VMlists = $vmInfo.Name
Write-Host "Hey Greetings !! Sit Back and relax . " -ForegroundColor Cyan 
Start-Sleep -s 1
$i = 1

ForEach($VMlist in $VMlists)
{
Write-Host "I have started my work with $VMlist VM . And this is No:$i VM in List ." -ForegroundColor Cyan 
Start-Sleep -s 1
$VMName = $VMlist
Write-Host $VMName
#$rg_name = (Get-AzureRmResource -Name $VMName -ResourceType "Microsoft.Compute/virtualMachines").ResourceGroupName
$OSDisks = (Get-AzureRMVM –Name $VMName –ResourceGroupName $rg_name).StorageProfile.OsDisk.Name
$DataDisks = (Get-AzureRMVM –Name $VMName –ResourceGroupName $rg_name).StorageProfile.DataDisks.name
$i = 1

ForEach($OSDisk in $OSDisks)
{
Write-Host "OS-Disk No $i is : $OSDisk"
Write-Host "Now I am creating snapshot of OSDisk $i " -ForegroundColor White
$Disk = Get-AzureRmDisk -ResourceGroupName $rg_name -Name $OSDisk
$OsDiskSku = (Get-AzureRmDisk -ResourceGroupName $rg_name -Name $OSDisk).sku.Name
$location = (Get-AzureRmResource -Name $OSDisk).Location
$time = (Get-Date -Format HHMM)
$day = (Get-Date).Day
$month = Get-Date -Format MMM
$year = (Get-Date).Year
$OSSnapshotName = ($VMName + '_' + $time + '_' + $day + '_' + $month + '_' + $year + '_Snapshot_OS_Disk_' + $i)
$Snapshot = New-AzureRmSnapshotConfig -SourceUri $Disk.Id -CreateOption Copy -Location $location
New-AzureRmSnapshot -Snapshot $Snapshot -SnapshotName $OSSnapshotName -ResourceGroupName $rg_name | Out-Null

#$VM_ID=(Get-AzureRmDisk -ResourceGroupName $rg_name -DiskName $OSDisk).ManagedBy
#$VM_NAME=$VM_ID.Split('/')[-1]
#Write-Host "VM is: " $VM_NAME
Start-Sleep -s 10
$VMStringFormat = $VMName.ToString()
$tags = @{"VM_NAME"=$VMStringFormat}
Set-AzResource -ResourceGroupName $rg_name -Name $OSSnapshotName -ResourceType "Microsoft.Compute/snapshots" -Tag $tags -Force

Write-Host "Snapshot Name : $OSSnapshotName" -ForegroundColor Green
Start-Sleep -s 4


#Move Snap to storage account 
$blobName = $OSSnapshotName
#Mention storage account Name
$storageAccountRGName = (Get-AzureRmResource -Name $storageAccountName -ResourceType "Microsoft.Storage/storageAccounts").ResourceGroupName
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccountRGName -Name $storageAccountName).Value | Select-Object -First 1
$SnapshotAccessURL = (Grant-AzureRMSnapshotAccess -ResourceGroupName $rg_name -SnapshotName $blobName -Access 'Read' -DurationInSecond 172800).AccessSAS
$absoluteUri = $SnapshotAccessURL
$storageAccountType = (Get-AzureRmStorageAccount -ResourceGroupName $storageAccountRGName -Name $storageAccountName).Sku.Name
$storageAccountId = (Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountRGName).Id
$storageAccountLocation = (Get-AzureRmStorageAccount -Name "asuse11dopsq1rgbkpbkp" -ResourceGroupName "asuse11dopsq1rgbkp").location
$destContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Start-AzureStorageBlobCopy -AbsoluteUri $absoluteUri -DestContainer $destContainer -DestContext $destContext -DestBlob $blobName -Force
Start-Sleep -s 5
Write-Host "Slept for 5 seconds"
Write-Host "I have moved This $OSSnapshotName to storage account ." -ForegroundColor Green
$OSVHDuri = $(Get-AzureStorageBlob -blob $OSSnapshotName -Container $destContainer -Context $context).ICloudBlob.uri.AbsoluteUri

Write-Host "URI of blob is: " $OSVHDuri

#$NewOssnapshotConfig = New-AzSnapshotConfig -AccountType $OsDiskSku -Location $storageAccountLocation -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $OSVHDuri 
#New-AzSnapshot -Snapshot $NewOssnapshotConfig -ResourceGroupName $storageAccountRGName -SnapshotName $blobName


$i =$i+1

}

$i = 1
ForEach($DataDisk in $DataDisks)
{
Write-Host "Data-Disk No $i is : $DataDisk"
$VM_ID=(Get-AzureRmDisk -ResourceGroupName $rg_name -DiskName $DataDisk).ManagedBy
$VM_NAME=$VM_ID.Split('/')[-1]
Write-Host "VM is: " $VM_NAME
Write-Host "Now I am creating snapshot of Data Disk $i " -ForegroundColor White
$Disk = Get-AzureRmDisk -ResourceGroupName $rg_name -Name $DataDisk
$location = (Get-AzureRmResource -Name $DataDisk).Location
$time = (Get-Date -Format HHMM)
$day = (Get-Date).Day
$month = Get-Date -Format MMM
$year = (Get-Date).Year
$DataSnapshotName = ($VMName + '_' + $time + '_' + $day + '_' + $month + '_' + $year + '_Snapshot_Data_Disk_' + $i)
$Snapshot = New-AzureRmSnapshotConfig -SourceUri $Disk.Id -CreateOption Copy -Location $location
New-AzureRmSnapshot -Snapshot $Snapshot -SnapshotName $DataSnapshotName -ResourceGroupName $dr_rg_name | Out-Null
Write-Host "Snapshot Name : $DataSnapshotName" -ForegroundColor Green

Start-Sleep -s 10
Set-AzResource -ResourceGroupName $rg_name -Name $DataSnapshotName -ResourceType "Microsoft.Compute/snapshots" -Tag $tags -Force


#Move Snap to storage account 
$blobName = $DataSnapshotName
#Mention storage account Name

$storageAccountRGName = (Get-AzureRmResource -Name $storageAccountName -ResourceType "Microsoft.Storage/storageAccounts").ResourceGroupName
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccountRGName -Name $storageAccountName).Value | Select-Object -First 1
$SnapshotAccessURL = (Grant-AzureRMSnapshotAccess -ResourceGroupName $rg_name -SnapshotName $blobName -Access 'Read' -DurationInSecond 172800).AccessSAS
$absoluteUri = $SnapshotAccessURL
$destContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Start-AzureStorageBlobCopy -AbsoluteUri $absoluteUri -DestContainer $destContainer -DestContext $destContext -DestBlob $blobName -Force
Start-Sleep -s 2
Write-Host "I have moved This $DataSnapshotName to storage account ." -ForegroundColor Green
$i ++

}
}
