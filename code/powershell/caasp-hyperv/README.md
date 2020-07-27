# SUSE Container As A Service Platform on Hyper-V

The script **caasp-hyperv.ps1** is used to manage the deployment of a CaaSP cluster
on Hyper-V based on the **VHD**|**VHDX** images. By default, it reads a configuration
file **caasp-hyperv.vars** in the script directory and generate an hvstate file
in json **caasp-hyperv-$stackName.hvstate** plus a copy in **caasp-hyperv.hvstate**.

The nodes can be configured with cloud-init by editing the default **cloud-init** files
in script directory.

## General notes

Requirements for each Hyper-V host:

* The same virtual machine network switch must exist
* The VHD and IMAGE directories must exist

The following files must be in the script directory:

* oscdimg.exe (tool to create the cloud-init, executable can be found in WAIK)
* cloud-init.admin (admin node cloud init)
* cloud-init.cls (master/worker) cloud init)
* caasp-hyperv.vars (configuration file, can be overridden)

The command line arguments takes precedence on config file options.

Memory must always be expressed in **mega-bytes**.

If image is in .vhdfixed.xz, the action **fetchimage** will first download the compressed image
in XZ formatand extracted in VHD format (.vhd)

If image is in .vhd|.vhdx, the action **fetchimage** will just download the image.

Using -Force on deploy|destroy does not require the hvstate file.

See [caasp-hyperv.hvstate.example](caasp-hyperv.hvstate.example) for an example
of a generated state file.

A VLAN will not be set on the network cards, if no VLAN ID is provided.

The virtual machines hard disk are created in **differencing** from the fixed
image in VHD|VHDX format (see fetchimage description).



## Actions

### listimages

* List images on each hyper-v hosts

```console
caasp-hyperv.ps1 listimages
```

### fetchimage

* Fetch an image on the nodes

```console
caasp-hyperv.ps1 fetchimage -caaspImageSourceUrl `
  http://image-repository/SUSE-CaaS-Platform-3.0-for-MS-HyperV.x86_64-3.0.0-GM.vhdfixed.xz
```

```console
caasp-hyperv.ps1 fetchimage -caaspImageSourceUrl `
  http://image-repository/SUSE-CaaS-Platform-4.0-for-MS-HyperV.x86_64-4.0.0-GM.vhdx
```

### deleteimage

* Delete an image on each hyper-v hosts

```console
caasp-hyperv.ps1 deleteimage -caaspImage SUSE-CaaS-Platform-3.0-for-MS-HyperV.x86_64-3.0.0-GM.vhd
```

### plan

* Test and validate the configuration

```console
caasp-hyperv.ps1 plan -stackName suse `
                      -caaspImage SUSE-CaaS-Platform-3.0-for-MS-HyperV.x86_64-3.0.0-GM.vhd `
                      -adminRam 16384mb `
                      -adminCpu 4 `
                      -masters 3 `
                      -masterRam 16384mb `
                      -masterCpu 4 `
                      -workers 36 `
                      -workerRam 8192mb
```

### deploy

* Deploy a cluster with the default configuration

```console
caasp-hyperv.ps1 deploy -stackName suse `
                        -caaspImage SUSE-CaaS-Platform-3.0-for-MS-HyperV.x86_64-3.0.0-GM.vhd
```

* Deploy a cluster with a specific configuration

```console
caasp-hyperv.ps1 deploy -stackName suse `
                        -caaspImage SUSE-CaaS-Platform-3.0-for-MS-HyperV.x86_64-3.0.0-GM.vhd `
                        -adminRam 16384mb `
                        -adminCpu 4 `
                        -masters 3 `
                        -masterRam 16384mb `
                        -masterCpu 4 `
                        -workers 36 `
                        -workerRam 8192mb
```

### status

* Get status of a specific stack

```console
caasp-hyperv.ps1 status -stackName suse
```

* Get status of all deployments

```console
caasp-hyperv.ps1 status
```

### destroy

* Destroy a cluster from the default configuration

```console
caasp-hyperv.ps1 destroy -stackName suse
```

* Destroy a cluster from a specific configuration

```console
caasp-hyperv.ps1 destroy -stackName suse `
                         -adminCpu 4 `
                         -masters 3 `
                         -workers 36
```

## CLI syntax

