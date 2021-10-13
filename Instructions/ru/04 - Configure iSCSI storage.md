# Модуль 4 - Подключение дисков по сети и сетевые папки

Продолжительность: 90 минут

## Подготовка к лабораторной работе
Для выполнения лабораторных работ вы создадите виртуальные сети для имеющихся машин при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги:
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
     > Этот скрипт создает виртуальные сети:  

   ```powershell
    powershell.exe -ExecutionPolicy Bypass -File "C:\Labs\Lab04\Prepare-Lab.ps1"
    ```
1. Подождите примерно 5 минут. 


## Задание 1: Настройка хранилища iSCSI

### Сценарий лабораторной работы
Вым необходимо развернуть хранилище с высокой доступностью на iSCSI с использованием MPIO. Имеется 2 независимых сетевых пути между файловым сервером и iSCSI target. Вы настроите MPIO для использования обоих путей с избыточностью на сетевом уровне.

Основные шаги этого задания:
1. Установка компонента iSCSI target
2. Создание и настройка iSCSI target
3. Настройка MPIO
4. Соединение с iSCSI target
5. Инициализация дисков iSCSI

### Шаг 1: Установка компонента iSCSI target
1. Зайдите на виртуальную машину **LON-SVR3**
1. Нажмите кнопку **Пуск**
1. Запустите **Server Manager**
1. Нажмите **Add roles and features** в центре экрана
1. Нажмите кнопку **Next >** 3 раза
1. Разверните узел **File and Storage Services**
1. Разверните узел **File and iSCSI Services**
1. Выберите опцию **iSCSI Target Server**
1. Нажмите кнопку **Add Features**
1. Нажмите кнопку **Next >** 2 раза
1. Нажмите кнопку **Install**
1. Дождитесь окончания установки (примерно 1 минуту)
1. Нажмите кнопку **Close**

### Шаг 2: Создание и настройка iSCSI target
1. В **Server Manager**, в **File and Storage Services**, выберите **iSCSI**.
1. В правом верхнем углу нажмите Tasks
1. Выберите **New iSCSI Virtual Disk**
1. Выберите диск M
1. Укажите **Name**: **iSCSIDisk1**
1. Нажмите кнопку **Next >**
1. Укажите **Disk size**: **5 GB**
1. Нажмите кнопку **Next >** 2 раза
1. Укажите **Name**: **LON-SVR3**
1. Нажмите кнопку **Next >**
1. Нажмите кнопку **Add...**
1. Выберите опцию **Enter a value for the selected type**
1. В списке **Type** выберите **IP Address**
1. Укажите **10.100.100.2**
1. Добавьте еще один адрес **10.200.100.2**
1. Нажмите кнопку **OK**
1. Нажмите кнопку **Next >** 2 раза
1. Нажмите кнопку **Create**
1. Нажмите кнопку **Close**
1. Создайте еще один диск с именем **iSCSIDisk2**
	
### Шаг 3: Настройка MPIO
1. На сервере **LON-SVR2**, нажмите кнопку **Start**, затем откройте **Server Manager**
1. Нажмите **Add roles and features** в центре экрана
1. Нажмите кнопку **Next >** 4 раза
1. Выберите опцию **Multipath I/O**
1. Нажмите кнопку **Next >**
1. Нажмите кнопку **Install**
1. Дождитесь окончания установки (примерно 1 минуту)
1. Нажмите кнопку **Close**
1. Перезагрузите сервер **LON-SVR2**
    - Нажмите кнопку **Start**, затем значок питания, и выберите **Restart**
1. Войдите на сервер **LON-SVR2**, используя **Adatum\Administrator** и пароль **Pa55w.rd**
1. Нажмите кнопку **Start**, затем откройте **Server Manager**


1. В **Server Manager** в меню выберите **Tools** и затем **iSCSI Initiator**
1. В окне нажмите кнопку **Yes**
1. Введите **10.100.100.3** и нажмите кнопку **Quick Connect**
1. В окне **Quick Connect** нажмите кнопку **Done**
1. Закройте окно
1. В **Server Manager** в меню выберите **Tools** и затем **MPIO**
1. Перейдите на закладку **Discover Multi-Paths**
1. Выберите опцию **Add support for iSCSI devices**
1. Нажмите кнопку **Add**
1. Должно появиться предложение перезагрузить сервер
1. Перезагрузите сервер **LON-SVR2**.
1. Войдите на сервер **LON-SVR2**, используя **Adatum\Administrator** и пароль **Pa55w.rd**
1. Нажмите кнопку **Start**, затем откройте **Server Manager**
1. В **Server Manager** в меню выберите **Tools** и затем **MPIO**
1. Обратите внимание на **Device Hardware Id - MSFT2005iSCSIBusType_0x9** в списке
1. Закройте окно
	
