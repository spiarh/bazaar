#Requires -Version 5
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
  
.PARAMETER lbNodePrefix
  Description: Base name of the lb node
  Actions: plan,deploy,destroy
  Expect: string

.PARAMETER lbRam
  Description: Memory of the lb node, MUST be configured in mega-bytes
  Actions: plan,deploy
  Expect: string
  
.PARAMETER lbCpu
  Description: Virtual CPUs of the lb node
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
    .\caasp-hyperv.ps1 deploy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masterCount 3 -workerCount 15
  
  Redeploy the cluster without confirmation
    .\caasp-hyperv.ps1 deploy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masterCount 3 -workerCount 15 -Force
    
  Destroy the cluster with confirmation
    .\caasp-hyperv.ps1 destroy -stackName suse -caaspImage SUSE-CaaS-Platform.vhd -masterCount 3 -workerCount 15
  
  Destroy the cluster without confirmation
    .\caasp-hyperv.ps1 destroy -stackName suse -masterCount 3 -workerCount 15 -Force

  Get all deployment status for suse stack
    .\caasp-hyperv.ps1 status -stackName suse
            
  Get all deployment status
    .\caasp-hyperv.ps1 status
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

param (
  [parameter(
    Mandatory = $true,
    Position = 0
  )
  ][string][ValidateSet("listimages", "deleteimage", "fetchimage", "plan", "deploy", "status", "destroy")]$action,
  
  [parameter(Mandatory = $false)][string]$computeHosts,
  [parameter(Mandatory = $false)][string]$caaspImage,
  [parameter(Mandatory = $false)][string]$caaspImageSourceUrl,
  [parameter(Mandatory = $false)][string]$imageStoragePath,
  [parameter(Mandatory = $false)][string]$vhdStoragePath,
  [parameter(Mandatory = $false)][int]$estimatedVmSize,
  [parameter(Mandatory = $false)][string]$stackName,
  [parameter(Mandatory = $false)][string]$networkConfigCloudInit,

  [parameter(Mandatory = $false)][int]$lbCount,
  [parameter(Mandatory = $false)][string]$lbNodePrefix,
  [parameter(Mandatory = $false)][string]$lbRam,
  [parameter(Mandatory = $false)][int]$lbCpu,
  [parameter(Mandatory = $false)][string]$lbCloudInit,
  
  [parameter(Mandatory = $false)][int]$masterCount,
  [parameter(Mandatory = $false)][string]$masterNodePrefix,
  [parameter(Mandatory = $false)][string]$masterRam,
  [parameter(Mandatory = $false)][int]$masterCpu,
  [parameter(Mandatory = $false)][string]$masterCloudInit,

  [parameter(Mandatory = $false)][int]$workerCount,
  [parameter(Mandatory = $false)][string]$workerNodePrefix,
  [parameter(Mandatory = $false)][string]$workerRam,
  [parameter(Mandatory = $false)][int]$workerCpu,
  [parameter(Mandatory = $false)][string]$workerCloudInit,

  [parameter(Mandatory = $false)][int]$vmVlanId,
  [parameter(Mandatory = $false)][string]$vmSwitch,

  [parameter(Mandatory = $false)][string]$varFile = "$PSScriptRoot\caasp-hyperv.vars",

  [switch]$Force
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Break on non-terminating errors
$ErrorActionPreference = "Stop"
# Hide ProgressBar
$ProgressPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$date = Get-Date -UFormat "%Y%m%d%H%M%S"
$networkConfigCloudInit = "$PSScriptRoot\cloud-init-network-config.yaml"
$lbCloudInit = "$PSScriptRoot\cloud-init-lb.yaml"
$masterCloudInit = "$PSScriptRoot\cloud-init-masters.yaml"
$workerCloudInit = "$PSScriptRoot\cloud-init-workers.yaml"
$oscdimgPath = "$PSScriptRoot\oscdimg.exe"
$IPv4RegexNew = "((?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d))"

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function parse_varfile() {
  Param([parameter(Mandatory = $true)]$file)

  $configuration = @{}
  $conf_file = (Get-Content $file) | Where-Object { $_ -match '\S' -and $_ -notmatch '^#' }
  $conf_file | ForEach-Object -process { $k = [regex]::split($_, '\s*=\s*'); $configuration.Add($k[0], $k[1]) }

  return $configuration
}

function log_task() {
  Param([parameter(Mandatory = $true)]$Message)
  Write-Host "TASK: $Message" -ForegroundColor Cyan
}

function log_info() {
  Param([parameter(Mandatory = $true)]$Message)
  Write-Host "INFO: $Message" -ForegroundColor Green
}

function log_destroy() {
  Param([parameter(Mandatory = $true)]$Message)
  Write-Host "INFO: $Message" -ForegroundColor Magenta
}

function log_warning() {
  Param([parameter(Mandatory = $true)]$Message)
  Write-Host "WARN: $Message" -ForegroundColor Yellow
}

function log_error() {
  Param([parameter(Mandatory = $true)]$Message)
  Write-Host "ERROR: $Message" -ForegroundColor Red
}

function convert_to_unc() {
  Param(
    [parameter(Mandatory = $true)]$ComputerName,
    [parameter(Mandatory = $true)]$LocalPath
  )
  
  $SharedPath = $($LocalPath).Replace(':', '$')
  $UNCPath = "\\$ComputerName\$SharedPath"
  
  return $UNCPath
}

function download_file() {
  Param(
    [parameter(Mandatory = $true)][string]$file_url,
    [parameter(Mandatory = $true)][string]$file_dest_path
  )
  
  Try {
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile("$file_url", "$file_dest_path")
    log_info -Message "Duration: $((Get-Date).Subtract($start_time).Seconds) second(s)"
  }
  Catch {
    log_error -Message "Download failed"
    $_.Exception.Message
    If (Test-Path $file_dest_path) { Remove-Item -Path $file_dest_path -Force }
    Exit          
  }  
}

Function is_file_locked {
  Param(
    [parameter(Mandatory = $true)][string]$file_path
  )

  try {
    Rename-Item $file_path $file_path
    return $false
  }
  catch {
    return $true
  }
}

Function delete_file() {
  Param(
    [parameter(Mandatory = $true)][string]$file_path
  )

  try {
    log_info "Deleting $file_path"
    Remove-item $file_path -Force
  }
  catch {
    log_error "Delete $file_path failed"
    $_.Exception.Message
  }
}

Function list_images() {
  Param(
    [parameter(Mandatory = $true)][string]$image_dir
  )
  
  Foreach ($ComputeHost in $COMPUTE_HOSTS) {
    $lsfiles = Get-ChildItem -File -Recurse -Include *.vhd,*.vhdx $(convert_to_unc $ComputeHost $image_dir)
    log_info "Available images:"
    ForEach ($f in $lsfiles) {
      log_info "- $($f.name) ($($f.length)b)"
    }
  }
}

Function delete_image() {
  Param(
    [parameter(Mandatory = $true)][string]$image_dir,
    [parameter(Mandatory = $true)][string]$image
  )
  $image_path = "$image_dir\$image"

  Foreach ($ComputeHost in $COMPUTE_HOSTS) {
    $unc_image_path = $(convert_to_unc $ComputeHost $image_path)
    $unc_image_base_path = $unc_image_path -replace '(.vhdx)|(.vhd)',''

    # Test if .vhd file exists and if it is locked
    If (Test-Path "$unc_image_path") {
      If ($(is_file_locked "$unc_image_path") -eq $false) {
        log_task "Delete $image on $($ComputeHost)"
        delete_file "$unc_image_path"
        # Clean up
        If (Test-Path "$unc_image_base_path.vhdfixed.xz") { delete_file "$unc_image_base_path.vhdfixed.xz" }
        If (Test-Path "$unc_image_base_path.vhdfixed.xz.sha256") { delete_file "$unc_image_base_path.vhdfixed.xz.sha256" }
        log_info "Image deleted"
      }
      Else {
        log_error "$image is locked on $($ComputeHost)"
      }
    }
  }
}

function fetch_image() {
  Param(
    [parameter(Mandatory = $true)][string]$file_url,
    [parameter(Mandatory = $true)][string]$dest_dir
  )

  Foreach ($ComputeHost in $COMPUTE_HOSTS) {
    log_task "Fetch $file_url on $($ComputeHost)"
    
    $dir = $(convert_to_unc $ComputeHost $dest_dir)
    # Create Image path if it does not exist
    If (-not $(Test-Path $dir)) { 
      log_info "Creating $dir"
      New-Item -ItemType Directory $dir -Force | Out-Null 
    }

    $url_split = $file_url.split('/')
    $filename = $url_split[-1]
    if ($filename -match '.*fixed.xz$') {
      $target_filename = $filename -replace 'fixed.xz',''
    }
    Else {
      $target_filename = $filename
    }

    # Download Image if it does not exist
    $output_file_path = "$dir\$target_filename"
    If (Test-Path $output_file_path) {
      log_info -Message "Existing $target_filename IMAGE found"
    }

    If (-not $(Test-Path $output_file_path)) {
      log_info -Message "Downloading $filename"
      # use $filename to download file to vhdfixed.xz if necessary
      download_file $file_url  "$dir\$filename"
    }
    
    $extracted_filename = $filename.replace('.xz', '')
    # Extract the file if necessary
    if ($filename -match '.*fixed.xz$') {
      try {
        If (-not $(Test-Path $output_file_path)) {
          log_info -Message "Extracting $dir\$filename"
          Invoke-Command -ComputerName $ComputeHost -ScriptBlock {param($d, $f, $df) & 'C:\Program Files\7-Zip\7Z.exe' e $d\$f -o"$df" -y } -ArgumentList $dest_dir, $filename, $dest_dir
          Rename-Item $dir\$extracted_filename "$dir\$target_filename"
        }
      }
      Catch {
        log_error -Message "Extract file failed"
        $_.Exception.Message
      }
      Finally {
        # Clean up
        If (Test-Path "$dir\$filename") { delete_file "$dir\$filename" }
        If (Test-Path "$dir\$filename.sha256") { delete_file "$dir\$filename.sha256" }
      }
    }
  }
}

function create_vmharddisk() {
  Param(
    [parameter(Mandatory = $true)]$ImagePath,
    [parameter(Mandatory = $true)]$DiskPath
  )
  log_info -Message "Creating VMHardDisk : $DiskPath from $ImagePath"
  New-VHD -ComputerName $ComputeHost -ParentPath $ImagePath -Path $DiskPath -Differencing | Out-Null
}

function add_vmharddisk() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $true)]$DiskPath
  )
  log_info -Message "Adding VMHardDisk : $DiskPath to $VMName"
  Add-VMHardDiskDrive -ComputerName $ComputeHost  -VMName $VMName -Path $DiskPath
}

