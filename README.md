# tkg on azure

## Pre-Requisites

### Download and install necessary binaries

Following this documentation: 
https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-install-cli.html

Steps:
- login into https://my.vmware.com
- then go to https://my.vmware.com/en/group/vmware/downloads/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/1_x
- Navigate to "Go to downloads" for Tanzu Kubernetes Grid
- 2 files to download
    - Download VMware Tanzu CLI for Linux
        - then `mv ~/Downloads/tanzu-cli-bundle-v1.x.x-linux-amd64.tar binaries/tanzu-cli-bundle-linux-amd64.tar`
    - Download kubectl cluster cli v1.x.x for Linux
        - then  `mv ~/Downloads/kubectl-linux-v1.20.5-vmware.1.gz binaries/kubectl-linux-vmware.gz`


### Docker

```
docker build . -t tkgonazure
docker run -it --rm -p 61234:61234 -v ${PWD}:/root/ -v /var/run/docker.sock:/var/run/docker.sock --name tkgonazure tkgonazure /bin/bash
```