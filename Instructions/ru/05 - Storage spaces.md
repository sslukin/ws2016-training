# Модуль 5 - Настройка Storage spaces и дедупликации

Продолжительность: 90 минут

## Подготовка к лабораторной работе
Для выполнения этой лабораторной работы вы создадите виртуальные машины при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги на машине **HOST**:
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
    Copy-Item C:\Labs\Lab04\unattend-svr4.xml "$($dl):\unattend.xml"
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

## Задание 1: Создание Storage Space
### Шаг 1: Создание storage pool из шести дисков, подключенных к серверу
1. На **LON-SVR4** нажмите кнопку **Start**, запустите **Server Manager**
1. В **Server Manager** в панели слева нажмите **File and Storage Services**, затем в панели **Servers** нажмите **Storage Pools**
1. В панеле **STORAGE POOLS** нажмите **TASKS**, затем в **TASKS** выберите **New Storage Pool**
1. Нажмите кнопку **Next**
1. Введите **Name - StoragePool1**, нажмите кнопку **Next**
1. Выберите первые 6 дисков в списке **Physical disks** и нажмите кнопку **Next**
1. Нажмите кнопку **Create**
1. Подождите завершения опепации
1. Нажмите кнопку **Close**

### Шаг 2: Создание three-way mirrored virtual disk (требуется минимум 5 дисков)
1. На **LON-SVR4** в **Server Manager** на панели **Storage Pools** нажмите на **StoragePool1**
1. На панели **VIRTUAL DISKS** нажмите **TASKS** затем выберите **New Virtual Disk**
1. В диалоговом окне выберите **StoragePool1** и нажмите кнопку **OK**
1. Нажмите кнопку **Next**
1. Введите **Name - Mirrored Disk**, нажмите кнопку **Next**
1. Нажмите кнопку **Next**
1. Нажмите кнопку **Mirror**, затем нажмите кнопку **Next**
1. Выберите **Three-way mirror**, затем нажмите кнопку **Next**

> Внимание: Если опция **three-way resiliency** недоступна, переходите к следующему шагу.

1. Выберите **Thin**, затем нажмите кнопку **Next**
1. Укажите размер диск **10** Gb, затем нажмите кнопку **Next**
1. Нажмите кнопку **Create**
1. Дождитесь завершения опепации
1. Отметьте опцию **Create a volume when this wizard closes**, затем нажмите кнопку **Close**
1. Нажмите кнопку **Next**
1. На панеле **Disk** нажмите **Mirrored Disk** virtual disk, затем нажмите кнопку **Next**
1. Нажмите кнопку **Next**
1. Выберите буквк диска **H**, затем нажмите кнопку **Next**
1. Выберите файловую систему ReFS, введите **Volume label - Mirrored Volume**, затем нажмите кнопку **Next**
1. Нажмите кнопку **Create**
1. Дождитесь завершения опепации
1. Нажмите кнопку **Close**

### Шаг 3: Копирование файлов на том и проверка их видимости в File Explorer
1. На **LON-SVR4** нажмите кнопку **Start**, начните печатать `command prompt`, затем нажмите клавишу **Enter**
1. Введите следующую команду и нажмите клавишу **Enter**
    ```powershell
    Copy C:\windows\system32\write.exe H:\
    ```
1. Закройте **Command Prompt**
1. Откройте **File Explorer**
1. В **File Explorer** в навигации слева выберите **Mirrored Volume (H:)**
1. Проверьте, что файл `write.exe` виден в списке файлов
1. Закройте **File Explorer**

### Шаг 4: Отключение физического диска для симуляции аварийной ситуации
1. На машине **HOST** откройте **Hyper-V Manager**
1. В панеле **Virtual Machines** щелкните правой кнопкой мыши на **LON-SVR4**, затем нажмите кнопку **Settings**
1. В настройках **LON-SVR4** в панеле **Hardware** выберите диск **LON-SVR4-Disk1**
1. На панеле **Hard Drive** нажмите кнопку **Remove**, затем нажмите кнопку **OK**, затем нажмите кнопку **Continue**

### Шаг 5: Проверьте, что файл все еще доступен
1. Переключитесь на машину LON-SVR4
1. Откройте **File Explorer**
1. В **File Explorer** в навигации слева выберите **Mirrored Volume (H:)**
1. Проверьте, что файл `write.exe` виден в списке файлов
1. Закройте **File Explorer**
1. В **Server Manager**, в панеле **STORAGE POOLS** в меню нажмите **Refresh “Storage Pools”**

> Внимание: Обратите внимание на предупреждение рядом с **Mirrored Disk**

1. На панеле **VIRTUAL DISK** щелкните правой кнопкой мыши **Mirrored Disk**, затем нажмите кнопку **Properties**
1. В диалоговом окне **Mirrored Disk Properties** в панеле слева нажмите **Health**