function add_vmdvddrive() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $true)]$IsoTargetPath
  )
  log_info -Message "Adding VMDvdDrive : $IsoTargetPath to $VMName"
  Add-VMDvdDrive -ComputerName $ComputeHost  -VMName $VMName -ControllerNumber 1 -Path $IsoTargetPath
}

function create_vm() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $false)]$VMVlanId,
    [parameter(Mandatory = $true)]$VMMemory,
    [parameter(Mandatory = $true)]$VMProcessor,
    [parameter(Mandatory = $true)]$VMSwitch
  )
  # Convert String to int64
  $VMMemory = [int64][scriptblock]::Create($VMMemory).Invoke()[0]
  
  log_info -Message "Creating VM: $VMName with $VMMemory mb, $VMProcessor vcpu, $VMSwitch switch"
  New-VM -ComputerName $ComputeHost -Name $VMName -MemoryStartupBytes $VMMemory -Generation 1 -BootDevice VHD -SwitchName $VMSwitch | Out-Null
  Set-VM -ComputerName $ComputeHost -Name $VMName -ProcessorCount $VMProcessor | Out-Null
  
  If ($VMVlanId -In 1..4096) {
    Set-VMNetworkAdapterVlan -ComputerName $ComputeHost -VMName $VMName -Trunk -NativeVlanId $VMVlanId -AllowedVlanIdList $VMVlanId
  }
  Set-VMNetworkAdapter -ComputerName $ComputeHost -VMName $VMName -VmqWeight 0
}

