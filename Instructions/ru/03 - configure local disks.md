# Модуль 2 - Настройка дисков #

Продолжительность: 50 минут

## Сценарий лабораторной работы
Ваш руководитель попросил добавить дисковое пространство на файл сервер, работающий на виртуальной машине. Этот сервер в ближашие месяцы скорее всего существенно вырастет в размере, вам необходима гибкость в вопросе выделения дискового пространства. Руководитель попросил вас оптимизировать размер коастера и сектора на дисках для хранения фалов больших размеров. Вам необходимо оценить варианты хвранения и простоту расширения для использования в будущем. 

## Цели
После выполнения заданий вы сможете: 
1. Создавать и управлять дисками.
1. Изменять размер томов.


## Подготовка к лабораторной работе
Для выполнения этой оабораторной работы вы создадите виртуальные машины при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги:
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Начните печатать **PowerShell**
1. Запустите **Windows PowerShell**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    > Этот скрипт загружает файлы, необходимые для выполнения лабораторной работы  

    ```powershell
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
    Copy-Item C:\Labs\Lab03\unattend.xml "$($dl):\unattend.xml"
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
        $net | new-NetIPAddress -IPAddress 172.16.0.28 -PrefixLength 16 -AddressFamily IPv4
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

## Задание 1: Создание и управление томами

### Сценарий задания
Вы создадите несколько томов на имеющихся дисках.

Основные шаги этого задания:
1. Создание тома и форматирование ReFS
2. Создание зеркального тома

### Шаг 1: Создание тома и форматирование ReFS
1. На виртуальной машине **LON-SVR4** запустите **Windows PowerShell (Admin)**. 
2. Создайте новый том, отформатированный **ReFS**, используя все место на **Disk 1**. Используйте следующие команды Windows PowerShell: 

    - Выведите все доступные диски, которые еще не были инициализированы:
    
        `Get-Disk | Where-Object PartitionStyle –Eq "RAW"`
    - Инициализируйте disk 2: 
    
		`Initialize-disk 2`
    - Посмотрите на таблицу разделов: 
		
        `Get-disk`
    - Создайте том с ReFS, используя все доступное место на disk 1: 
    
        `New-Partition -DiskNumber 2 -UseMaximumSize -AssignDriveLetter | Format-Volume -NewFileSystemLabel "Simple" -FileSystem ReFS`
1. Откройте проводник Windows, убедитесь, что в системе есть 2 диска, посмотрите свойства второго диска. Какая буква у второго диска?

### Шаг 2: Создание зеркального тома
1. Нажмите правой кнопкой мыши на кнопку **Пуск/Start** в Windows.
1. Выберите **Disk Management**
1. Для всех дисков со статусом **Offline**
    1. Нажмите правой кнопкой мыши и выберите **Online**
    1. Нажмите правой кнопкой мыши и выберите **Initialize Disk**
    1. Выберите опцию **GPT**
    1. Нажмите кнопку **OK**
1. Создайте зеркальный том
    1. Нажмите правой кнопкой мыши на **Disk 3** и выберите New Mirrored Volume
    1. Нажмите кнопку **Next**
    1. Выберите **Disk 4** 
    1. Нажмите кнопку **Add >**
    1. Нажмите кнопку **Next >**
    1. В выпадающем списке выберите букву **M**
    1. Нажмите кнопку **Next >**
    1. Укажите Volume label: **Mirror**
    1. Выберите опцию Perform a quick format
    1. Нажмите кнопку **Next >**
    1. Нажмите кнопку **Finish**
    1. Нажмите кнопку **Yes** в диалоговом окне
1. Проверьте наличие диска в проводнике Windows

> Результат:  После этого задания вы создали несколько томов, включая зеркальный.
 
## Задание 2: Изменение размера томов

### Сценарий
Вы создали новый том и затем поняли, что должны именить его размер. Вы решаете использовать инструмент **Diskpart.exe**. 

Основные шаги этого задания:
1. Создание простого тома и изменение его размера
2. Сжатие тома
3. Подготовка к следующему заданию

 ## Шаг 1: Создание и расширение простого тома
1. Switch to **Windows PowerShell (Admin)** and create a new drive by running the following commands:
    - Initialize **disk 5**: `Initialize-disk 5`
	- Open **diskpart**: `diskpart`
	- List available disks: `List disk`
	- Select the appropriate disk: `Select disk 5`
	- Make the disk dynamic: `Convert dynamic`
	- Create a simple volume on **Disk 5**: 
	    `Create volume simple size=10000 disk=5`
	- Assign the drive letter **Z**: `Assign letter=z`
	- Format the volume for **NTFS**: `Format`
2. In **Disk Management**, verify the presence of an **NTFS** volume on **Disk 5** of size approximately **10 GB**.
3. In the **Windows PowerShell (Admin)** window, run the following command:
	`Extend size 10000`
4. In **Disk Management**, verify the presence of an **NTFS** volume on **Disk 5** of size approximately **20 GB**.

## Шаг 2: Shrink a volume
1. In the **Windows PowerShell (Admin)** window, run the following command:
    `Shrink desired=15000`  
2. Switch to **Disk Management**. 
3. Verify the presence of an **NTFS** volume on **Disk 5** of size approximately **5 GB**.
4. Close the **Windows PowerShell (Admin)** window.

## Шаг 3: Prepare for the next exercise
1. On the host computer, start Hyper-V Manager.
2. In the Virtual Machines list, right-click LON-DC1, and then click Revert.
3. In the Revert Virtual Machine dialog box, click Revert.
4. Repeat steps 2 and 3 for LON-SVR1.
5. Restart your computer and select LON-HOST1 when prompted.
6. Sign in as Administrator with the password Pa55w.rd. 

> Results: After completing this exercise, you should have successfully resized a volume.
 
## Задание 3: Managing virtual hard disks

### Задание Scenario
You are required to create and configure virtual hard disks for use in a Windows Server 2016 server computer. The virtual hard disk is for the Sales department. You decide to use Windows PowerShell to achieve these objectives. First, you must install the Windows PowerShell Hyper-V module. 

The main tasks for this exercise are as follows:
1. Install the Hyper-V module
2. Create a virtual hard disk
3. Reconfigure the virtual hard disk
4. Prepare for the next module
 
### Шаг 1: Install the Hyper-V module
1.      On your host computer, open Server Manager and install the Hyper-V server role and management tools.
2.      Restart your computer and select 20740C-LON-HOST1 when prompted.
	      
> Note: Your computer might restart several times following installation of the Hyper-V components. 
	
3.      Sign in as Administrator with the password Pa55w.rd. 

### Шаг 2: Create a virtual hard disk
1. On your host computer, open Windows PowerShell (Admin). 
2. At the Windows PowerShell command prompt, type the following command, and then press Enter: 

	```powershell
	New-VHD -Path c:\sales.vhd -Dynamic -SizeBytes 10Gb | Mount-VHD -Passthru | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -Force
	```

> Note: If you receive a Microsoft Windows pop-up dialog box prompting you to format the disk, close it and continue.

### Шаг 3: Reconfigure the virtual hard disk

> Note: These steps are a duplicate of the detailed steps due to the complexity of the Windows PowerShell commands. 
	
1. To dismount the virtual hard disk, at the Windows PowerShell command prompt, type the following command, and then press Enter: 

    `Dismount-vhd C:\Sales.vhd`
2. To check the properties of the virtual hard disk, at the **Windows PowerShell** command prompt, type the following command, and then press **Enter**: 

    `Get-vhd C:\Sales.vhd`
    > Question: What is the physical sector size? 
4. To convert to a **.vhdx** file, at the **Windows PowerShell** command prompt, type the following command, and then press **Enter**: 
		
    `Convert-VHD –Path C:\Sales.vhd –DestinationPath c:\Sales.vhdx`
5. To change the sector size, at the **Windows PowerShell** command prompt, type the following command, and then press **Enter**: 
	
    `Set-VHD –Path c:\Sales.vhdx –PhysicalSectorSizeBytes 4096`
6. To check the properties of the **.vhdx** file, at the **Windows PowerShell** command prompt, type the following command, and then press **Enter**: 

	`Get-vhd C:\Sales.vhdx`

	> Question: What is the physical sector size? 

7. To optimize the .vhdx file, at the **Windows PowerShell** command prompt, type the following command, and then press **Enter**: 

    `Optimize-VHD –Path c:\Sales.vhdx –Mode Full`

### Шаг 4: Prepare for the next module

Restart your computer, and when prompted, choose Windows Server 2016. 


> Results: After completing this exercise, you should have successfully created and managed virtual hard disks by using Windows PowerShell.
 
## Lab Review

### Question
In the lab, you used the Diskpart.exe command-line tool to create and resize volumes. What alternate Windows PowerShell cmdlets could you have used?
### Answer
You could use some of the more common disk management cmdlets:
- Get-disk. Lists all available disks installed in the server computer. 
- Clear-disk. Removes all partitions and volumes from the specified disk. 
- Initialize-disk. Enables you to initialize a disk in readiness for creation of volumes.
- Get-volume. Lists all accessible volumes.
- Format-volume. Enables you to format a volume with NTFS. 

### Question
Your current volume runs out of disk space. You have another disk available in the same server. What actions in the Windows operating system can you perform to help you add disk space?
### Answer
Your answers can include converting the disk to a dynamic disk, and extending the volume with the second disk. You also can use the second disk as a mount point to move some large files and reassign their path. You also could use links to move large files to the new volume, and then create a link from their original location.
