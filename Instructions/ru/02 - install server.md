# Модуль 2 - Установка Windows Server 2016 #

Продолжительность: 90 минут

## Сценарий лабораторной работы
Ваш ИТ отдел в Adatum Corporation только что приобрел сервер без операционной системы (ОС). Ваша команда решила установить Windows Server 2016 Datacenter в режиме Server Core для тестирования возможностей Server Core. Ваша задача заключается в установке ОС и последующей настройке сервера. Вы назовете его **LON-SVR1**, присвоите статический IP адрес **172.16.0.26**, присоедините к домену **Adatum.com**.

## Цели
После выполнения заданий вы сможете: 
1. Устанавливать Server Core для Windows Server 2016.
1. Настраивать Server Core.

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
    > Этот скрипт отключает обновления Windows, которые могут периодически высплывать в системе, мешая выполнению заданий:  

    ```powershell
    Stop-Service wuauserv
    Set-Service wuauserv –startup disabled
    ```  

1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**: 
     > Этот скрипт устанавливает виртуальную машину с контроллером домена Active Directory:  

   ```powershell
    powershell.exe -ExecutionPolicy Bypass -File "C:\Labs\Lab02\Prepare-Lab02.ps1"
    ```
1. Подождите примерно 20-30 минут до появления сообщения **Setup completed**, не закрывайте окно. 
1. Пока идет автоматизированныя установка, ознакомьтесь с содержанием скрипта **C:\Labs\Lab02\Prepare-Lab02.ps1**
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Найдите и запустите программу **Hyper-V manager**
1. На виртуальной машине **LON-DC1** нажмите правой кнопкой мыши и выберите **Connect**
1. Подождите, пока в окне не появится преддожение ввести логин/пароль.
1. В появившемся окне в меню выберите **Action &#8594; CTRL+ALT+DEL**
1. Введите следующие данные:
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**

## Задание 1: Установка Server Core

### Сценарий задания
Вы решили, что Server Core является лучшим вариантом и пробуете его установку.
Основные шаги этого задания:
1. Установка Windows Server 2016 Datacenter на LON-SVR1

### Шаг 1: Установка Windows Server 2016 Datacenter на LON-SVR1
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
1. После запуска установки Windows на **LON-SVR1**, нажмите кнопку **Next**
1. Нажмите кнопку **Install now**
1. Подождите примерно 1 минуту
1. Используйте ключ продукта:  
    **CB7KF-BWN84-R7R2Y-793K2-8XDDG**  
      
    > Что это за ключ?  
    https://docs.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys
1. Нажмите кнопку **Next**
1. Оставьте выбор первого варианта
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
1. 
1. install **Windows Server 2016 Core** by using the **Windows Server 2016 Datacenter** option.

> Результат: Вы успешно установили ОС  Windows Server 2016 Core на **LON-SVR1**.
 
## Задание 2: Завершение установки Windows Server 2016 Core

### Сценарий задания
Теперь необходимо навершить установку Server Core через настройки и присоединение к домену **Adatum.com**.

Основные шаги этого задания:
1. Использование PowerShell и Sconfig.cmd для настройки Server Core
1. Изменение сетевых настроек
1. Подключение в домену

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
1. Укажите адрес: **172.16.0.27**
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
1. Закройте окно виртуальной машины.
1. Выполните скрипт для остановки машины:
    ```powershell
    Stop-VM -Name LON-SVR1 -TurnOff -Force -Confirm:$false
    ```

> Результаты: После выполнения задания вы изменили сетевые настройки, имя компьютера и подключили его к домену.
