# Модуль 2 - Установка Windows Server 2016 #

Продолжительность: 60 минут

## Сценарий лабораторной работы
Ваш ИТ отдел в Adatum Corporation только что приобрели серверы без операционной системы (ОС). Ваша команда решила установить Windows Server 2016 Datacenter в режиме Server Core для тестирования возможностей Server Core, а также сервер с графическим интерфейсом. Ваша задача заключается в установке ОС и последующей настройке серверов. Вы назовете их **LON-SVR1** и **LON-SVR2**, присвоите статический IP адрес **172.16.0.21** и **172.16.0.22**, присоедините к домену **Adatum.com**.
  
> Все данные можно вставлять в виртуальную машину путем копирования в буфер обмена, а затем вставкой через меню **Clipboard &#8594; Type clipboard text**.  
При вводе пароля в консоль Server Core, он не отображается и не вставляется через буфер обмена.


## Цели
После выполнения заданий вы сможете: 
1. Устанавливать Server Core для Windows Server 2016.
1. Настраивать Server with Desktop Experience.

## Задание 1: Установка Server Core

### Сценарий задания
Вы решили, что Server Core является лучшим вариантом и пробуете его установку.
Основные шаги этого задания:
1. Установка Windows Server 2016 Datacenter на LON-SVR1

### Шаг 1: Установка Windows Server 2016 Datacenter Core
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Начните печатать **PowerShell**
1. Запустите **Windows PowerShell**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    > Этот скрипт создает виртуальную машину, диск, добавляет к машине DVD диск с образом Windows Server 2016, устанавливает последовательность загрузки начиная с DVD, запускает и подключается к виртуальной машине.

    ```powershell
    $SwitchName = "Int"
    $dirVM = "C:\VM"
    $vm = "LON-SVR1"
    New-VHD -Path "$dirVM\$vm.vhdx" -Dynamic -SizeBytes 30GB
    New-VM -Name $vm -VHDPath "$dirVM\$vm.vhdx" -Generation 2 -SwitchName $SwitchName
    Set-VM -Name $vm -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 2GB
    $dvd = Add-VMDvdDrive -VMName $vm -Path (Get-ChildItem C:\iso | select -First 1).fullname -Passthru
    Set-VMFirmware -VMName $vm -BootOrder $dvd, (Get-VMHardDiskDrive -VMName $vm)
    Start-VM -Name $vm
    vmconnect localhost $vm
    ```
1. В появившемся окне быстро нажмите кливишу **Enter** для загрузки с DVD диска
    > Если не успели, выберите в меню **Action &#8594; CTRL+ALT+DEL** и снова нажмите **Enter**
1. После запуска установки Windows на **LON-SVR1**, нажмите кнопку **Next**
1. Нажмите кнопку **Install now**
1. Подождите примерно 1 минуту
1. Используйте ключ продукта:  
    **CB7KF-BWN84-R7R2Y-793K2-8XDDG**  
      
    > Что это за ключ?  
    https://docs.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys
1. Нажмите кнопку **Next**
1. Оставьте выбор первого варианта - **Windows Server 2016 Datacenter**
1. Нажмите кнопку **Next**
1. Отметьте опцию **I accept the icense terms**
1. Нажмите кнопку **Next**
1. Выберите вариант **Custom: Install Windows only (advanced)**
1. Нажмите кнопку **Next**
1. Подождите примерно 5 минут
    > Если после перезагрузки ОС окно пустое, закойте его. В **Hyper-V Manager** дважды щелкните на виртуальной машине **LON-SVR1**, чтобы открыть окно подключения
1. Нажмите клавишу **Enter**
1. Введите пароль **Pa55w.rd**
1. Нажмите клавишу **Tab** и еще раз введите **Pa55w.rd**
1. Нажмите клавишу **Enter** после появления сообщения о смене пароля

> Результат: Вы успешно установили ОС  Windows Server 2016 Core на **LON-SVR1**.
 
## Задание 2: Завершение установки Windows Server 2016 Core