function remove_vm() {
  Param([parameter(Mandatory = $true)]$VMName)
  log_destroy -Message "Removing VM: $VMName"
  Remove-VM -ComputerName $ComputeHost -VMName $VMName -WarningAction ignore -Confirm:$false -Force
}

function start_vm() {
  Param([parameter(Mandatory = $true)]$VMName)
  log_info "Starting VM: $VMName"
  Start-VM -ComputerName $ComputeHost -VMName $VMName -Confirm:$false
}

function get_vm_ip() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $true)]$ComputeHost
  )  

  $timeout = 0
  Do {
    if ($timeout -eq 12) { log_error -Message "No IP Address found after 120s for $VMName, exiting"; Exit }
    Write-Host "- Waiting for $VMName IP"
    $NodeIp = (Get-VM -VMName $VMName -ComputerName $ComputeHost -ErrorAction ignore | Select-Object -ExpandProperty NetworkAdapters | Select-Object IPaddresses).IPaddresses -match $IPv4RegexNew
    if (-not $NodeIp) { $timeout++; Start-Sleep 10 }
  } while (-not ($NodeIp -match $IPv4RegexNew))

  return $NodeIp
}

function generate_state_file() {
  $output = [ordered]@{date = "$date"; config = @{}; vmguests = @()}

  # Add global configuration
  $output.config = $CONF

  # Get configuration for each node
  foreach ($k in $ALLOCATION.keys) {
    $VMName = $k
    $ComputeHost = $ALLOCATION.item($k)
    
    log_task -Message "Gather information of $VMName on $ComputeHost"
    if ("$VMName" -match "$($CONF.lbNode)") { $Role = "lb" }
    Elseif ("$VMName" -match "$($CONF.masterNode)") { $Role = "master" }
    Else { $Role = "worker" }  

    # Get VM info
    $Vm = Get-VM -VMName $VMName -ComputerName $ComputeHost
    # Get IPv4 Address
    $NodeIp = get_vm_ip -VMName $VMName -ComputeHost $ComputeHost
    # Get FQDN
    $VMFqdn = Resolve-DnsName -Type PTR -DnsOnly $NodeIp | Where-Object { $_.Section -eq "Answer" }
    # Convert RAM in mb for visualization
    $VMRam = $Vm.MemoryAssigned / 1024 / 1024
    #Get VM Hard Disk
    $VMHdd = Get-VMHardDiskDrive -ComputerName $ComputeHost -VMName $VMName
    # Get Index of the VM in the deployment
    $index = $($ALLOCATION.keys).indexOf($k)

    $vm_attr = [ordered]@{index = "$index"; `
        name = "$VMName"; `
        id = "$($VM.id)"; `
        role = "$Role"; `
        publicipv4 = "$NodeIp"; `
        fqdn = "$($VMFqdn.NameHost)"; `
        hypervhost = "$ComputeHost"; `
        image = "$($CONF.caaspImage)"; `
        harddrive = "$($VMHdd.path)";
      ram = "$($VMRam)mb";
      cpu = "$($VM.ProcessorCount)";
    }

    $output["vmguests"] += $vm_attr
  }

  Write-Host "====BEGINING_HVSTATE====`n$($output | ConvertTo-Json)`n====END_HVSTATE===="
  ($output | ConvertTo-Json) | Out-File -filepath "$PSScriptRoot\caasp-hyperv.hvstate" -Encoding ASCII -Force
  ($output | ConvertTo-Json) | Out-File -filepath $CONF.hvStateFile -Encoding ASCII -Force
}