### Шаг 4: Подключение к iSCSI target
1. В **Server Manager** в меню выберите **Tools** и затем **iSCSI Initiator**
2. Нажмите кнопку **Disconnect**
1. Нажмите кнопку **Yes**
1. Нажмите кнопку **Connect**
1. Выберите опцию **Enable multi-path**
1. Нажмите кнопку **Advanced**
1. Выберите **Local adapter from Default - Microsoft iSCSI Initiator**
1. Выберите **Initiator - IP 10.100.100.2**
1. Выберите **Target portal IP - 10.100.100.3 / 3260**
1. Нажмите кнопку **OK** 2 раза

1. Нажмите кнопку **Connect**
1. Выберите опцию **Enable multi-path**
1. Нажмите кнопку **Advanced**
1. Выберите **Local adapter from Default - Microsoft iSCSI Initiator**
1. Выберите **Initiator - IP 10.200.100.2**
1. Выберите **Target portal IP - 10.200.100.3 / 3260**
1. Нажмите кнопку **OK** 2 раза

1. Перейдите на закладку **Volumes and Devices**
1. Нажмите кнопку **Auto Configure**
1. Перейдите на закладку **Targets**
1. Нажмите кнопку **Properties...**
1. Нажмите кнопку **MCS...**
1. Убедитесь, что выбрана окция **Round Robin**
1. Закройте все окна
	
### Шаг 5: Инициализация дисков iSCSI
1. В **Server Manager** выберите слева **File and Storage Services** и затем **Disks**
1. Нажмите правой кнопкой мыши на первом диске со статусом **Offline**
1. Выберите **Bring online**
1. Нажмите кнопку **Yes**
1. Нажмите правой кнопкой мыши на том же диске
1. Выберите **New Volume**
1. Нажмите кнопку **Next >** 2 раза
1. Нажмите кнопку **OK**
1. Нажмите кнопку **Next >** 
1. Выберите букву диска **J**
1. Укажите **Volume label - SMBShares**
1. Нажмите кнопку **Next >** 
1. Нажмите кнопку **Create** 
1. Нажмите кнопку **Close** 


1.   In Server Manager, in the right pane, right-click the remaining offline disk with a bus type of iSCSI, and then click Bring Online.
14.   In the Bring Disk Online dialog box, to bring the disk online, click Yes.
15.   Right-click the iSCSI disk that you brought online, and then click New Volume.
16.   In the New Volume Wizard, on the Before you begin page, click Next.
17.   On the Select the server and disk page, ensure that your iSCSI disk is selected, and then click Next.
18.   In the Offline or Uninitialized Disk dialog box, to initialize the disk as a GPT disk, click OK.
19.   On the Specify the size of the volume page, click Next to accept the default of using the entire disk size for the volume.
20.   On the Assign to a drive letter or folder page, in the Drive letter list, select K, and then click Next.
21.   On the Select file system settings page, in the File system box, select NTFS.
22.   In the Volume label text box, type NFSShares, and then click Next.
23.   On the Confirm selections page, to finish creating the volume, click Create.
24.   After the volume is created, on the Completion page, click Close.
25.   On the taskbar, click File Explorer, browse to This PC, and then verify that the SMBShares and NFSShares volumes are displayed.
	
## Задание 3: Настройка инфраструктуры сетевых папок

### Шаг 1: Установка ролей **File server** и **Server for NFS**
1. Зайдите на виртуальную машину **LON-SVR2**
1. Нажмите кнопку **Пуск**
1. Запустите **Server Manager**
1. Нажмите **Add roles and features** в центре экрана
1. Нажмите кнопку **Next >** 3 раза
1. Разверните узел **File and Storage Services**
1. Разверните узел **File and iSCSI Services**
1. Выберите опции **File server** и **Server for NFS**
1. Нажмите кнопку **Add Features**
1. Нажмите кнопку **Next >** 2 раза
1. Нажмите кнопку **Install**
1. Дождитесь окончания установки (примерно 1 минуту)
1. Нажмите кнопку **Close**