> Внимание: Обратите внимание на предупреждение **Health Status**. **Operational Status** должен показывать одно из значений: **Incomplete**, **Unknown** или **Degraded**

1. Нажмите кнопку **OK**

### Шаг 6: Добавьте новый диск к storage pool и удалите сломанный диск
1. На **LON-SVR4** в Server Manager на панеле **STORAGE POOLS** в меню нажмите **Refresh “Storage Pools”**
1. На панеле **STORAGE POOLS** щелкните правой кнопкой мыши **StoragePool1**, затем нажмите кнопку **Add Physical Disk**
1. В окне **Add Physical Disk** нажмите на первый диск в списке, затем нажмите кнопку **OK**.
1. Щелкните правой кнопкой мыши на кнопку **Start**, затем нажмите кнопку **Windows PowerShell (Admin)**
1. В **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    Get-PhysicalDisk
    ```
  
1. Обратите внимание на **FriendlyName** диска, который показывает **OperationalStatus** как **Lost Communication**
1. В **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    > Замените `diskname` на имя диска из предыдущего шага
    ```powershell
    $Disk = Get-PhysicalDisk -FriendlyName 'diskname'
    ```
  
1. В **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    Remove-PhysicalDisk -PhysicalDisks $disk -StoragePoolFriendlyName StoragePool1
    ```
  
1. Введите **Y** и нажмите клавишу **Enter**:
1. В **Server Manager** на панеле **STORAGE POOLS** в меню нажмите **Refresh “Storage Pools”** чтобы увидеть, что предупреждение исчезло

## Задание 2: Включение и настройка storage tiering
### Шаг 1: Использование команды Get-PhysicalDisk для просмотра доступных физических дисков
1. На **LON-SVR4** нажмите правой кнопкой мыши на **Start**, затем нажмите **Windows PowerShell (Admin)**
1. В **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    Get-PhysicalDisk
    ```
  
### Шаг 2: Создание storage pool
1. В **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    $canpool = Get-PhysicalDisk –CanPool $true
    ```
1. В **Windows PowerShell** введите команду и нажмите клавишу **Enter**:
    ```powershell
    New-StoragePool -FriendlyName "TieredStoragePool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $canpool
    ```
1. В **Windows PowerShell** введите команды и нажмите клавишу **Enter**:
    > Этот скрипт настраивает имена дисков для последующих шагов задания
    ```powershell
    $i = 1
    $disks = Get-StoragePool -FriendlyName TieredStoragePool | Get-PhysicalDisk
    Foreach ($disk in $disks) {
      Get-PhysicalDisk -UniqueId $disk.UniqueID | Set-PhysicalDisk -NewFriendlyName ("PhysicalDisk$i")
      $i++
    }
    ```

### Шаг 3: Просмотр media types
1. На **LON-SVR4** в **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    Get-StoragePool –FriendlyName TieredStoragePool | Get-PhysicalDisk | Select FriendlyName, MediaType, Usage, BusType
    ```
  
### Шаг 4: Укажите media type для дисков и проверьте, что тип изменился
1. На **LON-SVR4** в **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    Set-PhysicalDisk –FriendlyName PhysicalDisk1 –MediaType SSD
    Set-PhysicalDisk –FriendlyName PhysicalDisk2 –MediaType HDD
    Get-PhysicalDisk | Select FriendlyName, MediaType, Usage, BusType
    ```
  
### Шаг 5: Создайте pool-level storage tiers при помощи Windows PowerShell
1. На **LON-SVR4** в **Windows PowerShell** выполните следующую команду и нажмите клавишу **Enter**:
    ```powershell
    New-StorageTier –StoragePoolFriendlyName TieredStoragePool -FriendlyName HDD_Tier –MediaType HDD

    New-StorageTier –StoragePoolFriendlyName TieredStoragePool -FriendlyName SSD_Tier –MediaType SSD
    ```
  
### Шаг 6: Создайте новый виртуальный диск с уровнями хранения с использованием New Virtual Disk Wizard
1. На **LON-SVR4** в **Server Manager** на панели **Storage Pools** нажмите кнопку **Refresh**, затем нажмите кнопку **TieredStoragePool**
1. На панели **VIRTUAL DISKS** нажмите **TASKS**, затем в списке **TASKS** выберите **New Virtual Disk**
1. Выберите **TieredStoragePool**, затем нажмите кнопку **OK**
1. Нажмите кнопку **Next**
1. Укажите **Name - TieredVirtDisk**, выберите **Create storage tiers on this virtual disk**, затем нажмите кнопку **Next**
1. Нажмите кнопку **Next**
1. В обоих списках **Layout** выберите **Simple**, затем нажмите кнопку **Next**
1. Нажмите кнопку **Next**
1. В обоих вариантах **Specify size** введите **2**, снимите опцию **Enable read cache**, затем нажмите кнопку **Next**

