#!/bin/bash
helpFunction()
{
    printf "\n"
    echo "Usage: $0 -c path to the configfile"
    echo -e "\t-c /path/to/configfile"
    exit 1 # Exit script after printing help
}

while getopts "c:" opt
do
    case $opt in
        c ) configfile="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$configfile" ]
then
    printf "Some or all of the parameters are empty";
    helpFunction
else
    AZURE_RESOURCE_GROUP=$(cat $configfile | sed -r 's/[[:alnum:]]+=/\n&/g' | awk -F: '$1=="AZURE_RESOURCE_GROUP"{print $2}' | xargs)
    CLUSTER_NAME=$(cat $configfile | sed -r 's/[[:alnum:]]+=/\n&/g' | awk -F: '$1=="CLUSTER_NAME"{print $2}' | xargs)
    TMC_ATTACH_URL=$(cat $configfile | grep -o 'https://[^"]*' | xargs)
    TMC_ATTACH_URL=$(echo "\"$TMC_ATTACH_URL\"")
    AZ_NSG_NAME=$(echo "$CLUSTER_NAME-node-nsg")
    printf "\n below information were extracted from the file supplied:\n"
    printf "\nAZURE_RESOURCE_GROUP=$AZURE_RESOURCE_GROUP"
    printf "\nCLUSTER_NAME=$CLUSTER_NAME"
    printf "\nTMC_ATTACH_URL=$TMC_ATTACH_URL"
    printf "\nAZ_NSG_NAME=$AZ_NSG_NAME (derived from cluster name)"
    printf "\n\n\n"
    while true; do
        read -p "Confirm if the information is correct? [y/n] " yn
        case $yn in
            [Yy]* ) confirmation='yes'; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

if [[ ! -z "$confirmation" ]]
then
    printf "\n\n\n"
    printf "*****************************************\n"
    printf "***starting k8s cluster provision.....***\n"
    printf "*****************************************\n"
    printf "\n\n\n"

    printf "Creating NSG in azure"
    az network nsg create -g $AZURE_RESOURCE_GROUP -n $AZ_NSG_NAME --tags tkg $CLUSTER_NAME
    printf "\n\nDONE.\n\n\n"

    printf "Creating k8s cluster"
    tanzu cluster create --file $configfile
    printf "\n\nDONE.\n\n\n"


    printf "Waiting 5 mins to complete cluster create"
    sleep 5m
    printf "\n\nDONE.\n\n\n"

    printf "Getting cluster info"
    tanzu cluster get $CLUSTER_NAME
    printf "\n\nDONE.\n\n\n"

    printf "Attaching cluster to TMC"
    kubectl create -f $TMC_ATTACH_URL
    printf "\n\nDONE.\n\n\n"


    printf "\n\n\n"
    printf "*******************\n"
    printf "***COMPLETE.....***\n"
    printf "*******************\n"
    printf "\n\n\n"
fi