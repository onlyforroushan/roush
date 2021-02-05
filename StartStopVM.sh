#!/bin/sh
#Passing argument start/stop
action=$1
echo "You have passed action: " $action

AZUREID="ENTER_YOUR_AZURE_LOGIN_ID"
AZUREPW="ENTER_YOUR_PASSWORD"

#####################################Login to Azure Portal Started ##############################

az logout  > /dev/null 2>&1
sleep 5
az login -u $AZUREID -p $AZUREPW  > /dev/null 2>&1

if [ $? -eq 0 ]; then
echo "Signin was successful in first attempt"
else
az logout  > /dev/null 2>&1

sleep 5

az login -u $AZUREID -p $AZUREPW  > /dev/null 2>&1
if [ $? -eq 0 ]; then
echo "Signin was successful in second attempt"
else
az logout  > /dev/null 2>&1

sleep 5

az login -u $AZUREID -p $AZUREPW  > /dev/null 2>&1
if [ $? -eq 0 ]; then
echo "Signin was successful in third attempt"
else
az logout  > /dev/null 2>&1

sleep 5

az login -u $AZUREID -p $AZUREPW
fi
fi
fi



#####################################Operation started for DigitateSaaS Subscription##############################

echo "$action operation has started for subscription DigitateSaaS"
date
rm -rf /tmp/vm_list
rm -rf /tmp/rg_list
touch /tmp/vm_list
touch /tmp/rg_list

az vm list --out table | grep bkp | awk '{print $2}' > /tmp/rg_list
az vm list --out table | grep bkp | awk '{print $1}' > /tmp/vm_list

for i in {1..40}
do
        saasvm=$(sed -n "$i"p /tmp/vm_list)
        saasrg=$(sed -n "$i"p /tmp/rg_list)
echo $saasvm
echo $saasrg
az vm $action --resource-group $saasrg --name $saasvm --no-wait > /dev/null 2>&1
done

#####################################Operation started for DigitateSaaSInternal Subscription##############################

echo "$action operation has started for subscription DigitateSaaSInternal"
date

rm -rf /tmp/vm_list
rm -rf /tmp/rg_list
touch /tmp/vm_list
touch /tmp/rg_list

az vm list --out table --subscription DigitateSaaSInternal | grep bkp | awk '{print $2}' > /tmp/rg_list
az vm list --out table --subscription DigitateSaaSInternal | grep bkp | awk '{print $1}' > /tmp/vm_list

for i in {1..40}
do
        saasintvm=$(sed -n "$i"p /tmp/vm_list)
        saasintrg=$(sed -n "$i"p /tmp/rg_list)
              
echo $saasintvm
echo $saasintrg

az vm $action --resource-group $saasintrg --name $saasintvm --subscription DigitateSaaSInternal --no-wait > /dev/null 2>&1
az vm $action --resource-group $saasintrg --name $saasintvm --no-wait > /dev/null 2>&1
done


#####################################Operation started for DigitateSaaSDemo Subscription##############################

echo "$action operation has started for subscription DigitateSaaSDemo"
date

rm -rf /tmp/vm_list
rm -rf /tmp/rg_list
touch /tmp/vm_list
touch /tmp/rg_list

az vm list --out table --subscription DigitateSaaSDemo | grep bkp | awk '{print $2}' > /tmp/rg_list
az vm list --out table --subscription DigitateSaaSDemo | grep bkp | awk '{print $1}' > /tmp/vm_list

for i in {1..40}
do
        saasdemovm=$(sed -n "$i"p /tmp/vm_list)
        saasdemorg=$(sed -n "$i"p /tmp/rg_list)
            
echo $saasdemovm
echo $saasdemorg

az vm $action --resource-group $saasdemorg --name $saasdemovm --subscription DigitateSaaSDemo --no-wait > /dev/null 2>&1
az vm $action --resource-group $saasdemorg --name $saasdemovm --no-wait > /dev/null 2>&1
done


az vm list -d -o table --subscription DigitateSaaS | grep bkp  | awk '{print $1,$4}'
az vm list -d -o table --subscription DigitateSaaSDemo | grep bkp  | awk '{print $1,$4}'
az vm list -d -o table --subscription DigitateSaaSInternal | grep bkp  | awk '{print $1,$4}'
