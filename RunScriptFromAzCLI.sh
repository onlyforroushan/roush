#!/bin/sh
az login
read -p "Please enter 'Y' if login was successful. " -n 1 -r
echo -e ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi
echo "MAKE SURE YOU HAVE UPDATED THE VM AND RG NAME IN FILE /tmp/vm_rg.txt"
echo -e ""
subscriptionId=XXXXXXXXXXXXXXXXXXXXX
echo "Subscription ID  you chose is: " $subscriptionId
az account set --subscription $subscriptionId
echo "Please enter the script path, which you want to execute (like: /tmp/sc.sh) : "
read SCRIPT_PATH
while read -r line
do
case "$line" in \#*) continue ;; esac
VM_NAME=$(echo $line | awk '{print $1}')
RG_NAME=$(echo $line | awk '{print $2}')
echo "RG you chose for VM "$VM_NAME" is: " $RG_NAME
echo "Running script "$SCRIPT_PATH" on VM: " $VM_NAME
az vm run-command invoke -g $RG_NAME -n $VM_NAME --command-id RunShellScript --scripts $SCRIPT_PATH
done < /tmp/vm_rg.txt
