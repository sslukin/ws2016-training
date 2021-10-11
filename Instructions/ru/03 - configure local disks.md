# Модуль 3 - Настройка дисков

Продолжительность: 40 минут

## Сценарий лабораторной работы
Ваш руководитель попросил добавить дисковое пространство на файл сервер, работающий на виртуальной машине. Этот сервер в ближашие месяцы скорее всего существенно вырастет в размере, вам необходима гибкость в вопросе выделения дискового пространства. Руководитель попросил вас оптимизировать размер кластера и сектора на дисках для хранения фалов больших размеров. Вам необходимо оценить варианты хранения и простоту расширения для использования в будущем. 

## Цели
После выполнения заданий вы сможете: 
1. Создавать и управлять дисками.
1. Изменять размер томов.

## Подготовка к лабораторной работе
Для выполнения этой лабораторной работы вы создадите виртуальные машины при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги:
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Начните печатать **PowerShell**
1. Запустите **Windows PowerShell**

1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**: 
     > Этот скрипт устанавливает виртуальную машину и подключает ее к домену Active Directory:  

   ```powershell
    $SwitchName = "Int"
    $dirVM = "C:\VM"
    $vm = "LON-SVR3"
    
    New-VHD -ParentPath "$dirVM\win2016base.vhdx" -Path "$dirVM\$vm.vhdx" -Differencing
    
    $d = Mount-VHD -Path "$dirVM\$vm.vhdx" -Passthru
    $dl = $d | Get-Partition | select -Last 1 -ExpandProperty DriveLetter
    Copy-Item C:\Labs\Lab03\unattend-svr3.xml "$($dl):\unattend.xml"
    $d | Dismount-VHD
    
    New-VM -Name $vm -VHDPath "$dirVM\$vm.vhdx" -Generation 2 -SwitchName $SwitchName
    Set-VM -Name $vm -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 2GB
    1..10 | % { 
        $path = "$dirVM\lon-svr3-disk$_.vhdx"
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
        $net | new-NetIPAddress -IPAddress 172.16.0.23 -PrefixLength 16 -AddressFamily IPv4
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
1. Создание зеркального тома
1. Создание тома с чередованием
 
### Шаг 1: Создание тома и форматирование ReFS
1. На виртуальной машине **LON-SVR3** запустите **Windows PowerShell (Admin)**. 
1. Создайте новый том, отформатированный **ReFS**, используя все место на **Disk 1**. Используйте следующие команды Windows PowerShell: 

    - Выведите все доступные диски, которые еще не были инициализированы:
    
        ```powershell
		Get-Disk | Where-Object PartitionStyle –Eq "RAW"
		```
    - Инициализируйте **disk 2**: 
    
		```powershell
		Initialize-disk 2
		```
    - Посмотрите на таблицу разделов: 
		
        ```powershell
        Get-disk
        ```
    - Создайте том с **ReFS**, используя все доступное место на **disk 1**: 
    
        ```powershell
        New-Partition -DiskNumber 2 -UseMaximumSize -AssignDriveLetter | Format-Volume -NewFileSystemLabel "Simple" -FileSystem ReFS
        ```
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
    1. Нажмите правой кнопкой мыши на **Disk 3** и выберите **New Mirrored Volume**
    1. Нажмите кнопку **Next**
    1. Выберите **Disk 4** 
    1. Нажмите кнопку **Add >**
    1. Нажмите кнопку **Next >**
    1. В выпадающем списке выберите букву **M**
    1. Нажмите кнопку **Next >**
    1. Укажите Volume label: **Mirror**
    1. Выберите опцию **Perform a quick format**
    1. Нажмите кнопку **Next >**
    1. Нажмите кнопку **Finish**
    1. Нажмите кнопку **Yes** в диалоговом окне
1. Проверьте наличие диска **M** в проводнике Windows

### Шаг 3: Создание тома с чередованием
1. Откройте утилиту **Disk Management**
1. Создайте том с чередованием
    1. Нажмите правой кнопкой мыши на **Disk 6** и выберите **New Striped Volume**
    1. Нажмите кнопку **Next**
    1. Выберите **Disk 7** 
    1. Нажмите кнопку **Add >**
    1. Нажмите кнопку **Next >**
    1. В выпадающем списке выберите букву **S**
    1. Нажмите кнопку **Next >**
    1. Укажите Volume label: **Striped**
    1. Выберите опцию **Perform a quick format**
    1. Нажмите кнопку **Next >**
    1. Нажмите кнопку **Finish**
    1. Нажмите кнопку **Yes** в диалоговом окне
1. Проверьте наличие диска **S** в проводнике Windows размером примерно **64Gb**

> Результат:  После этого задания вы создали несколько томов с различными характеристиками.
 
## Задание 2: Изменение размера томов

### Сценарий
Вы создали новый том и затем поняли, что должны именить его размер. Вы решаете использовать инструмент **Diskpart.exe**. 

Основные шаги этого задания:
1. Создание простого тома и изменение его размера
2. Сжатие тома
3. Подготовка к следующему заданию

 ## Шаг 1: Создание и расширение простого тома
1. Переключитесь на **Windows PowerShell (Admin)** и создайте новый диск, выполнив следующие команды:
    - Инициализация **диска 5**: `Initialize-disk 5`
	- Запустите утилиту **diskpart**: `diskpart`
	- Перечислите диски: `List disk`
	- Выберите диск: `Select disk 5`
	- Конвертируйте диск в динамический: `Convert dynamic`
	- Создайте простой том на **диске 5**: 
	    `Create volume simple size=10000 disk=5`
	- Назначьте букву диска **Z**: `Assign letter=z`
	- Отворматируйте лиск с файловой системой **NTFS**: `Format`
1. Щелкните правой кнопкой мыши на кнопку Windows **Start/Пуск**
1. Выберите **Disk Management**
1. Проверьте наличие раздела с **NTFS** на томе **Disk 5** размером примерно **10 GB**.
1. Вернитесь в окно **Windows PowerShell (Admin)** и выполните команду:
	`Extend size 10000`
1. Переключитесь на утилиту **Disk Management**
1. Проверьте наличие раздела с **NTFS** на томе **Disk 5** размером примерно **20 GB**.

## Шаг 2: Сожмите том
1. В окне **Windows PowerShell (Admin)** выполните команду:
    `Shrink desired=15000`  
2. Переключитесь на утилиту **Disk Management**
3. Проверьте наличие раздела с **NTFS** на томе **Disk 5** размером примерно **5 GB**.
4. Закройте окно **Windows PowerShell (Admin)**.

> Результат:  После этого задания вы познакомились с утилитами diskpart и Disk Management для управления дисками.
 