function stop_vm() {
  Param([parameter(Mandatory = $true)]$VMName)

  log_destroy "Stopping VM : $VMName"
  Stop-VM -ComputerName $ComputeHost -VMName $VMName -TurnOff -WarningAction ignore -Confirm:$false -Force
}  

function create_cloudinit_iso() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $true)]$IsoTargetPath,
    [parameter(Mandatory = $true)]$NetworkConfigCloudInit,
    [parameter(Mandatory = $true)]$CloudInit,
    [parameter(Mandatory = $false)]$Masters
  )
  
  log_info -Message "- Creating Clout-Init ISO for $VMName"
  # Create Temp directory for meta-data and user-data files
  $TmpPath = "$IsoTargetPath\$VMName-tmp"
  New-Item -ItemType directory -Path $TmpPath -Force  | Out-Null

  $Hostname = $VMName.replace("_", "-")

  # Create haproxy server backend configuration
  if ($Masters) {
    $mastersBackend = @()
    foreach ($m in $Masters.GetEnumerator()) {
      $confLine = "      server $($m.Name) $($m.Value):6443 check check-ssl verify none"
      $mastersBackend += $confLine
    }
  }

  # Generate meta-data and user-data files of cloud-init ISO
  $metadata = "instance-id: $Hostname"
  $userdata = (Get-Content -Path "$CloudInit" -Encoding ASCII) | ForEach-Object {$_ -Replace "SET_MASTERS_BACKENDS", "$($mastersBackend | Out-String)" }
  $networkConfig = (Get-Content -Path "$NetworkConfigCloudInit" -Encoding ASCII)

  
  Set-Content -Path "$TmpPath\meta-data" -Value $metadata -Encoding ASCII
  Set-Content -Path "$TmpPath\user-data" -Value $userdata -Encoding ASCII
  Set-Content -Path "$TmpPath\network-config" -Value $networkConfig -Encoding ASCII

  # Create ISO
  & $oscdimgPath -j2 -lcidata "$TmpPath" "$IsoTargetPath\$VMName-cloud-init.iso" | Out-Null
}

function deploy_vm() {
  Param(
    [parameter(Mandatory = $false)]$Masters,
    [parameter(Mandatory = $true)]$NetworkConfigCloudInit,
    [parameter(Mandatory = $true)]$CloudInit,
    [parameter(Mandatory = $true)]$DeployVmDirLocal,
    [parameter(Mandatory = $true)]$VMPrefix,
    [parameter(Mandatory = $true)]$VMCount,
    [parameter(Mandatory = $true)]$VMMemory,
    [parameter(Mandatory = $true)]$VMProcessor,
    [parameter(Mandatory = $true)]$VMSwitch,
    [parameter(Mandatory = $true)]$VMVlanId,
    [parameter(Mandatory = $true)]$ImagePath,
    [parameter(Mandatory = $true)]$ImageFormat,
    [parameter(Mandatory = $true)]$Role
  )

  Try {
    For ($i = 0; $i -lt $VMCount; $i++) {
      $VMName = "$VMPrefix" + $i.ToString('000')

      # Get an available Compute Node
      $ComputeHost = $ALLOCATION.$VMName

      # Exit if a VM or VHD exit with the same name 
      if ((Get-VM -ComputerName $ComputeHost -VMName $VMName -ErrorAction ignore) -Or (Get-VHD -ComputerName $ComputeHost -Path "$DeployVmDirLocal\$VMName.$ImageFormat" -ErrorAction ignore)) { 
        log_error "A Virtual Machine ($VMName) or a Virtual Hard Disk ($DeployVmDirLocal\$VMName.$ImageFormat) on $ComputerHost already exist with the same name, use -Force to overwrite existing deployment"
        Exit
      }

      log_task "Deploy $VMName on $ComputeHost"
      create_vm -VMName $VMName -VMMemory $VMMemory -VMProcessor $VMProcessor -VMSwitch $VMSwitch -VMVlanId $VMVlanId
      create_vmharddisk -ImagePath $ImagePath -DiskPath "$DeployVmDirLocal\$VMName.$ImageFormat"
      add_vmharddisk -VMName $VMName -DiskPath "$DeployVmDirLocal\$VMName.$ImageFormat"
      create_cloudinit_iso -VMName $VMName `
          -IsoTargetPath $(convert_to_unc $ComputeHost $DeployVmDirLocal) `
          -CloudInit "$CloudInit" `
          -NetworkConfigCloudInit "$NetworkConfigCloudInit" `
          -Masters $Masters
      add_vmdvddrive -VMName $VMName -IsoTargetPath "$DeployVmDirLocal\$VMName-cloud-init.iso"
      start_vm -VMName $VMName
    }
  }
  Catch {
    log_error -Message "Deploy failed"
    $_.Exception.Message
    Exit
  }
}

