# Модуль 5 - Настройка Storage spaces и дедупликации

Продолжительность: 90 минут

## Подготовка к лабораторной работе
Для выполнения этой лабораторной работы вы создадите виртуальные машины при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги:
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Начните печатать **PowerShell**
1. Запустите **Windows PowerShell**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    > Этот скрипт загружает файлы, необходимые для выполнения лабораторной работы  

    ```powershell
    Remove-Item -Path c:\labs -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    $url = "https://github.com/sslukin/ws2016-training/archive/refs/heads/main.zip"
    $zip = "c:\ws2016.zip"
    $expand = "C:\ws2016-training-main"
    Start-BitsTransfer -Source $url -Destination $zip -TransferType Download
    Expand-Archive $zip -DestinationPath c:\
    Copy-Item "$expand\Labs" -Destination c:\Labs -Recurse
    Remove-Item $zip, $expand -Confirm:$false -Force -Recurse
    ```  
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**: 
     > Этот скрипт устанавливает виртуальную машину и подключает ее к домену Active Directory:  

   ```powershell
    $SwitchName = "Int"
    $dirVM = "C:\VM"
    $vm = "LON-SVR4"
    
    New-VHD -ParentPath "$dirVM\win2016base.vhdx" -Path "$dirVM\$vm.vhdx" -Differencing
    
    $d = Mount-VHD -Path "$dirVM\$vm.vhdx" -Passthru
    $dl = $d | Get-Partition | select -Last 1 -ExpandProperty DriveLetter
    Copy-Item C:\Labs\Lab03\unattend-svr4.xml "$($dl):\unattend.xml"
    $d | Dismount-VHD
    
    New-VM -Name $vm -VHDPath "$dirVM\$vm.vhdx" -Generation 2 -SwitchName $SwitchName
    Set-VM -Name $vm -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 2GB
    1..10 | % { 
        $path = "$dirVM\lon-svr4-disk$_.vhdx"
        New-VHD -Path $path -SizeBytes 32GB -Dynamic
        Add-VMHardDiskDrive -VMName $vm -Path $path -ControllerType SCSI
    }
    Start-VM -Name $vm
    
    $pass = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
    $LocalCred = New-Object System.Management.Automation.PSCredential ("Administrator", $pass)
    $DomainCred = New-Object System.Management.Automation.PSCredential ("Adatum\Administrator", $pass)
    
    $session = $null
    for (;;) 
    {
        $session = New-PSSession -VMName $vm -Credential $LocalCred -ErrorAction SilentlyContinue -ErrorVariable err
        if (!$err) { break }
        Start-Sleep -Seconds 10
    }
    
    Invoke-Command -Session $session -ScriptBlock {
        $net = Get-NetAdapter "Ethernet"
        $net | new-NetIPAddress -IPAddress 172.16.0.24 -PrefixLength 16 -AddressFamily IPv4
        $net | Set-DnsClientServerAddress -ServerAddresses 172.16.0.1
        Start-Sleep -Seconds 5
        Add-Computer -DomainName "Adatum" -LocalCredential $using:LocalCred -Credential $using:DomainCred -Force -Restart -Confirm:$false
    }
    
    vmconnect localhost $vm
    ```
1. Подождите примерно 5 минут. 
1. Введите следующие данные:
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**

# Lab A: Внедрение Storage Spaces

## Сценарий лабораторной работы
Adatum Corporation has purchased a number of hard disk drives and SSDs and you have been tasked with creating a storage solution that can utilize these new devices to the fullest. With mixed requirements in Adatum for data access and redundancy, you must ensure that you have a redundancy solution for critical data that does not require fast disk read and write access. You also must create a solution for data that does require fast read and write access.
You decide to use Storage Spaces and storage tiering to meet the requirements.

## Задание 1: Creating a Storage Space
### Шаг 1: Create a storage pool from six disks that are attached to the server
1. На **LON-SVR4** нажмите кнопку **Start**, запустите **Server Manager**
2. В Server Manager в панели слева нажмите **File and Storage Services**, затем в панели **Servers** нажмите **Storage Pools**
3. In the STORAGE POOLS pane, click TASKS, and then, in the TASKS drop-down list, click New Storage Pool.
4. In the New Storage Pool Wizard, on the Before you begin page, click Next.
5. On the Specify a storage pool name and subsystem page, in the Name text box, type StoragePool1, and then click Next.
6. On the Select physical disks for the storage pool page, select the first six disks in the Physical disks list and then click Next.
7. On the Confirm selections page, click Create.
8. On the View results page, wait until the task completes, and then click Close.