### Сценарий задания
Теперь необходимо навершить установку Server Core через настройки и присоединение к домену **Adatum.com**.

Основные шаги этого задания:
1. Использование PowerShell и Sconfig.cmd для настройки Server Core
1. Изменение сетевых настроек
1. Подключение к домену

### Шаг 1: Используйте Windows PowerShell и Sconfig.cmd для настройки Server Core
1. Наберите `PowerShell` и нажмите клавишу **Enter**.
2. Выполните следующие команды для отображения имени компьютера и информации об IP адресах
     ```powershell
     $env:computername
     Get-NetIPAddress
    ``` 

    > Обратите внимание на случайно сгенерированное имя компьютера и автоматически присвоенные адреса 169.254.X.X  
    Что это за адреса?  
    https://ru.wikipedia.org/wiki/Link-local_address

### Шаг 2: Изменение параметров сетевого адаптера
1. Наберите `Sconfig.cmd` и нажмите клавишу **Enter**.
1. Нажмите 8
1. Нажмите 1
1. Нажмите 1
1. Нажмите S
1. Укажите адрес: **172.16.0.21**
1. Укажите маску сети: **255.255.0.0**
1. Укажите шлюз: **172.16.0.1**
1. Нажмите 2
1. Укажите сервер: **172.16.0.1**
1. Нажмите кнопку **OK**
1. Нажмите **Enter**
1. Нажмите 4

### Шаг 3: Присоединение к домену
1. Нажмите 1
1. Нажмите D
1. Укажите домен: **Adatum.com**
1. Укажите логин: **Adatum\administrator** 
1. Введите пароль: **Pa55w.rd**
1. Нажмите кнопку **Yes**
1. Укажите имя компьютера: **LON-SVR1**
1. Укажите логин: **Adatum\administrator** 
1. Введите пароль: **Pa55w.rd**
1. Нажмите кнопку **Yes**
1. Закройте окно виртуальной машины
1. Откройте подключение к виртуальной машине снова
1. Введите пароль **Pa55w.rd**
1. Наберите `Sconfig.cmd` и нажмите клавишу **Enter**.
1. Проверьте, что  имя компьютера и домена изменились.

### Шаг 4: Завершение работы
1. Остановите виртуальную машину, для этого выберите в меню **Action &#8594; Shut down**, нажмите кнопку **Shut down**
1. Закройте окно виртуальной машины.

> Результаты: После выполнения задания вы изменили сетевые настройки, имя компьютера и подключили его к домену.

## Задание 3: Установка Server with Desktop Experience

### Сценарий задания
Вы решили, что Server with Desktop Experience является необходимым вариантом для ряда задач и пробуете его установку.
Основные шаги этого задания:
1. Установка Windows Server 2016 Datacenter на LON-SVR2

### Шаг 1: Установка Windows Server 2016 Datacenter
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Начните печатать **PowerShell**
1. Запустите **Windows PowerShell**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    > Этот скрипт создает виртуальную машину, диск, добавляет к машине DVD диск с образом Windows Server 2016, устанавливает последовательность загрузки начиная с DVD, запускает и подключается к виртуальной машине.

    ```powershell
    $SwitchName = "Int"
    $dirVM = "C:\VM"
    $vm = "LON-SVR2"
    New-VHD -Path "$dirVM\$vm.vhdx" -Dynamic -SizeBytes 30GB
    New-VM -Name $vm -VHDPath "$dirVM\$vm.vhdx" -Generation 2 -SwitchName $SwitchName
    Set-VM -Name $vm -ProcessorCount 4 -StaticMemory -MemoryStartupBytes 2GB
    $dvd = Add-VMDvdDrive -VMName $vm -Path (Get-ChildItem C:\iso | select -First 1).fullname -Passthru
    Set-VMFirmware -VMName $vm -BootOrder $dvd, (Get-VMHardDiskDrive -VMName $vm)
    Start-VM -Name $vm
    vmconnect localhost $vm
    ```
