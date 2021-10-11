# Подготовка к лабораторным работам 

Продолжительность: 40 минут

## Цели
1. Отключение назойливых автоматических обновлений
1. Очистка диска от предыдущих заданий
1. Загрузка файлов для лабораторных работ
1. Подготовка базового диска для виртуальных машин и виртуальной машины с контроллером домена 

## Подготовка к лабораторной работе
Для выполнения лабораторных работ вы создадите виртуальные машины при помощи прилагающихся скриптов PowerShell. Для этого выполните следующие шаги:
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
    > Этот скрипт отключает обновления Windows, которые могут периодически отображаться в системе, мешая выполнению заданий:  

    ```powershell
    Stop-Service wuauserv
    Set-Service wuauserv –startup disabled
    ```  

1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    > Этот скрипт останавливает и удаляет все виртуальные машины:  
    ```powershell
    Get-VM | Stop-VM -TurnOff -Force -Confirm:$false -Passthru | Remove-VM -Force -Confirm:$false
    ```
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Запустите **Hyper-V Manager**
1. Убедитесь, что в окне отсутствуют виртуальные машины
1. Переключитесь обратно в **PowerShell**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**:  
    ```powershell
    Remove-Item -Path c:\vm -Recurse -Force -Confirm:$false
    ```
1. Откройте проводник Windows и убедитесь, что на диске **C** отсутствует директория **VM**
1. Вставьте следующий скрипт в окно консоли и нажмите клавишу **Enter**: 
     > Этот скрипт устанавливает виртуальную машину с контроллером домена Active Directory:  

   ```powershell
    powershell.exe -ExecutionPolicy Bypass -File "C:\Labs\Prepare-Labs.ps1"
    ```
1. Подождите примерно 20-30 минут до появления сообщения **Setup completed**, не закрывайте окно. 
1. Пока идет автоматизированныя установка, ознакомьтесь с содержанием скрипта **C:\Labs\Prepare-Labs.ps1**
1. Нажмите на кнопку **Пуск/Start** в Windows.
1. Найдите и запустите программу **Hyper-V manager**
1. На виртуальной машине **LON-DC1** нажмите правой кнопкой мыши и выберите **Connect**
1. Подождите, пока в окне не появится преложение ввести логин/пароль.
1. В появившемся окне в меню выберите **Action &#8594; CTRL+ALT+DEL**
1. Введите следующие данные:
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**

> Вы успешно подготовили среду для выполнения лабораторных работ. 