```
<#
.SYNOPSIS
  Deploy and manage the deployment of CaaSP Cluster on Hyper-V
  
  See README.md in https://github.com/kubic-project/automation

.DESCRIPTION
  Deploy and manage the deployment of CaaSP Cluster on Hyper-V

.PARAMETER computeHosts
  Description: Hyperv-V Hosts
  Actions: all
  Expect: string separated by coma ","

.PARAMETER stackName
  Description: Name of the stack to deploy, used to prevent cluster interfering deployments
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER caaspImageSourceUrl
  Description: CaaSP image to download on hyperv hosts, the format image is vhdfixed.xz,vhd,vhdx
  Actions: fetchimage
  Expect: string

.PARAMETER caaspImage  
  Description: CaaSP image to deploy, the format is IMAGE.vhd|vhdx, can be different from the one in source-url
  Actions: deleteimage,plan,deploy,destroy
  Expect: string

.PARAMETER imageStoragePath
  Description: Location where the image will be downloaded and extracted
  Actions: deleteimage,plan,deploy
  Expect: string

.PARAMETER vhdStoragePath
  Description: Location where the virtual hard disks will be stored
  Actions: deleteimage,plan,deploy,destroy
  Expect: string

.PARAMETER vmVlanId
  Description: Set a VLAN on the virtual machines network adapter cards
  Actions: deploy
  Expect: integer

.PARAMETER vmSwitch
  Description: Set the virtual machine network switch
  Actions: plan,deploy
  Expect: string

.PARAMETER estimatedVmSize
  Description: Estimated size of a Virtual Machine in giga-bytes
  Actions: plan
  Expect: int
  Default: 15
  
.PARAMETER adminNodePrefix
  Description: Base name of the admin node
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER adminRam
  Description: Memory of the admin node, MUST be configured in mega-bytes
  Actions: plan,deploy
  Expect: string
  
.PARAMETER adminCpu
  Description: Virtual CPUs of the admin node
  Actions: plan,deploy
  Expect: integer

.PARAMETER masters
  Description: Number masters to deploy
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER masterNodePrefix
  Description: Base name of the master nodes
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER masterRam
  Description: Memory of the master nodes, MUST be configured in mega-bytes
  Actions: plan,deploy
  Expect: string

.PARAMETER masterCpu
  Description: Virtual CPUs of the master nodes
  Actions: plan,deploy
  Expect: integer

.PARAMETER workers
  Description: Number workers to deploy
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER workerNodePrefix
  Description: Base name of the worker nodes
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER workerRam
  Description: Memory of the worker nodes, MUST be configured in mega-bytes
  Actions: plan,deploy
  Expect: string

.PARAMETER workerCpu
  Description: Virtual CPUs of the worker nodes
  Actions: plan,deploy
  Expect: integer

.PARAMETER varFile
  Description: Configuration file with deployment variables, every parameters in
               the file can be pass on command line and takes precedence.
  Actions: all
  Expect: string
  Default: .\caasp-hyperv.vars

.PARAMETER Force
  Description: If set with 'deploy', existing VMs will be destroyed and redeployed.
               If set with 'destroy', you will not have to confirm when prompted.
  Actions: deploy,destroy
  Expect: None
  Default: false

.INPUTS
  None

.OUTPUTS
  HYPERV STATE FILE: caasp-hyper.hvstate
  HYPERV STACK STATE FILE: caasp-hyper-$stackName.hvstate
  LOG FILE: $action-$date.log

.NOTES
  Author: QA CAASP TEAM

.EXAMPLE
  Retrieve available images
  .\caasp-hyperv.ps1 listimages
  
  Retrieve image on nodes
    .\caasp-hyperv.ps1 fetchimage -caaspImageSourceUrl http://url/image.vhdfixed.xz
    .\caasp-hyperv.ps1 fetchimage -caaspImageSourceUrl http://url/image.vhd
    .\caasp-hyperv.ps1 fetchimage -caaspImageSourceUrl http://url/image.vhdx
  
  Deploy a new cluster
    .\caasp-hyperv.ps1 deploy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masters 3 -workers 15
  
  Redeploy the cluster without confirmation
    .\caasp-hyperv.ps1 deploy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masters 3 -workers 15 -Force

  Destroy the cluster with confirmation
    .\caasp-hyperv.ps1 destroy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masters 3 -workers 15
  
  Destroy the cluster without confirmation
    .\caasp-hyperv.ps1 destroy -stackName suse -masters 3 -workers 15 -Force

  Get all deployment status for suse stack
    .\caasp-hyperv.ps1 status -stackName suse

  Get all deployment status
    .\caasp-hyperv.ps1 status
#>
```
