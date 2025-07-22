foreach($vm in (Get-View -ViewType VirtualMachine -Property Name,runtime.powerState,Guest.net,Config.Hardware.numCPU,Config.Hardware.MemoryMB,Runtime.Host,Guest.GuestFullName,
Config.GuestFullName,Parent,ResourcePool,Config.Hardware.Device,Config.version,guest.toolsversionstatus,
Config.Files.VMPathName)){
    $t = Get-View $vm.ResourcePool -Property Name,Parent
    while($t.getType().Name -eq "ResourcePool"){
       $t = Get-View $t.Parent -Property Name,Parent
    }
        if($t.GetType().Name -eq "ClusterComputeResource"){
        $cluster = $t.Name
        }
        else{
            $cluster = "Stand Alone Host"
        }
    while($t.getType().Name -ne "Datacenter"){
        $t = Get-View $t.Parent -Property Name,Parent
    }
    $datacenter = $t.Name
  
    $vm.Config.Hardware.Device | where {$_.GetType().Name -eq "VirtualDisk"} |
    Select @{N="vCenter";E={$script:vmhost = Get-View -Id $vm.Runtime.Host; $script:vmhost.Client.ServiceUrl.Split('/')[2]}},
    @{N="VM";E={$vm.Name}},
    @{N='powerState';E={$vm.runtime.powerState}},
    @{N='IP';E={[string]::Join(',',($vm.Guest.Net | %{$_.IpAddress | where{$_.Split('.').Count -eq 4} | %{$_}}))}},
    @{N='NumCPU';E={$vm.config.Hardware.NumCpu}},
    @{N='Memory GB';E={$vm.Config.Hardware.MemoryMB| %{[math]::Round($_/1kb,2)}}},
    @{N='VMHost';E={$script:esx = Get-View -Id $vm.Runtime.Host; $script:esx.name}},
    @{N='GuestOS';E={$vm.Guest.GuestFullName}},
    @{N='ConfiguredOS';E={$vm.Config.GuestFullName}},
    #@{N="Folder";E={$path}},
    @{N="Cluster";E={$cluster}},
    @{N="Datacenter";E={$datacenter}},
    @{N="Scsi";E={$_.UnitNumber}},
    @{N="Hard Disk";E={$_.DeviceInfo.Label}},
    @{N="Disk datastore";E={$_.Backing.Filename.Split(']')[0].TrimStart('[')}},
    @{N="Disk capacity GB";E={$_.CapacityInKB| %{[math]::Round($_/1MB,2)}}},
    @{N="Disk type";E={
            if($_.Backing.GetType().Name -match "flat"){
                "Flat"
            }
            else{
                $_.Backing.CompatibilityMode
            }}},
   @{N='DeviceName';E={
    if($_.Backing.GetType().Name -match 'raw'){
      $_.Backing.DeviceName
    }
    else{
      $script:lunnaa = (Get-View -Id $_.Backing.Datastore).Info.Vmfs.Extent[0].DiskName
      $script:lun = $script:esx.Config.StorageDevice.ScsiLun | where{$_.CanonicalName -eq $script:lunnaa}
      $script:lun.Descriptor | where{$_.Id -match 'vml.'} | Select -ExpandProperty Id
    }}},
   @{N='LUN NAA';E={
    if($_.Backing.GetType().Name -match 'raw'){
      $lunUuid = $_.Backing.LunUuid
      $script:lun = $script:esx.Config.StorageDevice.ScsiLun | where{$_.Uuid -eq $lunUuid}
      $script:lun.CanonicalName
    }
    else{
      $script:lunnaa
    }}},
   @{N='LUN ID';E={
      $dev = $script:esx.Config.StorageDevice.PlugStoreTopology.Device | where {$_.Lun -eq $script:lun.Key}
      $script:esx.Config.StorageDevice.PlugStoreTopology.Path | where {$_.Device -eq $dev.Key} |
      Select -First 1 -ExpandProperty LunNumber
    }},
   @{N='VMConfigFile';E={$VM.config.files.VMpathname}},
   @{N='VMDKPath';E={$_.Backing.FileName}},
   @{N="HW Version";E={$vm.Config.version}},
   @{N="Tools Status";E={$vm.guest.toolsversionstatus}},
   @{N="NIC Name";E={($vm.config.hardware.device | where {($_.DeviceInfo.Label -like "Network*")}).DeviceInfo.Label}},
   @{N="Mac"; E={($vm.Config.Hardware.Device | where{$_.DeviceInfo.Label -like "Network*"}).MacAddress}},
   @{N="Portgroup"; E={
     $nic = $vm.Config.Hardware.Device | where{$_.DeviceInfo.Label -like "Network*"}
     [string]::Join(',',(
       $nic | %{
       if($_.DeviceInfo.Summary -notmatch 'DVSwitch'){
         $_.DeviceInfo.Summary
       }
       else{
         Get-View -ViewType DistributedVirtualPortgroup -Property Name -Filter @{'Key'=$_.Backing.Port.PortgroupKey} |
         Select -ExpandProperty Name
       }}))}}
}