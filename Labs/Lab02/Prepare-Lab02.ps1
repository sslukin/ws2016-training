$dirWindowsServerImage = "C:\iso"
$dirVM = "C:\VM"

New-Item -Path "c:\" -Name "VM" -ItemType "directory" -Confirm:$false -ErrorAction SilentlyContinue

$vhdPath = "$dirVM\Win2016Base.vhdx"
$imageName = "Windows Server 2016 Standard (Desktop Experience)"

if (Test-Path $dirWindowsServerImage) {
    
    $dirISO = Resolve-Path $dirWindowsServerImage
    $isoFile = Get-ChildItem -Path $dirISO | select -First 1

    if ($isoFile -ne $null)
    {
        New-VHD -Path $vhdPath -Dynamic -SizeBytes 30GB
        $d = Mount-VHD -Path $vhdPath -Passthru
        $d | Initialize-Disk -PartitionStyle GPT
        
        $efipart = $d | New-Partition -Size 100MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
        $efipart | Format-Volume -FileSystem FAT32 -Confirm:$false
        $EFIDriveLetter = (ls function:[d-z]: -n | ? { !(Test-Path $_) } | select -First 1).Substring(0, 1)
        $efipart | Set-Partition -NewDriveLetter $EFIdriveLetter

        $winpart = $d | New-Partition -UseMaximumSize
        $winpart | Format-Volume -FileSystem NTFS -Confirm:$false
        $WinDriveLetter = (ls function:[d-z]: -n | ? { !(Test-Path $_) } | select -First 1).Substring(0, 1)
        $winpart | Set-Partition -NewDriveLetter $WinDriveLetter
        $vhdMountedPath = "${WinDriveLetter}:\"

        $iso = Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO -Access ReadOnly -PassThru
        $isoDrive = ($iso | Get-Volume).DriveLetter
        $isoImage = "$($isoDrive):\sources\install.wim"
        $imageIndex = (Get-WindowsImage -ImagePath $isoImage | ? ImageName -eq $imageName).ImageIndex
        
        $dism = Start-Process -FilePath "$env:SystemRoot/system32/Dism.exe" -Wait -NoNewWindow -PassThru `
        -ArgumentList "/apply-image /imagefile:$isoImage /index:$imageIndex /ApplyDir:$vhdMountedPath /English"
        
        $vhdMountedPathW = $vhdMountedPath + "Windows"
        
        Start-Process -FilePath "$vhdMountedPathW\system32\bcdboot.exe" -Wait -NoNewWindow -PassThru `
        -ArgumentList "$vhdMountedPathW `/s $EFIDriveLetter`: /f UEFI /l en-us"

        $efipart | Remove-PartitionAccessPath -AccessPath "$EFIDriveLetter`:"

        Dismount-VHD $vhdPath
        $iso | Dismount-DiskImage
    }
}


$SwitchName = "Int"
if ((Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue).Count -eq 0) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal
}

$vm1 = "LON-DC1"
Copy-Item -Path $vhdPath -Destination "$dirVM\$vm1.vhdx"

$d = Mount-VHD -Path "$dirVM\$vm1.vhdx" -Passthru
$dl = $d | Get-Partition | select -Last 1 -ExpandProperty DriveLetter
Copy-Item C:\Labs\Lab-2\unattend-dc.xml "$($dl):\unattend.xml"
$d | Dismount-VHD

New-VM -Name $vm1 -VHDPath "$dirVM\$vm1.vhdx" -Generation 2 -SwitchName $SwitchName
Set-VM -Name $vm1 -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 4GB

$vm2 = "LON-SVR6"
New-VHD -Path "$dirVM\$vm2.vhdx" -Dynamic -SizeBytes 30GB
New-VM -Name "LON-SVR6" -VHDPath "$dirVM\$vm2.vhdx" -Generation 2 -SwitchName $SwitchName
Set-VM -Name "LON-SVR6" -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 4GB

Start-VM -Name $vm1

$pass = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ("Administrator", $pass)
$DomainCred = New-Object System.Management.Automation.PSCredential ("Adatum\Administrator", $pass)

$session = $null
$running = $false
do
{
    $session = New-PSSession -VMName $vm1 -Credential $LocalCred -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err)
    {
        Start-Sleep -Seconds 10
    }
    else
    {
        $running = $true
    }
} while (!$running)

Invoke-Command -Session $session -ScriptBlock {

    $net = Get-NetAdapter "Ethernet"
    $net | new-NetIPAddress -IPAddress 172.16.0.1 -PrefixLength 16 -AddressFamily IPv4
    $net | Set-DnsClientServerAddress -ServerAddresses 172.16.0.1


    Install-WindowsFeature DNS,AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools

    # Domain setup
    Import-Module ADDSDeployment

    #properties of the domain
    Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012" `
    -DomainName "adatum.local" `
    -DomainNetbiosName "Adatum" `
    -ForestMode "Win2012" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$true `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $Using:pass `
    -Force:$true

    Restart-Computer -Force -Confirm:$false 
}
$session | Remove-PSSession


$session = $null
$running = $false
do
{
    $session = New-PSSession -VMName $vm1 -Credential $DomainCred -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err)
    {
        Start-Sleep -Seconds 10
    }
    else
    {
        $running = $true
    }
} while (!$running)

Invoke-Command -Session $session -ScriptBlock {

    $net = Get-NetAdapter "Ethernet"
    $net | Set-DnsClientServerAddress -ServerAddresses 172.16.0.1
    $net | Disable-NetAdapter -Confirm:$false
    $net | Enable-NetAdapter -Confirm:$false
}
$session | Remove-PSSession