#!/bin/sh
echo -e "MAKE SURE YOU ARE CONNECTED TO AZURE PORTAL\n"

subscriptionId="7f555555544444423542rthda1fea-1ec4444444444c-4444444424a7f-8e33333333344-d9dedsaaaaaaaaaa"

echo "Subscription ID  you chose is: " $subscriptionId
az account set --subscription $subscriptionId

echo "Please enter the name of the VM which you want to scale out: "
read VM_NAME

echo "you have entered: " $VM_NAME
read -p "Please enter 'Y' if it is Correct. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Please enter the NEW VM name  which will be created: "
read NEW_VM_NAME

echo "you have entered: " $NEW_VM_NAME
read -p "Please enter 'Y' if it is Correct. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
exit 1
fi


echo "Please enter the RG name of the VM which you want to scale out: "
read RG_NAME

echo "you have entered: " $RG_NAME
read -p "Please enter 'Y' if it is Correct. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Please enter the list of services which you want to disable without comma and one space in between, like sshd analytics"
read services

read -p "Please enter 'Y' if it is Correct. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
exit 1
fi

echo ""
echo "Definining time variable for resource references."
NOW=`date '+%F_%H_%M_%S'`
echo "Time reference variable is: " $NOW

os_disk_name=$(az vm show -d -g $RG_NAME -n $VM_NAME --query "storageProfile.osDisk.name" -o tsv)
data_disk_name=$(az vm show -d -g $RG_NAME -n $VM_NAME --query "storageProfile.dataDisks[].name" -o tsv)
echo ""
echo -e "OS Disk is: "
echo "1. " $os_disk_name
echo -e ""
echo "Data Disks is/are:"
i=1
while IFS= read -r line

do
   echo $i"." $line

   i="$(($i+1))"

done <<< "$data_disk_name"
echo ""

#data_disk_name=$(az disk list --query "[].{Name:name}" --output tsv | grep $VM_NAME | grep -v Unattached | grep -v ASR | grep -v -i OsDisk)
#os_disk_name=$(az disk list --query "[].[name, diskState]" --output tsv | grep $VM_NAME | grep -i os | grep -v lun | grep -v Unattached | awk '{print $1}' | grep -v ASR | head -n 1)
#nic_name=$VM_NAME"nic01"
#nic_name=$(az network nic list --query "[].[name]" -o tsv | grep $VM_NAME | head -n 1)
#vnet_name=$(az network vnet list --resource-group $RG_NAME --query "[].[name]" -o tsv)
#subnet_name=$(az vm nic show -g $RG_NAME --vm-name $VM_NAME --nic $nic_name | grep id | grep subnet | awk '{print $2}' | sed s/\"//g | sed s/\,//g | sed 's/\//\n/g' | tail -n 1)
#subnet_id=$(az vm nic show -g $RG_NAME --vm-name $VM_NAME --nic $nic_name | grep id | grep subnet | awk '{print $2}' | sed s/\"//g | sed s/\,//g)
#echo "Vnet Name is: " $vnet_name
#echo "Subnet Name is: " $subnet_name
#os_skuname=$(az disk list --query '[].[name, sku.name]' --output tsv | grep $os_disk_name | awk '{print $2}' | head -n 1)
#os_disksize=$(az disk list --query '[].[name, diskSizeGb]' --output tsv | grep $os_disk_name | awk '{print $2}' | head -n 1)
#az vm create -g $RG_NAME -n $NEW_VM_NAME --computer-name $NEW_VM_NAME --attach-os-disk $New_Os_Disk --size $VM_SIZE --nics $new_nic_name --subnet $subnet_id --public-ip-address "" --os-type linux

nic_name=$(az vm show -g $RG_NAME -n $VM_NAME --query "networkProfile.networkInterfaces[].id" -o tsv)
echo -e "NIC Id is: " $nic_name


subnet_id=$(az vm nic show -g $RG_NAME --vm-name $VM_NAME --nic $nic_name --query "ipConfigurations[].subnet.id" -o tsv)
echo -e "subnet id is: " $subnet_id


os_skuname=$(az disk show -n $os_disk_name -g $RG_NAME --query sku.name -o tsv)
echo -e "OS Disk SKU is: " $os_skuname

os_disksize=$(az disk show -n $os_disk_name -g $RG_NAME --query diskSizeGb -o tsv)
echo -e "OS Disk Size in GB: " $os_disksize
echo ""
#New_Os_Disk="$os_disk_name$NOW""_NEW"
New_Os_Disk=$(echo $os_disk_name | sed "s/$VM_NAME/$NEW_VM_NAME/g")
echo -e "New OS Disk will be: " $New_Os_Disk
VM_SIZE=$(az vm show -n $VM_NAME -g $RG_NAME --query hardwareProfile.vmSize -o tsv)
echo -e "VM Size will be: " $VM_SIZE
os_snapshot_name="$os_disk_name$NOW"
echo -e "OS Snapshot name will be: " $os_snapshot_name

i=1
while IFS= read -r line