function destroy_vm() {
  Param(
    [parameter(Mandatory = $true)]$VMPrefix,
    [parameter(Mandatory = $true)]$VMCount,
    [parameter(Mandatory = $true)]$Role,
    [switch]$force
  )

  Try {
    For ($i = 0; $i -lt $VMCount; $i++) {
      $VMName = "$VMPrefix" + $i.ToString('000')
      $ComputeHost = $ALLOCATION.$VMName

      If (-not $Force -and $ALLOCATION.$VMName) {
        # Run only if a VM exists
        if (Get-VM -ComputerName $ComputeHost -VMName $VMName -ErrorAction ignore) { 
          log_task "Destroy $VMName on $ComputeHost"
          stop_vm -VMName "$VMName"
          remove_vm -VMName "$VMName"
        }
      }
      elseif ($force) {
        foreach ($ComputeHost in $COMPUTE_HOSTS) {
          # Run only if a VM exists
          if (Get-VM -ComputerName $ComputeHost -VMName $VMName -ErrorAction ignore) { 
            log_task "Destroy $VMName on $ComputeHost (-Force option activated)"
            stop_vm -VMName "$VMName"
            remove_vm -VMName "$VMName"
          }
        }  
      }
    }
  }
  Catch {
    log_error -Message "Destroy failed"
    $_.Exception.Message
    Exit
  }
}

function get_host_resources() {
  Param([parameter(Mandatory = $true)]$COMPUTE_HOSTS)

  # Create the resource table
  $ComputeResTable = New-Object System.Data.DataTable
  $ComputeResTable.Columns.add((New-Object System.Data.DataColumn ComputeHostName, ([string])))
  $ComputeResTable.Columns.add((New-Object System.Data.DataColumn MemoryAvailable, ([string])))
  $ComputeResTable.Columns.add((New-Object System.Data.DataColumn VhdDriveFreeDiskSpace, ([string])))

  # Get the memory available for each host
  foreach ($ComputeHost in $COMPUTE_HOSTS) {
    # Memory
    $MemoryAvailable = 0
    $NodeMemoryAvailable = Get-VMHostNumaNode -ComputerName $ComputeHost | Select MemoryAvailable
    foreach ($MemoryAvailablePerCpu in $NodeMemoryAvailable.MemoryAvailable) {
      $MemoryAvailable += $MemoryAvailablePerCpu
    }

    # Insert the values in the table
    $row = $ComputeResTable.NewRow()
    $row.ComputeHostName = $ComputeHost

    # Keep 2048mb for the hypervisor
    $row.MemoryAvailable = $MemoryAvailable - 2048
    $ComputeResTable.rows.add( $row )

    # Get the diskspace in VHD dir partition
    $device_id = $($CONF.vhdStoragePath).Substring(0, 2)
    $drive = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputeHost | Where { $_.DeviceID -eq $device_id }
    
    # Keep 5gb for the hypervisor
    $row.VhdDriveFreeDiskSpace = [int]$($drive.Freespace / 1024 / 1024 / 1024) - 5
  }

  return $ComputeResTable
}

function get_max_mem_available() {
  Param([parameter(Mandatory = $true)]$ComputeResTable)

  # Get the node with the most memory available
  $MaxMemAvailable = $ComputeResTable | Measure-Object -Property MemoryAvailable -Maximum
  $MaxMemFreeCompute = $ComputeResTable | Where-Object { $_.MemoryAvailable -eq $MaxMemAvailable.Maximum  }

  return $MaxMemFreeCompute
}

function select_compute() {
  Param(
    [parameter(Mandatory = $true)]$VMName,
    [parameter(Mandatory = $true)]$VMMemory
  )

  # Select a node in the pool
  $MaxMemFreeCompute = get_max_mem_available $COMPUTE_RESOURCES

  # Remove the unit information
  If ($VMMemory -match 'mb') {
    $VMMemory = $VMMemory.replace('mb', '')
  }

  If ($CONF.estimatedVmSize -match 'gb') {
    $CONF.estimatedVmSize = $($CONF.estimatedVmSize).replace('gb', '')
  }

  # Check memory
  If ( $($MaxMemFreeCompute.MemoryAvailable - $VMMemory) -gt 0 ) {
    # Update Compute Table by updating the choosen Compute
    $MaxMemFreeCompute.MemoryAvailable -= $VMMemory
  }
  Else {
    log_error "not enough memory on $($MaxMemFreeCompute.ComputeHostName) for $VMName"
    log_error "required : $($VMMemory)mb, available: $($MaxMemFreeCompute.MemoryAvailable)mb"
    $script:MEM_CHECK_FAILED = $true
  }

  # Check disk space
  If ( $($MaxMemFreeCompute.VhdDriveFreeDiskSpace - $CONF.estimatedVmSize) -gt 0 ) {
    # Update Compute Table by updating the choosen Compute
    $MaxMemFreeCompute.VhdDriveFreeDiskSpace -= $CONF.estimatedVmSize
  }
  Else {
    log_error "not enough free disk space $($MaxMemFreeCompute.ComputeHostName) for $VMName"
    log_error "required : $($CONF.estimatedVmSize)gb, available: $($MaxMemFreeCompute.VhdDriveFreeDiskSpace)gb"
    $script:DISK_CHECK_FAILED = $true
  }

  # Fill in the allocation hash
  Try {
    If ($MEM_CHECK_FAILED -or $DISK_CHECK_FAILED) {
      throw "No Hyper-V host available"
    }
    $ALLOCATION.Add($VMName, $MaxMemFreeCompute.ComputeHostName)
  }
  catch {
    log_error -Message  $_.Exception.Message

    # Only exist if the action is deploy
    # so the other tests can run when action is plan
    if ($action -eq "deploy") {
      Exit
    }
  }
}