### Шаг 2: Create a three-way mirrored virtual disk (need at least five physical disks)
1. On LON-SVR4, in Server Manager, in the Storage Pools pane, click StoragePool1.
2. In the VIRTUAL DISKS pane, click TASKS, and then, from the TASKS drop-down list, click New Virtual Disk.
3. In the Select the storage pool dialog box, click StoragePool1, and then click OK.
4. In the New Virtual Disk Wizard, on the Before you begin page, click Next.
5. On the Specify the virtual disk name page, in the Name text box, type Mirrored Disk, and then click Next.
6. On the Specify enclosure resiliency page, click Next.
7. On the Select the storage layout page, in the Layout list, click Mirror, and then click Next.
8. On the Configure the resiliency settings page, click Three-way mirror, and then click Next.

> Note: If the three-way resiliency setting is unavailable, proceed to the next step in the lab.

9. On the Specify the provisioning type page, click Thin, and then click Next.
10. On the Specify the size of the virtual disk page, in the Specify size text box, type 10, and then click Next.
11. On the Confirm selections page, click Create.
12. On the View results page, wait until the task completes. 
13. Ensure that the Create a volume when this wizard closes check box is selected, and then click Close.
14. In the New Volume Wizard window, on the Before you begin page, click Next.
15. On the Select the server and disk page, in the Disk pane, click the Mirrored Disk virtual disk, and then click Next.
16. On the Specify the size of the volume page, click Next to confirm the default selection.
17. On the Assign to a drive letter or folder page, in the Drive letter drop-down list, ensure that H is selected, and then click Next.
18. On the Select file system settings page, in the File system drop-down list, click ReFS, in the Volume label text box, type Mirrored Volume, and then click Next.
19. On the Confirm selections page, click Create. 
20. On the Completion page, wait until the creation completes, and then click Close.

### Шаг 3: Copy a file to the volume, and verify it is visible in File Explorer
1. On LON-SVR4, click Start, on the Start screen, type command prompt, and then press Enter.
2. When you receive the command prompt, type the following command, and then press Enter:
    ```powershell
    Copy C:\windows\system32\write.exe H:\
    ```
1. Close Command Prompt.
1. On the taskbar, click the File Explorer icon.
1. In the File Explorer window, in the navigation pane, click Mirrored Volume (H:). 
1. Verify that write.exe is visible in the file list.
1. Close File Explorer.

### Шаг 4: Remove a physical drive to simulate drive failure
1. On the host computer, open Hyper-V Manager.
2. In the Virtual Machines pane, right-click LON-SVR4, and then click Settings.
3. In Settings for LON-SVR4, in the Hardware pane, click the hard drive that begins with LON-SVR4-Disk1.
4. In the Hard Drive pane, click Remove, click OK, and then click Continue.

### Шаг 5: Verify that the file is still available
1. Switch to LON-SVR4.
2. On the taskbar, click the File Explorer icon.
3. In the File Explorer window, in the navigation pane, click Mirrored Volume (H:). 
4. In the file list pane, verify that write.exe is still available.
5. Close File Explorer.
6. In Server Manager, in the STORAGE POOLS pane, on the menu bar, click Refresh “Storage Pools”. 

Note: Notice the warning that is visible next to Mirrored Disk.

7. In the VIRTUAL DISK pane, right-click Mirrored Disk, and then click Properties.
8. In the Mirrored Disk Properties dialog box, in the left pane, click Health. 

Note: Notice that the Health Status indicates a warning. The Operational Status should indicate one or more of the following: Incomplete, Unknown, or Degraded.

9. In the Mirrored Disk Properties dialog box, click OK.

### Шаг 6: Add a new disk to the storage pool and remove the broken disk
1. On LON-SVR4, in Server Manager, in the STORAGE POOLS pane, on the menu bar, click Refresh “Storage Pools”. 
2. In the STORAGE POOLS pane, right-click StoragePool1, and then click Add Physical Disk.
3. In the Add Physical Disk window, click the first disk in the list, and then click OK.
4. Right-click Start, and then click Windows PowerShell (Admin).
5. In Windows PowerShell, type the following command, and then press Enter:
    ```powershell
    Get-PhysicalDisk
    ```
  
1. Note the FriendlyName for the disk that shows an OperationalStatus of Lost Communication. 
1. In Windows PowerShell, type the following command, and then press Enter:
    ```powershell
    $Disk = Get-PhysicalDisk -FriendlyName ‘diskname’
    ```
  
  Replace diskname with the name of the disk that you noted in Step 6.
1. In Windows PowerShell, type the following command, and then press Enter:
    ```powershell
    Remove-PhysicalDisk -PhysicalDisks $disk -StoragePoolFriendlyName StoragePool1
    ```
  
