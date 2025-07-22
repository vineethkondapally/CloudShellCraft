Write-Host 'Provide vCenter Name in order to Connect'
$vcenters='',''
$vccred=Get-Credential -Message 'Enter Credentials to Login to vCenter'
Write-Host 'Provide Email address and SMPT info to send mail after script completion'
$Fromid=''
$toids=''
$smtpserver=''
Connect-VIServer -Server $vcenters -Credential $vccred
$location=Get-Location
$CurrentDate = Get-Date -Format 'MM-dd-yyyy_hh-mm-ss'
$logfilelocation= "$location\$($CurrentDate)logfile.txt"
$alltemplatesexportpath="$location\$($CurrentDate)-templateswindows.csv"
$Outputfile = "$location\AllTemplatepatchstatusreport.csv as on dated $($CurrentDate).csv" 
$csvFiles = @()
Write-Host "Enter Administrator Credentials for logging into templates" -ForegroundColor Yellow
$cred=Get-Credential -Message 'Template Login Administrator Credentials'
Start-Transcript -Path $logfilelocation -NoClobber -Force -Confirm:$false
$script = @' 
$report = @()
$ErrorActionPreference = "SilentlyContinue"
If ($Error) {
    $Error.Clear()
}
$updatesession=New-Object -ComObject Microsoft.update.session 
$Criteria="IsInstalled=0 and Type=Software and IsHidden=0"
$searchresult=$updateSession.CreateupdateSearcher().Search("IsInstalled=0 and Type='Software' and IsHidden=0").Updates 
$report = if(-not $searchresult.Count){
New-Object -TypeName PSObject -property @{
KB = ''
InstallStatus = 'There are no applicable updates for this computer.'
}
}
else{
$pendingdownloads=$searchresult | Where-Object {$_.IsDownloaded -eq $false}
if(($pendingdownloads |Select-Object IsDownloaded).count -ne '0'){
$downloadercall=$updatesession.CreateUpdateDownloader()
$downloadercall.Updates=New-Object -ComObject Microsoft.update.updatecoll
foreach($pendingdownload in $pendingdownloads){
[void]$downloadercall.Updates.add($pendingdownload)
$downloadercall.Download() |Out-Null
[void]$downloadercall.Updates.RemoveAt(0)
}
}
$updatesession=New-Object -ComObject Microsoft.update.session
$Criteria="IsInstalled=0 and Type=Software and IsHidden=0"
$searchresult=$updateSession.CreateupdateSearcher().Search("IsInstalled=0 and Type='Software' and IsHidden=0").Updates
$downloadedupdates = $searchresult  | Where-Object {$_.IsDownloaded -eq $true}
$updatercall=$updatesession.CreateUpdateInstaller()
$updatercall.Updates= New-Object -ComObject Microsoft.update.updatecoll
foreach($singleupdate in $downloadedupdates){
[void]$updatercall.Updates.add($singleupdate)
$installstatus=$updatercall.install()
[void]$updatercall.Updates.RemoveAt(0)
New-Object -TypeName PSObject -property @{
KB = &{$kbnumb=$singleupdate.Title; $kbnumb.Substring($kbnumb.IndexOf("KB")).Trimend(")")}
InstallStatus = &{
if($installstatus.ResultCode -eq '2'){
    'KB Installed'
}
elseif($installstatus.ResultCode -eq '3'){
    'KB Install Succeeded with errors'
}
elseif($installstatus.ResultCode -eq '4'){
    'Kb Failed to install'
}
elseif($installstatus.ResultCode -eq '5'){
    'KBAborted'
}
elseif (-not $installstatus.ResultCode){
     'KB Failed to Download'
}
}
}
}
}
$report | ConvertTo-Csv -NoTypeInformation
'@
$tasks = @()
$alltemplates=Get-Datacenter | Get-Template |?{$_.ExtensionData.Guest.GuestFullName -match 'windows' -and $_.ExtensionData.runtime.connectionstate -eq 'connected'}  |Select-Object @{N='Name';E={$_.Name}},@{N="Portgroup";E={((Get-View -Id $_.ExtensionData.Network).name)}},@{N="vCenter";E={([System.Net.Dns]::GetHostEntry($_.Uid.Split(“:”)[0].Split(“@”)[1])).HostName}}
$alltemplates|Export-Csv -Path $alltemplatesexportpath -NoTypeInformation -NoClobber -UseCulture
foreach($singletemplate in $alltemplates){
Write-Host "Marking Template Name $($singletemplate.Name) to VM"
Set-Template -Template $singletemplate.Name -ToVM -Confirm:$false |fl
$templatevm= Get-VM $singletemplate.Name
if(-not $templatevm.Name){
Write-Host "Setting Template $($singletemplate.Name) to VM Failed Moving to Next Template"
}
else{
Write-Host "Collecting DHCP PortGroup Name for Vlanid 2067 from VMhost $($templatevm.VMHost)"
$dhcpportgroup=Get-VirtualPortGroup -VMHost $templatevm.VMHost |?{$_.ExtensionData.config.DefaultPortConfig.Vlan.VlanId -eq '2067'}
Write-Host "Collecting Network Adapter for $($templatevm.Name)" 
$nic=Get-NetworkAdapter -VM $templatevm.Name
Write-Host "Adding Network Adapter to VM $($templatevm.Name) if not Present" 
if($nic -eq $null){
New-NetworkAdapter -VM $templatevm.Name -Portgroup $dhcpportgroup -Type Vmxnet3 -StartConnected -Confirm:$false
}
else{
Write-Host "Changing Portgroup to $($dhcpportgroup.Name) to VM $($templatevm.Name)" 
Get-NetworkAdapter -VM $templatevm.Name |Set-NetworkAdapter -Portgroup $dhcpportgroup -Confirm:$false |fl
}
Write-Host "Starting VM $($templatevm.Name) and wait in loop till GuestOperationsReady is true " 
Start-VM -VM $templatevm.Name -Confirm:$false |fl
while($templatevm.ExtensionData.Guest.GuestOperationsReady -ne "True"){
Start-Sleep -Seconds 3
$templatevm.ExtensionData.UpdateViewData("Guest.GuestOperationsReady")
}
Write-Host "Updating vmtools on $($templatevm.Name) if they are Outdated"
if($templatevm.ExtensionData.guest.toolsversionstatus -eq 'guestToolsNeedUpgrade'){
$timeoutSeconds = 900
$start = (Get-Date)
$task = Get-View -Id (Update-Tools -VM $templatevm.Name -NoReboot  -RunAsync).Id
while((New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds -lt $timeoutSeconds -and 
($task.Info.State -eq [VMware.Vim.TaskInfoState]::running -or
$task.Info.State -eq [VMware.Vim.TaskInfoState]::queued)){
Sleep 5
$task.UpdateViewData()
}
if($task.Info.State -eq [VMware.Vim.TaskInfoState]::running){
$task.CancelTask()
}
elseif($task.Info.State -eq [VMware.Vim.TaskInfoState]::error){
Write-Error "Update Tools failed"
}
}
Write-Host "Waiting for GuestOperationsReady to be true on $($templatevm.Name)"
$templatevm.ExtensionData.UpdateViewData("Guest.GuestOperationsReady")
while($templatevm.ExtensionData.Guest.GuestOperationsReady -ne "True"){
Start-Sleep -Seconds 3
$templatevm.ExtensionData.UpdateViewData("Guest.GuestOperationsReady")
}
Write-Host "Performing Invoke Operation on $($templatevm.Name)"
$sInvoke = @{
VM            = $templatevm.Name
GuestCredential=$cred
ScriptText    = $script
ScriptType    = 'Powershell'
RunAsync      = $true
Confirm       = $false
}
$tasks += @{
VM = $templatevm.Name
Task = Invoke-VMScript @sInvoke
}
}
}
Write-Host "Invoke Operation is performed on all the templates and waiting for results to be collected"
while($tasks.Task.State -contains 'Running'){
sleep 2
Write-Host "waiting on Invoke Operation to Complete" -ForegroundColor Yellow -NoNewline
}
Write-Host "Passing tasks information to foreach loop"
$tasks |ForEach-Object -Process {
$vm=Get-VM -Name $_.VM
Write-Host "Stopping VM $($vm.Name) to Apply windows updates"
Stop-VMGuest -VM $vm.Name -Confirm:$false |Out-Null
while($vm.ExtensionData.Runtime.PowerState -ne 'poweredOff'){
Start-Sleep -Seconds 1
$vm.ExtensionData.UpdateViewData("Runtime.Powerstate")
}
Write-Host "Starting back the VM $($vm.Name) after applying updates"
Start-VM -VM $vm.Name -Confirm:$false |Out-Null
$vm.ExtensionData.UpdateViewData("Guest.GuestOperationsReady")
while($vm.ExtensionData.Guest.GuestOperationsReady -ne "True"){
Start-Sleep -Seconds 1
$vm.ExtensionData.UpdateViewData("Guest.GuestOperationsReady")
}
Write-Host "Performing Invoke operation on VM $($vm.Name) to check if all updates are installed"
$updatescheckscript=@'
$updateObject = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateObject.CreateUpdateSearcher()
$searchResults = $updateSearcher.Search("IsInstalled=0")
$timeoutValue = 1200
$startTime = Get-Date
while($searchResults.Updates.Count -ne '0' -and (New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -lt $timeoutValue){
Start-Sleep 1
$searchResults.Updates.Count
}
if((New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -ge $timeoutValue) {
'windows update completed Partially'
}
else{
'windows update completed sucessfully'
}
'@
$sInvoke = @{
VM            = $vm.Name
GuestCredential=$cred
ScriptText    = $updatescheckscript
ScriptType    = 'Powershell'
ErrorAction   = 'SilentlyContinue'
Confirm       = $false
}
$invokeresult=Invoke-VMScript @sInvoke
Write-Host "Result of invoke operation on VM $($vm.Name)"
Write-Host $invokeresult.ScriptOutput
Write-Host "Performing Stop operation on VM $($vm.Name) before converting to Template"
$maxCount = 3
$count = 0
while($count -lt $maxCount -and $vm.PowerState -ne 'PoweredOff' ){
Stop-VMGuest -VM $vm.Name -Confirm:$false |Out-Null
$count++
Sleep 300
$vm = Get-VM -Name $vm.Name
}
if($vm.PowerState -ne 'PoweredOff'){
Stop-VM -VM $vm -Confirm:$false |Out-Null
}
Write-Host "Updating report to csv"
if($_.Task.State -eq 'Success'){
$_.Task.Result.Scriptoutput | ConvertFrom-Csv |
Add-Member -MemberType NoteProperty -Name VM -Value $_.VM -PassThru |
Add-Member -MemberType NoteProperty -Name State -Value $_.Task.State -PassThru
}
else{
New-Object -TypeName PSObject -Property @{
VM = $_.VM
KB = ''
InstallStatus = ''
State = $_.Task.State
}
}
} | Select VM,State,KB,InstallStatus |Export-Csv -Path $Outputfile -NoTypeInformation -NoClobber -UseCulture
Write-Host "Saved results to csv file"
$csvFiles += $Outputfile
Write-Host "Converting Back to templates"
$alltemplates |ForEach-Object -Process {
Get-NetworkAdapter -VM $_.name |Set-NetworkAdapter -NetworkName $_.Portgroup -Confirm:$false -ErrorAction SilentlyContinue
Set-VM -VM $_.Name -ToTemplate -Confirm:$false -ErrorAction SilentlyContinue
}
Stop-Transcript
$csvFiles+=$logfilelocation
$csvFiles+=$alltemplatesexportpath
$smail = @{
From          = $Fromid
To            = $toids
Subject       = 'Template Patching Status'
Body          = 'This Mail contains 3 attachments- 1)List of templates which are going to be patched by the script. 2)Log file in text format 3)Templates path status after script execution'
Attachments   = $csvFiles
SmtpServer    =$smtpserver
    }
Send-MailMessage @smail