function read_allocation_hvstate() {
  Param([switch]$Force)

  If (-not $Force) {
    Try {
      $guests = (Get-Content -Path $CONF.hvStateFile -Encoding ASCII | ConvertFrom-Json).vmguests
      Foreach ($g in $guests) {
        $ALLOCATION.Add($g.name, $g.hypervhost)
      }

      # Override the values in $CONF with the values from the State File
      $state_conf = (Get-Content -Path $CONF.hvStateFile -Encoding ASCII | ConvertFrom-Json).config
      $CONF.masterCount = $state_conf.masterCount
      $CONF.workerCount = $state_conf.workerCount
    }
    Catch {
      log_error -Message "Reading state file $($CONF.hvStateFile) failed"
      $_.Exception.Message
      If (($action -eq "destroy") -or ($action -eq "deploy")) {
        log_error -Message "If a previous deployment has failed, try using '-Force' parameter"
      }
      Exit
    }
  }
}

function plan_deploy() {
  log_task "Generate the execution plan"
  
  try {
    # Test and select a compute host
    For ($i = 0; $i -lt $CONF.lbCount; $i++) {
      $VMName = $CONF.lbNode + $i.ToString('000')
      select_compute -VMName $VMName -VMMemory $CONF.lbRam
    }
    For ($i = 0; $i -lt $CONF.masterCount; $i++) { 
      $VMName = $CONF.masterNode + $i.ToString('000')
      select_compute $VMName $CONF.masterRam
    }
    For ($i = 0; $i -lt $CONF.workerCount; $i++) { 
      $VMName = $CONF.workerNode + $i.ToString('000')
      select_compute $VMName $CONF.workerRam
    }

    # select_compute return $MEM_CHECK_FAILED or $DISK_CHECK_FAILE
    If (-not $MEM_CHECK_FAILED) {
      log_info "Hyper-V hosts have sufficient memory"
    }
    If (-not $DISK_CHECK_FAILED) {
      log_info "Hyper-V hosts have sufficient free disk space"
    }

    Foreach ($ComputeHost in $COMPUTE_HOSTS) {
      log_task "Check Hyper-V hosts: $ComputeHost"
  
      # Check Virtual Machine switch presence
      If (Get-VMSwitch -Name $CONF.vmSwitch -ComputerName $ComputeHost -ErrorAction ignore) {
        log_info "VM Switch: $($CONF.vmSwitch) exists"
      }
      Else {
        log_error "VM Switch: $($CONF.vmSwitch) does not exist" 
      }
  
      # Check Image dir and Image file presence
      If (Test-Path $(convert_to_unc $ComputeHost $CONF.imageStoragePath)) {
        log_info "Image dir: $($CONF.imageStoragePath) exists"
        If (Test-Path $(convert_to_unc $ComputeHost $CONF.imagePath)) {
          log_info "Image file: $($CONF.imagePath) exists"
        }
        Else {
          log_error "Image file: $($CONF.imagePath) does not exist"
        }
      }
      Else {
        log_error "Image dir: $($CONF.imageStoragePath) does not exist"
        log_error "Image file: $($CONF.imagePath) does not exist"
      }
  
      # Check VHD dir

      # Remove stackName from storage path, full deployment
      # directory with the stackName will be created during deployment
      $vhdDir = $($CONF.vhdStoragePath).Substring(0, $($CONF.vhdStoragePath).Length - $($CONF.stackName).Length)
      
      If (Test-Path $(convert_to_unc $ComputeHost $vhdDir)) {
        log_info "VHD dir: $vhdDir exists"
      }
      Else {
        log_error "VHD dir: $vhdDir does not exist"
      }
    }
  }
  Catch {
    log_error "Planification failed"
    $_.Exception.Message
  }
  
  log_task "Show configuration:"
  $CONF | Format-Table
  
  log_task "Show virtual machines allocation:"
  $ALLOCATION | Format-Table
  
  log_task "Show estimated compute resources status after deployment:"
  $COMPUTE_RESOURCES | Format-Table
}