### Шаг 2: Создание SMB share на основе хранилища iSCSI
1. На **LON-SVR2** в **Server Manager** в меню слева выберите **File and Storage Services** и затем **Shares**
1. В **SHARES** нажмите **TASKS** и выберите **New Share**
1. В **New Share Wizard** на странице **Select the profile** в **File share profile** нажмите **SMB Share – Quick** и затем **Next**
1. On the Select the server and path for this share page, select LON-SVR2, click Select by volume, click J:, and then click Next.
1. On the Specify share name page, in the Share name box, type Data, and then click Next.
1. On the Configure share settings page, select the Enable access-based enumeration check box, and then click Next.
1. On the Specify permissions to control access page, click Customize permissions.
1. In the Advanced Security Settings for Data window, on the Permissions tab, click Add.
1. In the Permission Entry for Data window, click Select a principal, type Domain Users, and then click OK.
1.   In the Basic permissions area, select the Modify check box, and then click OK.
1.   In the Advanced Security Settings for Data window, click OK.
1.   On the Specify permissions to control access page, click Next.
1.   On the Confirm selections page, click Create.
1.   When the creation of the share is complete, click Close.
	
### Шаг 3: Создание NFS share на основе хранилища iSCSI
1. On LON-SVR2, in the SHARES area, click TASKS, and then click New Share.
2. In the New Share Wizard, on the Select the profile for this share page, in the File share profile box, click NFS Share – Quick, and then click Next.
3. On the Select the server and path for this share page, click LON-SVR2, click Select by volume, click K:, and then click Next.
4. On the Specify share name page, in the Share name box, type LinuxData, and then click Next.
5. On the Specify authentication methods page, select Kerberos v5 authentication(Krb5), and then click Next.
6. On the Specify the share permissions page, click Add.
7. In the Add Permissions window, click All Machines.
8. In the Share permissions box, select Read / Write, and then click Add.
9. On the Specify the share permissions page, click Next.
10. On the Specify permissions to control access page, click Next.
11. On the Confirm selections page, click Create.
12. On the View results page, click Close.
	
### Шаг 4: Использование Windows PowerShell для просмотра информации об общих папках
1. На **LON-DC1** откройте **File Explorer**
2. В адресной строке **File Explorer** введите `\\LON-SVR2\Data` и нажмите **Enter**
3. Создайте новый текстовый файл и переименуйте его в `NewFile.txt`
5. Откройте `NewFile.txt` в **Notepad**
6. Оставьте **Notepad** открытым
7. На **LON-SVR2** запустите **Windows PowerShell (Admin)**
8. На **LON-SVR2** в **Windows PowerShell** введите следующие команды и нажмите **Enter**:
    ```powershell
    Get-NfsShare
    Get-NfsShare LinuxData | FL *
    Get-SmbShare
    Get-SmbShare Data | FL *
    Get-SmbSession
    Get-SMBSession -ClientUserName Adatum\Administrator | FL *
    Get-SmbOpenFile
    ```

> Внимание: Отображаются 2 строки для **Adatum\Administrator**. Они создаются программами **File Explorer** и **Notepad**. Если `NewFile.txt` не виден, то только потому, что запись проявляется короткое время при сохранении. Если вы не видите 2 записи, то на **LON-DC1** закройте **Notepad** и откройте `NewFile.txt`. Затем на **LON-SVR2** выполните те же **PowerShell** команды.
	
### Шаг 5: Отключение устаревшей версии протокола SMB1
1. На **LON-SVR2** в **Windows PowerShell** введите следующую команду и нажмите **Enter**:
    ```powershell
    Set-SmbServerConfiguration -AuditSmb1Access $true
    ```    
2. Укажите **Y** для подтверждения и затем нажмите **Enter**
3. Введите следующую команду и нажмите Enter:
    ```powershell
    Get-SmbServerConfiguration | FL enable*
    ```    
4. Введите следующую команду и нажмите **Enter**:
    ```powershell
    Set-SmbServerConfiguration -EnableSMB1Protocol $false
    ```    
5. Укажите **Y** для подтверждения и затем нажмите **Enter**
6. Введите следующую команду и нажмите **Enter**:
    ```powershell
    Get-WindowsFeature *SMB*
    ```    
7. Введите следующую команду и нажмите **Enter**:
    ```powershell
    Remove-WindowsFeature FS-SMB1
    ```    
8. Закройте **Windows PowerShell**
	

> Результат: Вы создали 2 диска на удаленном сервере, подключили их через 2 разные сети к другому серверу c MPIO, а затем создали общие сетевые папки, используя протоколы SMB, NFS. В конце вы отключили старую уязвимую версию протокола SMB1.