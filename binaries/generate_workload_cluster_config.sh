#!/bin/bash

while getopts "n:" opt
do
    case $opt in
        n ) clustername="$OPTARG";;
    esac
done

if [ -z "$clustername" ]
then
    printf "\n Error: No cluster name given. Exit..."
    exit 1
fi


unset CLUSTER_NAME
unset CLUSTER_PLAN
unset CLUSTER_NAME
unset AZURE_LOCATION
unset AZURE_RESOURCE_GROUP
unset AZURE_CONTROL_PLANE_MACHINE_TYPE
unset AZURE_NODE_MACHINE_TYPE
unset ENABLE_AUTOSCALER
unset AUTOSCALER_MIN_SIZE_0
unset AUTOSCALER_MAX_SIZE_0


printf "\n\nLooking for management cluster config at: ~/.config/tanzu/tkg/clusterconfigs/\n"
mgmtconfigfile=$(ls ~/.config/tanzu/tkg/clusterconfigs/ | awk -v i=1 -v j=1 'FNR == i {print $j}')
printf "\n\nFound management cluster config file: $mgmtconfigfile\n"
if [[ ! -z $mgmtconfigfile ]]
then
    mgmtconfigfile=~/.config/tanzu/tkg/clusterconfigs/$mgmtconfigfile 
    printf "Extracting values from file: $mgmtconfigfile\n"
    echo "" > ~/workload-clusters/tmp.yaml
    chmod 777 ~/workload-clusters/tmp.yaml
    while IFS=: read -r key val
    do
        if [[ $key == *@("AZURE"|"CLUSTER_CIDR"|"SERVICE"|"TKG_HTTP_PROXY_ENABLED"|"ENABLE_AUDIT_LOGGING"|"ENABLE_CEIP_PARTICIPATION"|"ENABLE_MHC"|"IDENTITY_MANAGEMENT_TYPE")* ]]
        then
            if [[ "$key" != @("AZURE_VNET_RESOURCE_GROUP"|"AZURE_FRONTEND_PRIVATE_IP"|"AZURE_ENABLE_PRIVATE_CLUSTER"|"AZURE_VNET_NAME"|"AZURE_CONTROL_PLANE_SUBNET_NAME"|"AZURE_NODE_SUBNET_NAME"|"AZURE_RESOURCE_GROUP"|"AZURE_LOCATION"|"AZURE_CONTROL_PLANE_MACHINE_TYPE"|"AZURE_NODE_MACHINE_TYPE") ]]
            then
                printf "$key: $(echo $val | sed 's,^ *,,; s, *$,,')\n" >> ~/workload-clusters/tmp.yaml
            fi
            
        fi
        
        if [[ $key == *"CLUSTER_PLAN"* ]]
        then
            CLUSTER_PLAN=$(echo $val | sed 's,^ *,,; s, *$,,')
        fi


        if [[ $key == *"AZURE_LOCATION"* ]]
        then
            AZURE_LOCATION=$(echo $val | sed 's,^ *,,; s, *$,,')
        fi

        if [[ $key == *"AZURE_CONTROL_PLANE_MACHINE_TYPE"* ]]
        then
            AZURE_CONTROL_PLANE_MACHINE_TYPE=$(echo $val | sed 's,^ *,,; s, *$,,')
        fi

        if [[ $key == *"AZURE_NODE_MACHINE_TYPE"* ]]
        then
            AZURE_NODE_MACHINE_TYPE=$(echo $val | sed 's,^ *,,; s, *$,,')
        fi


        # echo "key=$key --- val=$(echo $val | sed 's,^ *,,; s, *$,,')"
    done < "$mgmtconfigfile"

    printf "\n\nFew additional input required...\n\n"


    while true; do
        read -p "CLUSTER_NAME:(press enter to keep value extracted from parameter \"$clustername\") " inp
        if [ -z "$inp" ]
        then
            CLUSTER_NAME=$clustername
        else 
            CLUSTER_NAME=$inp
        fi
        if [ -z "$CLUSTER_NAME" ]
        then 
            printf "\nThis is a required field.\n"
        else
            printf "\ncluster name accepted: $CLUSTER_NAME"
            printf "CLUSTER_NAME: $CLUSTER_NAME\n" >> ~/workload-clusters/tmp.yaml
            break
        fi
    done
    printf "\n\n"

    read -p "CLUSTER_PLAN:(press enter to keep extracted default \"$CLUSTER_PLAN\") " inp
    if [ -z "$inp" ]
    then
        inp=$CLUSTER_PLAN
    else 
        CLUSTER_PLAN=$inp
    fi
    printf "CLUSTER_PLAN: $inp\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"

    printf "For list of azure locations do\n"
    printf "\tvisit: https://azuretracks.com/2021/04/current-azure-region-names-reference/\n"
    printf "\tOR run: \"az account list-locations -o table\"\n"
    read -p "AZURE_LOCATION:(press enter to keep extracted default \"$AZURE_LOCATION\") " inp
    if [ -z "$inp" ]
    then
        inp=$AZURE_LOCATION
    else 
        AZURE_LOCATION=$inp
    fi
    printf "AZURE_LOCATION: $inp\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"


    read -p "AZURE_RESOURCE_GROUP:(press enter to keep default \"$CLUSTER_NAME\") " inp
    if [ -z "$inp" ]
    then
        inp=$CLUSTER_NAME
        
    fi
    AZURE_RESOURCE_GROUP=$inp
    printf "AZURE_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP\n" >> ~/workload-clusters/tmp.yaml
    printf "AZURE_VNET_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"


    read -p "AZURE_CONTROL_PLANE_MACHINE_TYPE:(press enter to keep extracted default \"$AZURE_CONTROL_PLANE_MACHINE_TYPE\") " inp
    if [ -z "$inp" ]
    then
        inp=$AZURE_CONTROL_PLANE_MACHINE_TYPE
    fi
    printf "AZURE_CONTROL_PLANE_MACHINE_TYPE: $inp\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"

    while true; do
        read -p "CONTROL_PLANE_MACHINE_COUNT:(press enter to keep extracted default \"$(if [ $CLUSTER_PLAN == "dev" ] ; then echo "1"; else echo "3"; fi)\") " inp
        if [ -z "$inp" ]
        then
            if [ $CLUSTER_PLAN == "dev" ] ; then inp=1; else inp=3; fi
        fi
        if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
        then
            printf "\nYou must provide a valid value.\n"
        else
            printf "CONTROL_PLANE_MACHINE_COUNT: $inp\n" >> ~/workload-clusters/tmp.yaml
            printf "\n\n"
            break
        fi
    done

    # intentionally left prompt AZURE_WORKER_MACHINE_TYPE (where as the config key name is AZURE_NODE_MACHINE_TYPE) to match key name  WORKER_MACHINE_COUNT
    read -p "AZURE_WORKER_MACHINE_TYPE:(press enter to keep extracted default \"$AZURE_NODE_MACHINE_TYPE\") " inp
    if [ -z "$inp" ]
    then
        inp=$AZURE_NODE_MACHINE_TYPE
    fi
    printf "AZURE_NODE_MACHINE_TYPE: $inp\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"  

    while true; do
        read -p "WORKER_MACHINE_COUNT:(press enter to keep extracted default \"$(if [ $CLUSTER_PLAN == "dev" ] ; then echo "1"; else echo "3"; fi)\") " inp
        if [ -z "$inp" ]
        then
            if [ $CLUSTER_PLAN == "dev" ] ; then inp=1; else inp=3; fi
        fi
        if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
        then
            printf "\nYou must provide a valid value.\n"
        else
            printf "WORKER_MACHINE_COUNT: $inp\n" >> ~/workload-clusters/tmp.yaml
            printf "\n\n"
            AUTOSCALER_MIN_SIZE_0=$inp
            AUTOSCALER_MAX_SIZE_0=$inp
            break
        fi
    done


    while [[ -z $ENABLE_AUTOSCALER ]]; do
        read -p "ENABLE_AUTOSCALER: [y/n] " yn
        case $yn in
            [Yy]* ) ENABLE_AUTOSCALER='true'; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) ENABLE_AUTOSCALER='false'; printf "\nYou confirmed no.\n"; break;;
            * ) echo "Please answer y or n.";;
        esac        
        printf "\n"    
    done    
    if [[ -z $ENABLE_AUTOSCALER ]]
    then
        ENABLE_AUTOSCALER='false'
    fi
    printf "ENABLE_AUTOSCALER: $ENABLE_AUTOSCALER\n" >> ~/workload-clusters/tmp.yaml
    printf "\n\n"

    if [[ $ENABLE_AUTOSCALER == 'true' ]]
    then
        printf "***** Autoscaling configs ********\n\n"    
        while true; do
            read -p "AUTOSCALER_MIN_SIZE_0 (number only. Press enter to accept default=$AUTOSCALER_MIN_SIZE_0):  " inp
            if [[ -z $inp ]]
            then
                inp=$AUTOSCALER_MIN_SIZE_0
            fi

            if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
            then
                printf "\nYou must provide a valid integer value.\n"
            else
                AUTOSCALER_MIN_SIZE_0=$inp
                printf "AUTOSCALER_MIN_SIZE_0: $AUTOSCALER_MAX_SIZE_0\n" >> ~/workload-clusters/tmp.yaml
                printf "\n\n"
                break
            fi
            printf "\n"
        done

        
        while true; do
            read -p "AUTOSCALER_MAX_SIZE_0 (number only. Press enter to accept default=$AUTOSCALER_MAX_SIZE_0):  " inp
            if [[ -z $inp ]]
            then
                inp=$AUTOSCALER_MAX_SIZE_0
            fi

            if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
            then
                printf "\nYou must provide a valid integer value.\n"
            else
                AUTOSCALER_MAX_SIZE_0=$inp
                printf "AUTOSCALER_MAX_SIZE_0: $AUTOSCALER_MAX_SIZE_0\n" >> ~/workload-clusters/tmp.yaml
                printf "\n\n"
                break
            fi
            printf "\n"
        done

        unset AUTOSCALER_SCALE_DOWN_DELAY_AFTER_ADD
        while true; do
            read -p "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_ADD (number only in mins. Press enter to accept default=10):  " inp
            if [[ -z $inp ]]
            then
                inp=10
            fi

            if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
            then
                printf "\nYou must provide a valid integer value.\n"
            else
                AUTOSCALER_SCALE_DOWN_DELAY_AFTER_ADD=$(echo "$inp"m)
                printf "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_ADD: \"$AUTOSCALER_SCALE_DOWN_DELAY_AFTER_ADD\"\n" >> ~/workload-clusters/tmp.yaml
                printf "\n\n"
                break
            fi
            printf "\n"
        done

        unset AUTOSCALER_SCALE_DOWN_DELAY_AFTER_DELETE
        while true; do
            read -p "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_DELETE (number only in secs. Press enter to accept default=10):  " inp
            if [[ -z $inp ]]
            then
                inp=10
            fi

            if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
            then
                printf "\nYou must provide a valid integer value.\n"
            else
                AUTOSCALER_SCALE_DOWN_DELAY_AFTER_DELETE=$(echo "$inp"s)
                printf "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_DELETE: \"$AUTOSCALER_SCALE_DOWN_DELAY_AFTER_DELETE\"\n" >> ~/workload-clusters/tmp.yaml
                printf "\n\n"
                break
            fi
            printf "\n"
        done

        unset AUTOSCALER_SCALE_DOWN_DELAY_AFTER_FAILURE
        while true; do
            read -p "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_FAILURE (number only in min. Press enter to accept default=3):  " inp
            if [[ -z $inp ]]
            then
                inp=3
            fi

            if [[ ! $inp =~ ^[0-9]+$ || $inp < 1 ]]
            then
                printf "\nYou must provide a valid integer value.\n"
            else
                AUTOSCALER_SCALE_DOWN_DELAY_AFTER_FAILURE=$(echo "$inp"m)
                printf "AUTOSCALER_SCALE_DOWN_DELAY_AFTER_FAILURE: \"$AUTOSCALER_SCALE_DOWN_DELAY_AFTER_FAILURE\"\n" >> ~/workload-clusters/tmp.yaml
                printf "\n\n"
                break
            fi
            printf "\n"
        done

        printf "AUTOSCALER_SCALE_DOWN_UNNEEDED_TIME: \"10m\"\n" >> ~/workload-clusters/tmp.yaml
        printf "AUTOSCALER_MAX_NODE_PROVISION_TIME: \"15m\"\n" >> ~/workload-clusters/tmp.yaml

        printf "***** END Autoscaling configs ********\n\n"
    fi



    read -p "TMC_ATTACH_URL or TMC_CLUSTER_GROUP:(press enter to leave it empty and not attach to tmc OR provide a TMC attach url or Cluster Group Name) " inp
    if [[ ! -z $inp ]]
    then
        if [[ $inp == *"https:"* ]]
        then
            printf "TMC_ATTACH_URL: $inp\n" >> ~/workload-clusters/tmp.yaml
        else
            printf "TMC_CLUSTER_GROUP: $inp\n" >> ~/workload-clusters/tmp.yaml
        fi
    fi
    
    
    printf "\n\n======================\n\n"


    
    printf "INFRASTRUCTURE_PROVIDER: azure\n" >> ~/workload-clusters/tmp.yaml
    printf "AZURE_ENVIRONMENT: \"AzurePublicCloud\"\n" >> ~/workload-clusters/tmp.yaml
    printf "AZURE_ENABLE_ACCELERATED_NETWORKING: true\n" >> ~/workload-clusters/tmp.yaml
    printf "CNI: antrea\n" >> ~/workload-clusters/tmp.yaml
    printf "NAMESPACE: default\n" >> ~/workload-clusters/tmp.yaml
    
    printf "ENABLE_DEFAULT_STORAGE_CLASS: true\n" >> ~/workload-clusters/tmp.yaml
    
    printf "ENABLE_MHC_CONTROL_PLANE: true\n" >> ~/workload-clusters/tmp.yaml
    printf "ENABLE_MHC_WORKER_NODE: true\n" >> ~/workload-clusters/tmp.yaml
    printf "MHC_UNKNOWN_STATUS_TIMEOUT: 5m\n" >> ~/workload-clusters/tmp.yaml
    printf "MHC_FALSE_STATUS_TIMEOUT: 12m\n" >> ~/workload-clusters/tmp.yaml

    mv ~/workload-clusters/tmp.yaml ~/workload-clusters/$CLUSTER_NAME.yaml;

    while true; do
        read -p "Review generated file ~/workload-clusters/$CLUSTER_NAME.yaml and confirm or modify in the file and confirm to proceed further? [y/n] " yn
        case $yn in
            [Yy]* ) export configfile=$(echo "~/workload-clusters/$CLUSTER_NAME.yaml"); printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) printf "\n\nYou said no. \n\nExiting...\n\n"; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
else
    printf "\n\nNo management cluster config file found.\n\nGENERATION OF TKG WORKLOAD CLUSTER CONFIG FILE FAILED\n\n"
fi