function deploy_caasp() {
  # Test deployment configuration and create vm allocation table
  plan_deploy

  # Create deployment directory
  Foreach ($ComputeHost in $COMPUTE_HOSTS) {
    if (-not (Test-Path $(convert_to_unc $ComputeHost $CONF.vhdStoragePath))) {
      log_info "Creating deployment directory : $(convert_to_unc $ComputeHost $CONF.vhdStoragePath)"
      New-Item -Type Directory $(convert_to_unc $ComputeHost $CONF.vhdStoragePath) | Out-Null
    }
  }
  
  # Create Master nodes
  deploy_vm -DeployVmDirLocal $CONF.vhdStoragePath `
    -VMPrefix $CONF.masterNode `
    -VMCount $CONF.masterCount `
    -VMMemory $CONF.masterRam `
    -VMVlanId $CONF.vmVlanId `
    -VMProcessor $CONF.masterCpu `
    -VMSwitch $CONF.vmSwitch `
    -ImagePath $CONF.imagePath `
    -ImageFormat $CONF.imageFormat `
    -Role "master" `
    -NetworkConfigCloudInit $CONF.networkConfigCloudInit `
    -CloudInit $CONF.masterCloudInit

  # Create Worker nodes
  deploy_vm -DeployVmDirLocal $CONF.vhdStoragePath `
    -VMPrefix $CONF.workerNode `
    -VMCount $CONF.workerCount `
    -VMMemory $CONF.workerRam `
    -VMVlanId $CONF.vmVlanId `
    -VMProcessor $CONF.workerCpu `
    -VMSwitch $CONF.vmSwitch `
    -ImagePath $CONF.imagePath `
    -ImageFormat $CONF.imageFormat `
    -Role "worker" `
    -NetworkConfigCloudInit $CONF.networkConfigCloudInit `
    -CloudInit $CONF.workerCloudInit

  ## Get Masters IPs
  log_task "Get Masters IPs"
  $Masters = @{}
  For ($i = 0; $i -lt $CONF.masterCount; $i++) { 
    $VMName = $CONF.masterNode + $i.ToString('000')
    $ComputeHost = $ALLOCATION.$VMName

    $MasterIp = (get_vm_ip -VMName $VMName -ComputeHost $ComputeHost)
    $MasterFqdn = Resolve-DnsName -Type PTR -DnsOnly $MasterIp | Where-Object { $_.Section -eq "Answer" }
    $Masters[$MasterFqdn.NameHost] = $MasterIp

    log_info "- Master Node $($MasterFqdn.NameHost) has the IPs $MasterIp"
  }

  # Create lb node
  deploy_vm -DeployVmDirLocal $CONF.vhdStoragePath `
    -VMPrefix $CONF.lbNode `
    -VMCount $CONF.lbCount `
    -VMMemory $CONF.lbRam `
    -VMVlanId $CONF.vmVlanId `
    -VMProcessor $CONF.lbCpu `
    -VMSwitch $CONF.vmSwitch `
    -ImagePath $CONF.imagePath `
    -ImageFormat $CONF.imageFormat `
    -Role "lb" `
    -NetworkConfigCloudInit $CONF.networkConfigCloudInit `
    -CloudInit $CONF.lbCloudInit `
    -Masters $Masters    
}


function destroy_caasp() {
  Param([switch]$Force)
  # Read allocation of virtual machines, masters and workers number from hvstate file
  read_allocation_hvstate -Force:$force

  # Destroy lb node
  destroy_vm -VMPrefix $CONF.lbNode `
    -VMCount 1 `
    -Role "lb" -Force:$force

  # Destroy Master nodes
  destroy_vm -VMPrefix $CONF.masterNode `
    -VMCount $CONF.masterCount `
    -Role "master" -Force:$force

  # Destroy Worker nodes
  destroy_vm -VMPrefix $CONF.workerNode `
    -VMCount $CONF.workerCount `
    -Role "worker" -Force:$force

  # Remove deployment directory
  Try {
    Foreach ($ComputeHost in $COMPUTE_HOSTS) {
      if ((Test-Path $(convert_to_unc $ComputeHost $CONF.vhdStoragePath))) {
        log_task "Destroy deployment directory : $(convert_to_unc $ComputeHost $CONF.vhdStoragePath)"
        Remove-Item -Path $(convert_to_unc $ComputeHost $CONF.vhdStoragePath) -Recurse -Confirm:$false -Force | Out-Null
      }
    }
  }
  Catch {
    log_error -Message "Destroy failed"
    $_.Exception.Message
    log_error -Message "If a previous deployment has failed, try using '-Force' parameter"
    Exit
  }
}

