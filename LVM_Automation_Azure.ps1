$subscriptionId = "DigitateSaaSInternal"
$rg = "ASUSE11DOPSQ1RG"
$vm = "asdopsq1dwdt01"
$disk_size = "64"
$TIME = (Get-Date).AddMonths(-1).ToString("yyyyMMddhhmmss")
$disk_name = $vm + $TIME
Select-AzSubscription -Subscription $subscriptionId

########################################################################################################

Remove-Item initial_fdisk.sh
New-Item initial_fdisk.sh
Start-Sleep -s 2

########################################################################################################

Add-Content initial_fdisk.sh -Value "#!/bin/sh"
Add-Content initial_fdisk.sh -Value "rm -rf /tmp/initial_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "rm -rf /tmp/final_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "rm -rf /tmp/final_fdisk.sh"
Add-Content initial_fdisk.sh -Value "touch /tmp/final_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "touch /tmp/initial_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "touch /tmp/disk_resize.log"
Add-Content initial_fdisk.sh -Value "touch /tmp/final_fdisk.sh"
Add-Content initial_fdisk.sh -Value "chmod 777 /tmp/final_fdisk.sh"
Add-Content initial_fdisk.sh -Value "sleep 2"
Add-Content initial_fdisk.sh -Value "fdisk  -l  | grep `"Disk /dev/`" | awk '{print `$2}' | sed 's/\://' > /tmp/initial_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "cat > /tmp/final_fdisk.sh <<- `"EOF`" "
Add-Content initial_fdisk.sh -Value "#!/bin/sh"
Add-Content initial_fdisk.sh -Value "fdisk  -l  | grep `"Disk /dev/`" | awk '{print `$2}' | sed 's/\://' > /tmp/final_fdisk1.txt"
Add-Content initial_fdisk.sh -Value "devdisk=`$(comm -1 -3 /tmp/initial_fdisk1.txt /tmp/final_fdisk1.txt)"
Add-Content initial_fdisk.sh -Value "LV_PATH=`$`(lvdisplay | grep `"LV Path`" | awk `'`{print `$3`}`' | head -n 1)"
Add-Content initial_fdisk.sh -Value "LV_NAME=`$`(lvdisplay | grep `"LV Name`" | awk `'`{print `$3`}`' | head -n 1)"
Add-Content initial_fdisk.sh -Value "VG_NAME=`$`(lvdisplay | grep `"VG Name`" | awk `'`{print `$3`}`' | head -n 1)"
Add-Content initial_fdisk.sh -Value "echo `"LV path is`: `$LV_PATH `" "
Add-Content initial_fdisk.sh -Value "echo `"LV Name is`: `$LV_NAME `" "
Add-Content initial_fdisk.sh -Value "echo `"VG name is`: `$VG_NAME `" "
Add-Content initial_fdisk.sh -Value ""
Add-Content initial_fdisk.sh -Value ""
Add-Content initial_fdisk.sh -Value "pvcreate `$devdisk --force"
Add-Content initial_fdisk.sh -Value "sleep 2"
Add-Content initial_fdisk.sh -Value "vgextend `$VG_NAME `$devdisk"
Add-Content initial_fdisk.sh -Value "sleep 2"
Add-Content initial_fdisk.sh -Value "lvextend --stripes 1 `$VG_NAME/`$LV_NAME `$devdisk"
Add-Content initial_fdisk.sh -Value "sleep 2"
Add-Content initial_fdisk.sh -Value "resize2fs `$LV_PATH"
Add-Content initial_fdisk.sh -Value "sleep 2"
Add-Content initial_fdisk.sh -Value ""
Add-Content initial_fdisk.sh -Value ""
Add-Content initial_fdisk.sh -Value "EOF"
Add-Content initial_fdisk.sh -Value "echo `"/bin/sh /tmp/final_fdisk.sh >> /tmp/disk_resize.log 2`>`&1`" | at -m now + 2 minute"


########################################################################################################

Start-Sleep -s 5
Invoke-AzVMRunCommand -Name $vm -ResourceGroupName $rg -CommandId 'RunShellScript' -ScriptPath 'initial_fdisk.sh'

########################################################################################################


Write-Output "Output of the above script can be found on server $vm and on path /tmp/disk_resize.log"
$vminfo = Get-AzVM -ResourceGroupName $rg -Name $vm
Start-Sleep -s 2
$location = $vminfo.Location
$current_max_lun=(get-azurermvm -ResourceGroupName $rg -Name $vm).StorageProfile.DataDisks.lun  |  Sort-Object -Descending | Select-Object -First 1
$new_lun = $current_max_lun + 2
Start-Sleep -s 2
$diskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB $disk_size
Start-Sleep -s 2
$dataDisk = New-AzDisk -ResourceGroupName $rg -DiskName $disk_name -Disk $diskConfig
Start-Sleep -s 2
$vminfo = Add-AzVMDataDisk -VM $vminfo -Name $disk_name -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $new_lun
Start-Sleep -s 2
Update-AzVM -ResourceGroupName $rg -VM $vminfo -NoWait