1. In Windows PowerShell, type Y, and then press Enter.
1. In Server Manager, in the STORAGE POOLS pane, on the menu bar, click the Refresh “Storage Pools” button to see the warnings disappear.

## Задание 2: Enabling and configuring storage tiering
### Шаг 1: Use the Get-PhysicalDisk cmdlet to view all available disks on the system
1. On LON-SVR4, right-click Start, and then click Windows PowerShell (Admin).
2. In Windows PowerShell, type the following command, and then press Enter:  
    ```powershell
    Get-PhysicalDisk
    ```
  
### Шаг 2: Create a new storage pool
1. In the Windows PowerShell command prompt, type the following command, and then press Enter:
    ```powershell
    $canpool = Get-PhysicalDisk –CanPool $true
    ```
2. At the Windows PowerShell command prompt, type the following command, and then press Enter:
    ```powershell
    New-StoragePool -FriendlyName "TieredStoragePool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $canpool
    ```
3. At the Windows PowerShell command prompt, type the following command, and then press Enter:
    > This configures the disk names for the next part of the exercise.
    ```powershell
    $i = 1
    $disks = Get-StoragePool -FriendlyName TieredStoragePool | Get-PhysicalDisk
    Foreach ($disk in $disks)
        {Get-PhysicalDisk -UniqueId $disk.UniqueID | Set-PhysicalDisk -NewFriendlyName (“PhysicalDisk$i”)
        $i++}
    ```

### Шаг 3: View the media types
1. On LON-SVR4, at the Windows PowerShell command prompt, type the following command, and then press Enter:
    ```powershell
    Get-StoragePool –FriendlyName TieredStoragePool | Get-PhysicalDisk | Select FriendlyName, MediaType, Usage, BusType
    ```
  
### Шаг 4: Specify the media type for the sample disks and verify that the media type is changed
1. On LON-SVR4, at the Windows PowerShell command prompt, type the following command, and then press Enter:
    ```powershell
    Set-PhysicalDisk –FriendlyName PhysicalDisk1 –MediaType SSD
    Set-PhysicalDisk –FriendlyName PhysicalDisk2 –MediaType HDD
    Get-PhysicalDisk | Select FriendlyName, MediaType, Usage, BusType
    ```
  
### Шаг 5: Create pool-level storage tiers by using Windows PowerShell
1. On LON-SVR4, at the Windows PowerShell command prompt, type the following command, and then press Enter:
    ```powershell
    New-StorageTier –StoragePoolFriendlyName TieredStoragePool -FriendlyName HDD_Tier –MediaType HDD

    New-StorageTier –StoragePoolFriendlyName TieredStoragePool -FriendlyName SSD_Tier –MediaType SSD
    ```
  
### Шаг 6: Create a new virtual disk with storage tiering by using the New Virtual Disk Wizard
1. On LON-SVR4, in Server Manager, in the Storage Pools pane, click Refresh, and then click TieredStoragePool.
2. In the VIRTUAL DISKS pane, click TASKS, and then in the TASKS drop-down list, click New Virtual Disk.
3. In the Select the storage pool dialog, click TieredStoragePool, and then click OK.
4. In the New Virtual Disk Wizard, on the Before you begin page, click Next.
5. On the Specify the virtual disk name page, in the Name text box, type TieredVirtDisk, select Create storage tiers on this virtual disk, and then click Next.
6. On the Specify enclosure resiliency page, click Next.
7. On the Select the storage layout page, in both the Layout lists, click Simple, and then click Next.
8. On the Specify the provisioning type page, click Next.
9. On the Specify the size of the virtual disk page, in both the Specify size text boxes, type 2, clear the Enable read cache check box, and then click Next.

> Note: Based on your storage subsystem, the Enable read cache check box may not be present.

10. On the Confirm selections page, click Create.
11. On the View results page, wait until the task completes. 
12. Ensure that Create a volume when this wizard closes is selected, and then click Close.
13. In the New Volume Wizard, on the Before you begin page, click Next.
14. On the Select the server and disk page, in the Disk pane, click the TieredVirtDisk virtual disk, and then click Next.
15. On the Specify the size of the volume page, click Next to confirm the default selection.
16. On the Assign to a drive letter or folder page, in the Drive letter drop-down list, ensure that R is selected, and then click Next.
17. On the Select file system settings page, in the File system drop-down list, click ReFS. In the Volume label text box, type Tiered Volume, and then click Next.

> Note: If ReFS is not available from the file system drop-down menu, select NTFS.

18. On the Confirm selections page, click Create. 
19. On the Completion page, wait until the creation completes, and then click Close.
20. In Server Manager, right-click the virtual disk you just created, and then click Properties.
21. In the TieredVirtDisk Properties window, on the General tab, observe the Storage tiers, Capacity, Allocated space, and Used pool space details. 
22. Click the Health tab, and observe the Storage layout details, and then click OK.


