#!/bin/bash
export $(cat /root/.env | xargs)

printf "\n***************************************************"
printf "\n********** Starting *******************************"
printf "\n***************************************************"

printf "\nChecking Tanzu plugin...\n"

ISINSTALLED=$(tanzu management-cluster --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu plugin management-cluster not found. installing...\n"
    tanzu plugin install management-cluster
    printf "\n\n"
fi

ISINSTALLED=$(tanzu cluster --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu plugin cluster not found. installing...\n"
    tanzu plugin install cluster
    printf "\n\n"
fi

ISINSTALLED=$(tanzu login --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu plugin login not found. installing...\n"
    tanzu plugin install login
    printf "\n\n"
fi

ISINSTALLED=$(tanzu kubernetes-release --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu plugin kubernetes-release not found. installing...\n"
    tanzu plugin install kubernetes-release
    printf "\n\n"
fi

ISINSTALLED=$(tanzu pinniped-auth --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu plugin pinniped-auth not found. installing...\n"
    tanzu plugin install pinniped-auth
    printf "\n\n"
fi

ISINSTALLED=$(tanzu alpha --help)
if [[ $ISINSTALLED == *"unknown"* ]]
then
    printf "\n\ntanzu optional plugin alpha not found. installing...\n"
    tanzu plugin install alpha
    printf "\n\n"
fi

tanzu plugin list

while true; do
    read -p "Confirm if plugins are installed? [y/n] " yn
    case $yn in
        [Yy]* ) printf "\nyou confirmed yes\n"; break;;
        [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done



printf "\n\n\n Login into az using az-cli using service principal...\n"
az login --service-principal --username $AZ_TKG_APP_ID --password $AZ_TKG_APP_CLIENT_SECRET --tenant $AZ_TENANT_ID

if [ -z "$COMPLETE" ]
then
    printf "\n\n\n vm terms accept for plan $TKG_PLAN on subscription id $AZ_SUBSCRIPTION_ID...\n"
    az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan $TKG_PLAN --subscription $AZ_SUBSCRIPTION_ID

    printf "\n\n\n executing ssh-keygen for email $TKG_ADMIN_EMAIL...\n"
    ssh-keygen -t rsa -b 4096 -C "$TKG_ADMIN_EMAIL"
    ssh-add ~/.ssh/id_rsa

    printf "\n\n\n Here's your public key:\n"
    cat ~/.ssh/id_rsa.pub

    printf "\n\n\n Launching management cluster create UI.\n"
    

    tanzu management-cluster create --ui -y -v 8 --browser none


    printf "\n\n\n Done. Marking as commplete.\n"
    printf "\nCOMPLETE=YES" >> /root/.env
else
    printf "\n\n\n Already marked as complete in the .env. If this is not desired then remove the 'COMPLETE=yes' from the .env file.\n"
    printf "\nGoing straign to shell access.\n Type tanzu --help to get started\n"
fi

/bin/bash