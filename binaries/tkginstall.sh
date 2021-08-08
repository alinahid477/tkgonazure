#!/bin/bash
export $(cat /root/.env | xargs)

printf "\n\n\n Login into az using az-cli using service principal...\n"
az login --service-principal --username $AZ_TKG_APP_ID --password $AZ_TKG_APP_CLIENT_SECRET --tenant $AZ_TENANT_ID

if [ -z "$COMPLETE" ]
then
    printf "\n\n\n vm terms accept for plan $TKG_PLAN on subscription id $AZ_SUBSCRIPTION_ID...\n"
    az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan $TKG_PLAN --subscription $AZ_SUBSCRIPTION_ID

    printf "\n\n\n executing ssh-keygen for email $TKG_ADMIN_EMAIL...\n"
    /dev/zero/ ssh-keygen -t rsa -b 4096 -C "$TKG_ADMIN_EMAIL"
    ssh-add ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub

    printf "\n\n\n Launching management cluster create UI.\n"
    printf "\nOpen localhost:$TKG_MANAGEMENT_UI_EXPOSE_PORT in your browser to complete the process using UI.\n"

    BINDIP=$(cat /etc/hosts | grep $HOSTNAME | awk '{print $1}'):$TKG_MANAGEMENT_UI_EXPOSE_PORT

    tanzu management-cluster create --ui -y -v 8 --browser none --bind $BINDIP    
fi

/bin/bash