# Lab B: Implementing Data Deduplication

Scenario
After you have tested the storage redundancy and performance options, you decide that it also would be beneficial to maximize the available disk space that you have, especially on generic file servers. You decide to test Data Deduplication solutions to maximize storage availability for users.
New: After you have tested the storage redundancy and performance options, you now decide that it would also be beneficial to maximize the available disk space that you have, especially around virtual machine storage which is in ever increasing demand. You decide to test out Data Deduplication solutions to maximize storage availability for virtual machines.

## Задание 1: Installing Data Deduplication
### Шаг 1: Install the Data Deduplication role service
1. On LON-SVR4, in Server Manager, in the navigation pane, click Dashboard.
2. In the details pane, click Add roles and features.
3. In the Add Roles and Features Wizard, on the Before you begin page, click Next.
4. On the Select installation type page, click Next.
5. On the Select destination server page, click Next.
6. On the Select server roles page, in the Roles list, expand File and Storage Services (4 of 12 installed). 
7. Expand File and iSCSI Services (3 of 11 installed).
8. Select the Data Deduplication check box, and then click Next.
9. On the Select features page, click Next.
10. On the Confirm installation selections page, click Install. 
11. When installation is complete, on the Installation progress page, click Close.

### Шаг 2: Check the status of Data Deduplication
1. On LON-SVR4, switch to Windows PowerShell.
2. In the Windows PowerShell command prompt window, type the following command, and then press Enter:
  Get-DedupVolume 
3. In the Windows PowerShell command prompt window, type the following command, and then press Enter:
  Get-DedupStatus 
4. These commands return no results. This is because you need to enable it on the volume after installing it.

### Шаг 3: Verify the virtual machine performance
1. On LON-SRV1, in the Windows PowerShell window, type the following, and then press Enter:
    ```powershell
    Measure-Command -Expression {Get-ChildItem –Path D:\ -Recurse}
    ```

> Note: You will use the values returned from the previous command later in the lab.

## Задание 2: Configuring Data Deduplication
### Шаг 1: Configure Data Deduplication
1. On LON-SVR4, on the taskbar, click the File Explorer icon.
2. In Server Manager, in the navigation pane, click File and Storage Services, and then click Disks.
3. In the Disks pane, click 1.
4. Beneath VOLUMES, click D.
5. Right-click D, and then click Configure Data Deduplication.
6. In the Allfiles (D:\) Deduplication Settings dialog box, in the Data deduplication list, click General purpose file server.
7. In the Deduplicate files older than (in days) text box, type 0.
8. Click Set Deduplication Schedule.
9. In the LON-SVR4 Deduplication Schedule dialog box, select the Enable throughput optimization check box, and then click OK.
10. In the Allfiles (D:\) Deduplication Settings dialog box, click Add. 
11. In the Select Folder dialog box, expand Allfiles (D:), click shares.
12. Click Select Folder, and then click OK.

### Шаг 2: Configure optimization to run now and view the status
1. On LON-SRV1, in the Windows PowerShell window, type the following command, and then press Enter:
    ```powershell
    Start-DedupJob D: -Type Optimization –Memory 50

    Get-DedupJob –Volume D:
    ```  
> Note: Verify the status of the optimization job from the previous command. Repeat the `Get-DedupJob` command until the Progress shows as 100%.
  
### Шаг 3: Verify if the file has been optimized
1. On LON-SVR4, in File Explorer, navigate to D:\Labfiles\Mod04.
2. Right-click ContosoP1AnnualReport.docx, and then select Properties. 
3. In the Properties window, observe the values of Size and Size on disk and note any differences.
4. Repeat steps 2 and 3 for a few more files to verify deduplication.
5. Switch to Windows PowerShell.
6. In the Windows PowerShell command prompt window, type the following command, and then press Enter:
    ```powershell
    Get-DedupStatus –Volume D: |fl
    Get-DedupVolume –Volume D: |fl
    ```

> Note: Observe the number of optimized files.

8. In Server Manager, in the navigation pane, click File and Storage Services, and then click Disks.
9. In the DISKS pane, click 1.
10. Beneath VOLUMES, click D.
11. Click Refresh and observe the values for Deduplication Rate and Deduplication Savings. 

> Note: Because most of the files on drive D are small, you may not notice a significant amount of saved space.

### Шаг 4: Verify VM performance again
1. In the Windows PowerShell window, type the following command, and then press Enter:
    ```powershell
    Measure-Command -Expression {Get-ChildItem –Path D:\ -Recurse}
    ```

> Note: Compare the values returned from the previous command with the value of the same command earlier in the lab to assess if system performance has changed.