function status_caasp() {
  $status = @()

  # Get only the deployment status for a provided stack
  if ($CONF.stackName) {
    log_task "Show deployment status for stack: $($CONF.stackName)"
    read_allocation_hvstate

    foreach ($k in $ALLOCATION.keys) {
      $VMName = $k
      $ComputeHost = $ALLOCATION.item($k)
      $vmguest = Get-VM $VMName -ComputerName $ComputeHost
      $status += $vmguest
    }
  }

  # Get all the deployments
  Else {
    log_task "Show global status per Hyper-V host"
    Foreach ($ComputeHost in $COMPUTE_HOSTS) {
      $vmguests += Get-VM * -ComputerName $ComputeHost
    }

    $status += $vmguests
  }

  # Show output
  $status | Format-Table Name, State, ComputerName, `
  @{Label = "IpAddress"; Expression = {$_.NetworkAdapters.IpAddresses -match $IPv4RegexNew}}, `
  @{Label = 'CPUUsage(%)'; Expression = {$_.CPUUsage}}, `
  @{Label = "Memory(mb) d/a"; Expression = {"$($_.MemoryDemand / 1024 / 1024)/$($_.MemoryAssigned / 1024 / 1024)"}}, `
  @{Label = "Uptime"; Expression = {"$($_.Uptime.days)d, $($_.Uptime.hours)h$($_.Uptime.minutes)m$($_.Uptime.seconds)s"}} , `
    Status
}

function test_vars_not_null() {
  Param([parameter(Mandatory = $true)][array]$vars)
  Foreach ($var in $vars) {
    If (-not $CONF.$var) {
      log_error "$var parameter not set"
      $min_one_var_not_set = $true
    }
  }

  If ($min_one_var_not_set) {
    log_error "One or more parameters are not set, exiting..."
    Exit
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Parse configuration
$CONF = parse_varfile $varFile

# Command line arguments have priority over file arguments
Foreach ($param in $MyInvocation.BoundParameters.keys) {
  $option = (get-variable $param).Value
  if ($param) { $CONF.$param = $option }
}

# Create global hash for the virtual machine allocation
$ALLOCATION = [ordered]@{}

# Create global var with the compute hosts
$COMPUTE_HOSTS = @()
foreach ($computeHost in $($CONF.computeHosts.split(','))) {
  $COMPUTE_HOSTS += $computeHost
}

# Create global var with the available resources
$COMPUTE_RESOURCES = get_host_resources $COMPUTE_HOSTS

# Add values to global config
$CONF.networkConfigCloudInit = $networkConfigCloudInit
$CONF.lbCloudInit = $lbCloudInit
$CONF.masterCloudInit = $masterCloudInit
$CONF.workerCloudInit = $workerCloudInit

# Get total number of nodes
$CONF["nodeTotal"] = 1 + $CONF.masterCount + $CONF.workerCount

# Generate node names
$CONF["lbNode"] = $CONF.lbNodePrefix + "-$($CONF.stackName)"
$CONF["masterNode"] = $CONF.masterNodePrefix + "-$($CONF.stackName)"
$CONF["workerNode"] = $CONF.workerNodePrefix + "-$($CONF.stackName)"

# Generate VHD Image path
$CONF["imagePath"] = "$($CONF.imageStoragePath)\$($CONF.caaspImage)"

# Get VHD Image format
$CONF["imageFormat"] = ($CONF.caaspImage).split('.')[-1]

# Generate deployment dir path
$CONF["vhdStoragePath"] = "$($CONF.vhdStoragePath)\$($CONF.stackName)"

# Generate state file path
$CONF["hvStateFile"] = "$PSScriptRoot\caasp-hyperv-$($CONF.stackName).hvstate"

# Set default values if not set
If (-not $CONF.caaspImageFormat) { $CONF.caaspImageFormat = "vhdx" }
If (-not $CONF.estimatedVmSize) { $CONF.estimatedVmSize = 15 }
If (-not $CONF.lbs) { $CONF.lbCount = 1 }
If (-not $CONF.lbRam) { $CONF.lbRam = "1024mb" }
If (-not $CONF.lbCpu) { $CONF.lbCpu = 1 }
If (-not $CONF.masterCount) { $CONF.masterCount = 1 }
If (-not $CONF.masterRam) { $CONF.masterRam = "4096mb" }
If (-not $CONF.masterCpu) { $CONF.masterCpu = 2 }
If (-not $CONF.workerCount) { $CONF.workerCount = 2 }
If (-not $CONF.workerRam) { $CONF.workerRam = "2048mb" }
If (-not $CONF.workerCpu) { $CONF.workerCpu = 1 }

# Add the mb unit information if not here
foreach ($mem in @("lbRam", "masterRam", "workerRam")) {
  If ($CONF.$mem.Substring($CONF.$mem.Length - 2) -ne "mb") {
    $CONF.$mem = $CONF.$mem + "mb"
  }
}

# Quich check for the mandatory variables
test_vars_not_null @("ComputeHosts")

Start-Transcript -Path "$PSScriptRoot\$action-$date.log"
switch ($action) {
  "listimages" {
    test_vars_not_null @("imageStoragePath")
    list_images $CONF.imageStoragePath
  }
  "deleteimage" {
    test_vars_not_null @("imageStoragePath", "caaspImage")
    if ($Force) {
      delete_image $CONF.imageStoragePath $CONF.caaspImage
    }
    Else {
      $confirm = Read-Host "Do you really want to delete images ?, Only 'yes' will be accepted to confirm"
      if ($confirm -eq 'yes') {
        delete_image $CONF.imageStoragePath $CONF.caaspImage
      }
      Else {
        log_warning -Message "Delete cancelled"
        exit
      }
    }
  }
  "fetchimage" {
    test_vars_not_null @("caaspImageSourceUrl", "imageStoragePath")
    fetch_image $CONF.caaspImageSourceUrl $CONF.imageStoragePath
  }
  "plan" {
    test_vars_not_null @("stackName", "caaspImage")
    plan_deploy    
  }
  "deploy" {
    test_vars_not_null @("stackName", "caaspImage")
    if ($Force) {
      destroy_caasp -Force:$Force
      deploy_caasp
    }
    Else {
      deploy_caasp
    }
    generate_state_file
  }
  "status" {
    status_caasp
  }
  "destroy" {
    test_vars_not_null @("stackName")
    if ($Force) {
      destroy_caasp -Force:$Force
    }
    Else {
      $confirm = Read-Host "Do you really want to destroy?, Only 'yes' will be accepted to confirm"
      if ($confirm -eq 'yes') {
        destroy_caasp
      } 
      Else {
        log_warning -Message "Destroy cancelled"
        exit
      }
    }
  }
}
Stop-Transcript
Exit