> Внимание: В зависимости от вашей подсистемы хранения опция Enable read cache может быть недоступна.

1. Нажмите кнопку **Create**
1. Дождитесь завершения 
1. Убедитесь, что выбрана опция **Create a volume when this wizard closes**, затем нажмите кнопку **Close**
1. Нажмите кнопку **Next**
1. На странице **Select the server and disk**, в панеле **Disk**, выберите **TieredVirtDisk**, затем нажмите кнопку **Next**
1. Нажмите кнопку Next
1. Выберите букву диска **R**, затем нажмите кнопку **Next**
1. Выберите файловую систему **ReFS**. Укажите **Volume label - Tiered Volume**, затем нажмите кнопку **Next**

> Внимание: Если ReFS недоступна, выберите NTFS.

1. Нажмите кнопку **Create**
1. Дождитесь завершения операции
1. Нажмите кнопку **Close**
1. В **Server Manager**, щелкните правой кнопкой по созданному только что диску, затем нажмите кнопку **Properties**
1. В окне **TieredVirtDisk Properties**, на закладке **General**, посмотрите на **Storage tiers**, **Capacity**, **Allocated space**, и **Used pool space**
1. Перейдите на закладку **Health**, посмотрите на детали **Storage layout**, затем нажмите кнопку **OK**


# Лабораторная работа B: Внедрение Data Deduplication - !!! Не готова !!!

## Сценарий оабораторной работы
After you have tested the storage redundancy and performance options, you decide that it also would be beneficial to maximize the available disk space that you have, especially on generic file servers. You decide to test Data Deduplication solutions to maximize storage availability for users.
New: After you have tested the storage redundancy and performance options, you now decide that it would also be beneficial to maximize the available disk space that you have, especially around virtual machine storage which is in ever increasing demand. You decide to test out Data Deduplication solutions to maximize storage availability for virtual machines.

## Подготовка
> Перед выполнением заданий вам неободимо при помощи **Disk Management** инициализировать один из доступных дисков, создать на нем том, отформатировать его при помощи **ReFS**, назначить диску букву `D`. Далее необходимо разархивировать в корень `D:\` архив `C:\labs\lab05\dfiles.zip`

## Задание 1: Установка Data Deduplication
### Шаг 1: Установка роли сервера Data Deduplication
1. On LON-SVR4, in Server Manager, in the navigation pane, click Dashboard.
2. In the details pane, click Add roles and features.
3. In the Add Roles and Features Wizard, on the Before you begin page, click Next.
4. On the Select installation type page, click Next.
5. On the Select destination server page, click Next.
6. On the Select server roles page, in the Roles list, expand File and Storage Services (4 of 12 installed). 
7. Expand File and iSCSI Services (3 of 11 installed).
8. Select the Data Deduplication check box, затем нажмите кнопку Next.
9. On the Select features page, click Next.
10. On the Confirm installation selections page, click Install. 
11. When installation is complete, on the Installation progress page, click Close.

### Шаг 2: Проверка статуса Data Deduplication
1. On LON-SVR4, switch to Windows PowerShell.
1. В **Windows PowerShell** введите команду и нажмите клавишу **Enter**:
    ```powershell
    Get-DedupVolume 
    ```
  
1. В **Windows PowerShell** введите команду и нажмите клавишу **Enter**:
    ```powershell
    Get-DedupStatus 
    ```
  
1. These commands return no results. This is because you need to enable it on the volume after installing it.

### Шаг 3: Проверка производительности виртуальной машины
1. On LON-SRV1, in the Windows PowerShell window, type the following, and then press Enter:
    ```powershell
    Measure-Command -Expression {Get-ChildItem –Path D:\ -Recurse}
    ```

> Note: You will use the values returned from the previous command later in the lab.

## Задание 2: Настройка Data Deduplication
### Шаг 1: Настройка Data Deduplication
1. On LON-SVR4, on the taskbar, click the File Explorer icon.
2. In Server Manager, in the navigation pane, click File and Storage Services, затем нажмите кнопку Disks.
3. In the Disks pane, click 1.
4. Beneath VOLUMES, click D.
5. Right-click D, затем нажмите кнопку Configure Data Deduplication.
6. In the Allfiles (D:\) Deduplication Settings dialog box, in the Data deduplication list, click General purpose file server.
7. In the Deduplicate files older than (in days) text box, type 0.
8. Click Set Deduplication Schedule.
9. In the LON-SVR4 Deduplication Schedule dialog box, select the Enable throughput optimization check box, затем нажмите кнопку OK.
10. In the Allfiles (D:\) Deduplication Settings dialog box, click Add. 
11. In the Select Folder dialog box, expand Allfiles (D:), click shares.
12. Click Select Folder, затем нажмите кнопку OK.

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

8. In Server Manager, in the navigation pane, click File and Storage Services, затем нажмите кнопку Disks.
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