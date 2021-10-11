# Модуль 3 - Подключение дисков по сети и сетевые папки

Продолжительность: 40 минут

## Задание 1: Настройка хранилища iSCSI

## Сценарий лабораторной работы
Вым необходимо развернуть хранилище с высокой доступностью на iSCSI с использованием MPIO. Имеется 2 независимых сетевых пути между файловым сервером и iSCSI target. Вы настроите MPIO для использования обоих путей с избыточностью на сетевом уровне.

Основные шаги этого задания:
1. Установка компонента iSCSI target
2. Создание и настройка iSCSI target
3. Настройка MPIO
4. Соединение с iSCSI target
5. Инициализация дисков iSCSI

# Шаг 1: Install the iSCSI target feature
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

# Шаг 2: Создание и настройка iSCSI target
1. В **Server Manager**, в **File and Storage Services**, выберите **iSCSI**.
1. В правом верхнем углу нажмите Tasks
1. Выберите **New iSCSI Virtual Disk**
1. Выберите диск M
1. Укажите **Name**: **iSCSIDisk1**
1. Нажмите кнопку **Next >**
1. Укажите **Disk size**: **5 GB**
1. Нажмите кнопку **Next >** 2 раза
1. Укажите **Name**: **New**
1. Нажмите кнопку **Next >**
    - iSCSI target: 
    - Target name: LON‑DC1
    - Access servers: 10.100.100.3,10.200.100.3
1. Create a second iSCSI virtual disk with the following settings:
    - Name: iSCSIDisk2
    - Disk size: 5 GB
    - iSCSI target: LON‑DC1

# Шаг 3: Configure MPIO
1. On LON-SVR1, in Server Manager, add the Multipath I/O feature.
2. After installation is complete, restart LON-SVR1, and then sign in as Adatum\Administrator with the password Pa55w.rd.
3. In Server Manager, on the Tools menu, open iSCSI Initiator.
4. In the iSCSI Initiator, perform a quick connect to the target 10.100.100.2.
5. In Server Manager, on the Tools menu, open MPIO.
6. In MPIO Properties, on the Discover Multi-Paths tab, add support for iSCSI devices, and then restart when prompted.
7. After restarting, sign in as Adatum\Administrator with the password Pa55w.rd.
8. In Server Manager, open MPIO, and then verify that MSFT2005iSCSIBusType_0x9 is listed as a device.

# Шаг 4: Connect to the iSCSI target
1. On LON-SVR1, in Server Manager, on the Tools menu, open iSCSI Initiator.
2. On the Targets tab, disconnect from all sessions.
3. Connect again, select the following options, and then enter the Advanced settings:
    - Enable multi-path
    - Add this connection to the list of Favorite Targets.
4. In the Advanced Settings dialog box, select the following settings:
    - Local adapter: Microsoft iSCSI Initiator
    - Initiator IP: 10.100.100.3
    - Target Portal IP: 10.100.100.2 / 3260
5. Connect a second time, select the following options, and then enter the Advanced settings:
    - Enable multi-path
    - Add this connection to the list of Favorite Targets.
6. In the Advanced Settings dialog box, select the following settings:
    - Local adapter: Microsoft iSCSI Initiator
    - Initiator IP: 10.200.100.3
    - Target Portal IP: 10.200.100.2 / 3260
7. On the Volumes and Devices tab, select the Auto Configure option.
8. On the Targets tab, select the iqn.1991-05.com.microsoft:lon-dc1-lon-dc1-target target, and then view the Devices.
9. For MPIO, verify that:
    - Load balance policy: Round Robin
    - The path details match the IP addresses you configure for source and destination addresses

# Шаг 5: Initialize the iSCSI disks
1. On LON-SVR1, in Server Manager, in File and Storage Services, browse to Disks.
2. Select an offline disk with a bus type of iSCSI, and then bring it online.
3. Right-click that disk, and then create a new volume with the following properties:
    - GPT disk
    - Drive letter: J
    - Volume label: SMBShares
    - Other settings: default
4. Select an offline disk with a bus type of iSCSI, and then bring it online.
5. Right-click that disk, and then create a new volume with the following properties:
    - GPT disk
    - Drive letter: K
    - File system: NTFS
    - Volume label: NFSShares
    - Other settings: default
6. Use File Explorer to verify that SMBShares and NFSShares are available in This PC.

> Результат: После выполнения этого задания вы успешно настроили iSCSI target с использованием MPIO для избыточности.
 

