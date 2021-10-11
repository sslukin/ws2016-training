Write-Host "Suppress Windows format disk promt"
Stop-Service -Name ShellHWDetection

Write-Host "Initializing folders"
$dirWindowsServerImage = "C:\iso"
$dirVM = "C:\VM"

New-Item -Path "c:\" -Name "VM" -ItemType "directory" -Confirm:$false -ErrorAction SilentlyContinue

$vhdPath = "$dirVM\Win2016Base.vhdx"
$imageName = "Windows Server 2016 SERVERDATACENTER"

$dirISO = Resolve-Path $dirWindowsServerImage
$isoFile = Get-ChildItem -Path $dirISO | select -First 1

Write-Host "Creating base VHD"
New-VHD -Path $vhdPath -Dynamic -SizeBytes 30GB
$d = Mount-VHD -Path $vhdPath -Passthru
$d | Initialize-Disk -PartitionStyle GPT
        
$efipart = $d | New-Partition -Size 100MB -AssignDriveLetter
$efipart | Format-Volume -FileSystem FAT32 -Confirm:$false
$EFIDriveLetter = $efipart.DriveLetter

$winpart = $d | New-Partition -UseMaximumSize -AssignDriveLetter
$winpart | Format-Volume -FileSystem NTFS -Confirm:$false
$WinDriveLetter = $winpart.DriveLetter
$vhdMountedPath = "${WinDriveLetter}:\"

$iso = Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO -Access ReadOnly -PassThru
$isoDrive = ($iso | Get-Volume).DriveLetter
$isoImage = "$($isoDrive):\sources\install.wim"
$imageIndex = 4
#Get-WindowsImage -ImagePath $isoImage

Write-Host "Applying Windows image to VHD"
$dism = Start-Process -FilePath "$env:SystemRoot/system32/Dism.exe" -Wait -NoNewWindow -PassThru `
-ArgumentList "/apply-image /imagefile:$isoImage /index:$imageIndex /ApplyDir:$vhdMountedPath /English"
        
$vhdMountedPathW = $vhdMountedPath + "Windows"

Write-Host "Making disk bootable"
Start-Process -FilePath "$vhdMountedPathW\system32\bcdboot.exe" -Wait -NoNewWindow -PassThru `
-ArgumentList "$vhdMountedPathW `/s $EFIDriveLetter`: /f UEFI /l en-us"

$efipart | Set-Partition -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"

Dismount-VHD $vhdPath
$iso | Dismount-DiskImage

Write-Host "Creating Hyper-V switch"
$SwitchName = "Int"
if ((Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue).Count -eq 0) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal
}

Write-Host "Creating a differencing VHD for DC1"
$vm1 = "LON-DC1"
#Copy-Item -Path $vhdPath -Destination "$dirVM\$vm1.vhdx"
New-VHD -ParentPath $vhdPath -Path "$dirVM\$vm1.vhdx" -Differencing

Write-Host "Copying unattend.xml"
$d = Mount-VHD -Path "$dirVM\$vm1.vhdx" -Passthru
$dl = $d | Get-Partition | select -Last 1 -ExpandProperty DriveLetter
Copy-Item C:\Labs\Lab02\unattend-dc.xml "$($dl):\unattend.xml"
$d | Dismount-VHD

Write-Host "Creating new VM for DC1"
New-VM -Name $vm1 -VHDPath "$dirVM\$vm1.vhdx" -Generation 2 -SwitchName $SwitchName
Set-VM -Name $vm1 -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 2GB

Write-Host "Starting VM DC1"
Start-VM -Name $vm1

Write-Host "Initializing credentials"
$pass = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ("Administrator", $pass)
$DomainCred = New-Object System.Management.Automation.PSCredential ("Adatum\Administrator", $pass)

Write-Host "Waiting for DC1 to complete installation"
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

Write-Host "Installing AD for DC1"
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
    -DomainName "adatum.com" `
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

Write-Host "Waiting for DC1 to complete AD installation"
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

Write-Host "Updating network adapter on DC1"
Invoke-Command -Session $session -ScriptBlock {

    $net = Get-NetAdapter "Ethernet"
    $net | Set-DnsClientServerAddress -ServerAddresses 172.16.0.1
    $net | Disable-NetAdapter -Confirm:$false
    $net | Enable-NetAdapter -Confirm:$false

    Remove-Item c:\unattend.xml -Confirm:$false -Force
}
$session | Remove-PSSession

Write-Host "Setup completed" -ForegroundColor Green