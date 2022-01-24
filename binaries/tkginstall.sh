#!/bin/bash
export $(cat /root/.env | xargs)


returnOrexit()
{
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
    then
        return
    else
        exit
    fi
}

helpFunction()
{
    printf "\nNo parameter to pass.\nThis is a wizard based installation.\n"
    printf "\tThe wizard will take care of few of the installation pre-requisites through asking for some basic input. Just follow the prompt.\n"
    printf "\tOnce the prerequisites conditions are staisfied the wizard will then proceed on launching tkg installation UI.\n"
    printf "\tWhen using bastion host the wizard will connect to bastion host and check for the below prequisites:\n"
    printf "\t\t- Bastion host must have docker engine (docker ce or docker ee) installed. (if you do not have it installed please do so now)\n"
    printf "\t\t- Bastion host must have php installed. (if you do not have it installed please do so now).\n"
    printf "\n\n"
    returnOrexit
}


while getopts "h:" opt
do
    case $opt in
        h ) helpFunction ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

unset TKG_ADMIN_EMAIL


printf "\n***************************************************"
printf "\n********** Starting *******************************"
printf "\n***************************************************"



if [ -z "$COMPLETE" ]
then

    printf "\n\nchecking pre-requisites..\n"
    if [[ -z $TKG_PLAN ]]
    then
        printf "\n\nERROR: No TKG_PLAN value found. Exiting...\n\n"
        returnOrexit
    fi

    if [[ -z $AZ_SUBSCRIPTION_ID ]]
    then
        printf "\n\nERROR: No AZ_SUBSCRIPTION_ID value found. Exiting...\n\n"
        returnOrexit
    fi

    printf "\n\n\n vm terms accept for plan $TKG_PLAN on subscription id $AZ_SUBSCRIPTION_ID...\n"
    az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan $TKG_PLAN --subscription $AZ_SUBSCRIPTION_ID

    isidrsa=$(ls ~/.ssh/id_rsa)
    if [[ -n $isidrsa ]]
    then
        isidrsa=$(ls ~/.ssh/id_rsa.pub)
    fi

    if [[ -z $isidrsa ]]
    then
        printf "\n\n\n executing ssh-keygen for email $TKG_ADMIN_EMAIL...\n"
        ssh-keygen -t rsa -b 4096 -C "$TKG_ADMIN_EMAIL"
        ssh-add ~/.ssh/id_rsa
    fi
    

    printf "\n\n\n Here's your public key:\n"
    cat ~/.ssh/id_rsa.pub


    if [[ -n $MANAGEMENT_CLUSTER_CONFIG_FILE ]]
    then
        printf "\nLaunching management cluster create using $MANAGEMENT_CLUSTER_CONFIG_FILE...\n"
        tanzu management-cluster create --file $MANAGEMENT_CLUSTER_CONFIG_FILE -v 9
    else
        printf "\nLaunching management cluster create using UI...\n"
        tanzu management-cluster create --ui -y -v 9 --browser none
    fi

    ISPINNIPED=$(kubectl get svc -n pinniped-supervisor | grep pinniped-supervisor)

    if [[ -n $ISPINNIPED ]]
    then
        printf "\n\n\nBelow is details of the service for the auth callback url. Update your OIDC/LDAP callback accordingly.\n"
        kubectl get svc -n pinniped-supervisor
        printf "\nDocumentation: https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-mgmt-clusters-configure-id-mgmt.html\n"
    fi

    printf "\n\n\nDone. Marking as commplete.\n\n\n"
    sed -i '/COMPLETE/d' .env
    printf "\nCOMPLETE=YES" >> /root/.env
else
    printf "\n\n\n Already marked as complete in the .env. If this is not desired then remove the 'COMPLETE=yes' from the .env file.\n"
fi

printf "\n\n\nRUN ~/binaries/tkgworkloadwizard.sh --help to start creating workload clusters.\n\n\n"