#!/bin/bash
helpFunction()
{
    printf "\nYou must provide at least one parameter. (-n parameter recommended)\n\n"
    echo "Usage: $0"
    echo -e "\t-n name of cluster to start wizard OR"
    echo -e "\t-f /path/to/configfile"
    exit 1 # Exit script after printing help
}

while getopts "f:n:" opt
do
    case $opt in
        f ) configfile="$OPTARG" ;;
        n ) clustername="$OPTARG";;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

if [ -z "$configfile" ] 
then
    printf "no config file path.\n"
    if [ -z "$clustername" ] 
    then
        printf "no clustername given.\n"
        helpFunction
    else 
        SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        source $SCRIPT_DIR/generate_workload_cluster_config.sh -n $clustername
    fi
fi
ISCONFIGEXIST=$(ls $configfile)
# echo "is ... $ISCONFIGEXIST"
if [ -z "$ISCONFIGEXIST" ]
then
    printf "\nhere\n"
    unset configfile
fi

if [ -z "$configfile" ]
then
    printf "\n\nNo configfile found.\n\n";
    exit;
else
    printf "\n\nconfigfile: $configfile"

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
    printf "*********************************************\n"
    printf "*** starting tkg k8s cluster provision...****\n"
    printf "*********************************************\n"
    printf "\n\n\n"

    sed -i '$ d' $configfile


    printf "Creating NSG in azure\n\n"
    az network nsg create -g $AZURE_RESOURCE_GROUP -n $AZ_NSG_NAME --tags tkg $CLUSTER_NAME
    printf "\n\nDONE.\n\n\n"

    printf "Creating k8s cluster\n\n"
    tanzu cluster create --file $configfile -v 6
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