1. В появившемся окне быстро нажмите кливишу **Enter** для загрузки с DVD диска
    > Если не успели, выберите в меню **Action &#8594; CTRL+ALT+DEL** и снова нажмите **Enter**
1. После запуска установки Windows на **LON-SVR2**, нажмите кнопку **Next**
1. Нажмите кнопку **Install now**
1. Подождите примерно 1 минуту
1. Используйте ключ продукта:  
    **CB7KF-BWN84-R7R2Y-793K2-8XDDG**  
      
    > Что это за ключ?  
    https://docs.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys
1. Нажмите кнопку **Next**
1. Выберите **Windows Server 2016 Datacenter (Desktop Experience)**
1. Нажмите кнопку **Next**
1. Отметьте опцию **I accept the icense terms**
1. Нажмите кнопку **Next**
1. Выберите вариант **Custom: Install Windows only (advanced)**
1. Нажмите кнопку **Next**
1. Подождите примерно 5 минут
1. Введите пароль **Pa55w.rd** 2 раза и нажмите кнопку **Finish**
1. В меню выберите **Action &#8594; CTRL+ALT+DEL**
1. Введите пароль **Pa55w.rd** и нажмите клавишу **Enter**

> Результат: Вы успешно установили ОС  Windows Server 2016 на **LON-SVR2**.
 
## Задание 4: Завершение установки Windows Server 2016

### Сценарий задания
Теперь необходимо навершить установку через настройки и присоединение к домену **Adatum.com**.

Основные шаги этого задания:
1. Изменение сетевых настроек
1. Подключение к домену

### Шаг 1: 
1. Дождитесь появления окна **Server manager**
1. Слева выберите **Local Server**
1. Справа от пункта **Ethernet** надмите **IPv4 adress assigned by DHCP, IPv6 enabled**
1. Дважды щелкните по адаптеру **Ethernet**
1. Нажмите кнопку **Properties**
1. Дважды щелкните по **Internet Protocol Version 4 (TCP/IPv4)**
1. Выберите опцию **Use the following IP address**
1. Укажите IP address: **172.16.0.22**
1. Укажите **Subnet mask**: **255.255.0.0**
1. Укажите **Deafult gateway**: **172.16.0.1**
1. Укажите Preferred DNS server: **172.16.0.1**
1. Нажмите кнопки **OK** или **Close** во всех диалоговых окнах
1. > Нажмите **Yes** в синей панели справа, если появится
1. Закройте окно **Network Connections**

### Шаг 2: Присоединение к домену
1. Вернитесь к окну **Server manager**
1. Нажмите на имя **Win-...** напротив **Computer name** 
1. Нажмите кнопку **Change**
1. Укажите имя компьютера: **LON-SVR2**
1. Выберите опцию **Member of: Domain**
1. Укажите домен: **Adatum.com**
1. Нажмите кнопку **OK**
1. 
1. Укажите логин: **Adatum\administrator** 
1. Введите пароль: **Pa55w.rd**
1. Нажмите кнопку **OK**
1. Нажмите кнопку **OK** в появившемся окне
1. Нажмите кнопку **OK**
1. Нажмите кнопку **Close**
1. Нажмите кнопку **Restart Now**
1. Дождитесь перезагрузки
1. Выберите в меню **Action &#8594; CTRL+ALT+DEL** 
1. В левом нижнем углу выберите **Other user**
1. Укажите логин: **Adatum\administrator** 
1. Введите пароль: **Pa55w.rd**
1. Дождитесь появления окна **Server manager**
1. Слева выберите **Local Server**
1. Обратите внимание на имя компьютера, домен и IP адрес

### Шаг 3: Завершение работы
1. Остановите виртуальную машину, для этого выберите в меню **Action &#8594; Shut down**, нажмите кнопку **Shut down**
1. Закройте окно виртуальной машины.

> Результаты: После выполнения задания вы изменили сетевые настройки, имя компьютера и подключили его к домену.