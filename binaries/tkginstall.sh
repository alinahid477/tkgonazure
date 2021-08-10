#!/bin/bash
export $(cat /root/.env | xargs)

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