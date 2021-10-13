Get-VM | ? Name -like "LON-SVR*" | Stop-VM -TurnOff -Force -Confirm:$false -ErrorAction SilentlyContinue

$SwitchName = "Cluster Network"
if ((Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue).Count -eq 0) {
    New-VMSwitch -Name $SwitchName -SwitchType Privat
}
Add-VMNetworkAdapter -VMName "LON-SVR2" -SwitchName $SwitchName -DeviceNaming On -Name $SwitchName
Add-VMNetworkAdapter -VMName "LON-SVR3" -SwitchName $SwitchName -DeviceNaming On -Name $SwitchName

$SwitchName = "iSCSI Storage Network"
if ((Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue).Count -eq 0) {
    New-VMSwitch -Name $SwitchName -SwitchType Private
}
Add-VMNetworkAdapter -VMName "LON-SVR2" -SwitchName $SwitchName -DeviceNaming On -Name $SwitchName
Add-VMNetworkAdapter -VMName "LON-SVR3" -SwitchName $SwitchName -DeviceNaming On -Name $SwitchName

"LON-SVR2", "LON-SVR3" | Start-VM

$pass = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential ("Adatum\Administrator", $pass)

$vm = "LON-SVR2"
$session = $null
for (;;) 
{
    $session = New-PSSession -VMName $vm -Credential $DomainCred -ErrorAction SilentlyContinue -ErrorVariable err
    if (!$err) { break }
    Start-Sleep -Seconds 10
}

Invoke-Command -Session $session -ScriptBlock {

    Get-NetAdapter | ? name -ne "Ethernet" | % {
        $name = $_.Name
        $switch = (Get-NetAdapterAdvancedProperty -Name $name | ? DisplayName -eq "Hyper-V Network Adapter Name" | select -ExpandProperty DisplayValue)
        Rename-NetAdapter -Name $name -NewName $switch
    }
    Start-Sleep -Seconds 5
    Get-NetAdapter "iSCSI Storage Network" | New-NetIPAddress -IPAddress 10.100.100.2 -PrefixLength 24 -AddressFamily IPv4
    Get-NetAdapter "Cluster Network" | New-NetIPAddress -IPAddress 10.200.100.2 -PrefixLength 24 -AddressFamily IPv4
}

$vm = "LON-SVR3"
$session = $null
for (;;) 
{
    $session = New-PSSession -VMName $vm -Credential $DomainCred -ErrorAction SilentlyContinue -ErrorVariable err
    if (!$err) { break }
    Start-Sleep -Seconds 10
}

Invoke-Command -Session $session -ScriptBlock {

    Get-NetAdapter | ? name -ne "Ethernet" | % {
        $name = $_.Name
        $switch = (Get-NetAdapterAdvancedProperty -Name $name | ? DisplayName -eq "Hyper-V Network Adapter Name" | select -ExpandProperty DisplayValue)
        Rename-NetAdapter -Name $name -NewName $switch
    }
    Start-Sleep -Seconds 5
    Get-NetAdapter "iSCSI Storage Network" | New-NetIPAddress -IPAddress 10.100.100.3 -PrefixLength 24 -AddressFamily IPv4
    Get-NetAdapter "Cluster Network" | New-NetIPAddress -IPAddress 10.200.100.3 -PrefixLength 24 -AddressFamily IPv4
}