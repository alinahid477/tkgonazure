# Tanzu on azure


## Pre-Requisites


### Download and install necessary binaries

Following this documentation: 
https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-install-cli.html

Steps:
- login into https://my.vmware.com
- then go to https://my.vmware.com/en/group/vmware/downloads/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/1_x
- Navigate to "Go to downloads" for Tanzu Kubernetes Grid
- 1 file to download
    - Download VMware Tanzu CLI for Linux
        - then `mv ~/Downloads/tanzu-cli-bundle-v1.x.x-linux-amd64.tar binaries/tanzu-cli-bundle-linux-amd64.tar`


### input using .env

Below are the values required:
- AZ_TENANT_ID={search 'tenant properties' in portal to get the azure tenant id}
- AZ_TKG_APP_ID={APP_ID is also known as CLIENT_ID. in portal search 'app registration' > New Regitration. the process is documented here: https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-mgmt-clusters-azure.html#register-tanzu-kubernetes-grid-as-an-azure-client-app-3 }
- AZ_TKG_APP_CLIENT_SECRET={recorded secret from the above}
- AZ_SUBSCRIPTION_ID={azure subscription id}
- TKG_PLAN={default: k8s-1dot20dot5-ubuntu-2004 --> as this was the latest at the time of writing this. Modify it to the version your prefer, notice how it is 1dot20dot5 instead of 1.20.5. Follow the same. IMPORTANT: In Tanzu Kubernetes Grid v1.3.1, the default cluster image --plan value is k8s-1dot20dot5-ubuntu-2004, based on Kubernetes version 1.20.5 and the machine OS, Ubuntu 20.04. Run the following command} 
- TKG_ADMIN_EMAIL={this email address will be needed for private and public key purpose. Nothing will be emailed to this address. Just signature purpose stuff.}


## Docker

```
docker build . -t tkgonazure
docker run -it --rm --net=host -v ${PWD}:/root/ -v /var/run/docker.sock:/var/run/docker.sock --name tkgonazure tkgonazure /bin/bash
```

***When run the first time (.env is not marked as COMPLETE eg: does not have COMPLETE=yes) it automatically goes initiates  management cluster creation.***

***When run 2nd or more times (.env is marked as COMPLETE eg: .env file contains COMPLETE=yes) it given shell access where you can execute tanzu commands***

**When prompted for keygen do the below:**
- when promted for filename press 'enter'. to keep the file name as id_rsa
- when prompted for password provide a password you like. and reconfirm the password. Providing no password will generate clear text which is a security issue.


Yes, I am using --net=host ---> 
- since this is only a bootstrapped container scalability is not of concern 
- since I will only run this to provision tkgm on azure and only on my localmachine or a jump vm security is not of concern 

# That's it for creating Tanzu Management Cluster on Azure

Simple enough with this bootstrapped docker.


# Create workload clusters on Azure using Tanzu

Read details in the official documentation here: https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-tanzu-k8s-clusters-deploy.html

***Using this boostrapped docker when you get shell access you can use it to create workload clusters using tanzu cli on azure*** 

Here's a summarised version of creating workoad cluster using this bootstrapped docker:
- `cp .tanzu/tkg/clusterconfigs/n44jxxxx.yaml workload-clusters/my-worload-cluster1.yaml`

    Where n44jxxxx is the randomly generated (via the wizard) name of the file based on which the management cluster was created.  
- change the below values:
    - CLUSTER_NAME: my-workload-cluster1 (or give any appropriate name)
    - WORKER_MACHINE_COUNT: 3 (This is optional. Change `CLUSTER_PLAN: prod` for 3 control place node and 3 worker node. Since the default number of worker node for `CLUSTER_PLAN: dev` is 1, I am overwriting it with this value. It is also posibble to overwrite control plane node count with `CONTROL_PLANE_MACHINE_COUNT`.)


# Enable Identity Management After Management Cluster Deployment

Doc: https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-cluster-lifecycle-enable-identity-management.html

sample config in ~/identity-management/oidc/azure-oidc.sample.yaml

Steps:
- Fill out the value in the sample config file (that one is for Azure, AWS/vSphere would be similar)
- export _TKG_CLUSTER_FORCE_ROLE="management"
- export FILTER_BY_ADDON_TYPE="authentication/pinniped"
- tanzu cluster create CLUSTER-NAME --dry-run -f ~/identity-management/oidc/azure-oidc.sample.yaml > ~/identity-management/oidc/CLUSTER-NAME-example-secret.yaml
- `kubectl apply -f ~/identity-management/oidc/CLUSTER-NAME-example-secret.yaml`
- check by running `kubectl get app pinniped -n tkg-system`
- if "reconcile failed" then do `kubectl get app pinniped -n tkg-system -o yaml`




## Handy Commands



delete nsg
```
az network nsg delete -g tkgm -n tkg-az-cluster-1-node-nsg
```


When the management cluster config is already in place we can simple run the below command. (To generate the yaml always use the wizard.)
```
tanzu management-cluster create --file /root/.tanzu/tkg/clusterconfigs/l3ew4cqkzw.yaml -v 6
```


to extract the docker-on-docker ip:
```
$(cat /etc/hosts | grep $HOSTNAME | awk '{print $1}')
```

Below is not needed any more as I am using --net=host. BUT if I didn't use it then one to tell docker-on-docker (where kind will be running) is below and create port forwarding manually.
eg: https://www.conjur.org/blog/tutorial-spin-up-your-kubernetes-in-docker-cluster-and-they-will-come/
```
docker ps | grep tkg-kind | awk '{print $11}'
CLIENT_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $(docker ps | grep tkg-kind | awk '{print $11}'))
echo $CLIENT_IP

iptables -t nat -A  DOCKER -p tcp --dport 8001 -j DNAT --to-destination ${CONTAINER_IP}:8000
```