do
   echo -e ""
   echo "This is Data Disk Number- " $i
   echo "Data Disk name is: " $line
   data_snapshot_name="$line$NOW"
   echo "Snapshot name will be: "$data_snapshot_name
   #data_skuname=$(az disk list --query '[].[name, sku.name]' --output tsv | grep $line | awk '{print $2}' | head -n 1)
   data_skuname=$(az disk show -n $line -g $RG_NAME --query sku.name -o tsv)
   echo "Data Disk SKU is: " $data_skuname
   #data_disksize=$(az disk list --query '[].[name, diskSizeGb]' --output tsv | grep $line | awk '{print $2}' | head -n 1)
   data_disksize=$(az disk show -n $line -g $RG_NAME --query diskSizeGb -o tsv)
   echo "Data Disk Size in GB: " $data_disksize
   New_Data_Disk=$(echo $line | sed "s/$VM_NAME/$NEW_VM_NAME/g")
   echo "New Data Disk will be: " $New_Data_Disk
   i="$(($i+1))"

done <<< "$data_disk_name"

echo ""
read -p "Above values seems Correct? Please enter 'Y' for yes. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


echo "disabling services on VM $VM_NAME "
az vm run-command invoke -g $RG_NAME -n $VM_NAME --command-id RunShellScript --scripts "systemctl disable $services"

read -p "Please press 'Y' if the services were successfully disabled. Check the msge and confirm. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

new_nic_name=$NEW_VM_NAME"nic01"
echo "Creating nic: " $new_nic_name
az network nic create --name $new_nic_name --resource-group $RG_NAME --subnet $subnet_id --accelerated-networking true
echo -e ""
echo "Creating Snapshot of disk " $os_disk_name
az snapshot create -g $RG_NAME -n $os_snapshot_name --source $os_disk_name
echo -e ""

os_snapshot_id=$(az snapshot list --resource-group $RG_NAME --query [].[id] -o tsv | grep $os_snapshot_name)
echo "OS Snapshot Id is: " $os_snapshot_id
echo -e ""
sleep 20
echo "Creating OS Disk: " $New_Os_Disk
az disk create --resource-group $RG_NAME --name $New_Os_Disk --sku $os_skuname --size-gb $os_disksize --source $os_snapshot_id
sleep 10

echo "Creating New VM: " $NEW_VM_NAME
az vm create -g $RG_NAME -n $NEW_VM_NAME --computer-name $NEW_VM_NAME --attach-os-disk $New_Os_Disk --size $VM_SIZE --nics $new_nic_name --os-type linux

j=1
echo "VM created and OS disk attached. Now finding all attached data disk and doing below operations."
while IFS= read -r line

do
   echo -e ""
   echo "This is Data Disk No: " $j
   echo "Data Disk name is: " $line
   data_snapshot_name="$line$NOW"
   echo "Snapshot name will be: "$data_snapshot_name
   data_skuname=$(az disk list --query '[].[name, sku.name]' --output tsv | grep $line | awk '{print $2}' | head -n 1)
   echo "Data Disk SKU is: " $data_skuname
   data_disksize=$(az disk list --query '[].[name, diskSizeGb]' --output tsv | grep $line | awk '{print $2}' | head -n 1)
   echo "Data Disk Size in GB: " $data_disksize
   New_Data_Disk=$(echo $line | sed "s/$VM_NAME/$NEW_VM_NAME/g")
   echo "New Data Disk will be: " $New_Data_Disk
   echo "Creating Data Disk Snapshot: " $data_snapshot_name
   az snapshot create -g $RG_NAME -n $data_snapshot_name --source $line
   data_snapshot_id=$(az snapshot list --resource-group $RG_NAME --query [].[id] -o tsv | grep $data_snapshot_name)
   sleep 10
   echo "Data Snapshot Id is: " $data_snapshot_id
   echo "Creating Data Disk" $New_Data_Disk
   az disk create --resource-group $RG_NAME --name $New_Data_Disk --sku $data_skuname --size-gb $data_disksize --source $data_snapshot_id
   echo "Attaching Data Disk: " $New_Data_Disk
   az vm disk attach -g $RG_NAME --vm-name $NEW_VM_NAME --name $New_Data_Disk
   j="$(($j+1))"

done <<< "$data_disk_name"
echo -e ""
echo "restarting NEW VM ..."
az vm restart -g $RG_NAME -n $NEW_VM_NAME --no-wait
echo -e ""
sleep 60
echo "Setting Up hostname on NEW VM"
az vm run-command invoke -g $RG_NAME -n $NEW_VM_NAME --command-id RunShellScript --scripts "hostnamectl set-hostname $NEW_VM_NAME"
echo -e ""
echo "Operation Of New VM $NEW_VM_NAME finished Successfully."
echo "Enabling services on " $VM_NAME
echo -e ""
az vm run-command invoke -g $RG_NAME -n $VM_NAME --command-id RunShellScript --scripts "systemctl enable $services"
echo -e ""
echo -e ""
echo "Bye Bye..."
