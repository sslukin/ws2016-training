# Лабораторная работа: Windows Server Backup


## Задание 1: Резервное копирование и восстановление с Windows Server Backup

### Шаг 1: Configure Windows Server Backup options

1. If necessary, sign in to **LON-SVR4** as **Adatum\\Administrator** with password **Pa55w.rd**.

1. Select **File Explorer** on the taskbar.

1. In the **File Explorer** window, select **Local Disk (C:)** in the **navigation** pane.

1. Right-click or access the context menu in an empty space in the **details** pane, select **New**, and then select **Folder**. You can also open **File Explorer**, select the **Home** menu, and then select the **New Folder** option.

1. Name the folder **BackupShare**. Right-click or access the context menu for the **BackupShare** folder, select **Give access to**, and then select **Specific people**.

1. In the **Network access** window, enter **Authenticated Users**, and then select **Add**. In the **Permission Level** column, set the value for **Authenticated Users** to **Read/Write**, select **Share**, and then select **Done**.

1. Select **Start**, and then enter **powershell**. Right-click or access the context menu for Windows PowerShell, and then select **Run as administrator**.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

   ```powershell
   $cred=Get-Credential
   ```

   When prompted, sign in as **Adatum\\Administrator** with password **Pa55w.rd**.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

   ```powershell
   $sess = New-PSSession -Credential $cred -ComputerName lon-svr4.adatum.com
   ```

   Next, enter the following command, and then select Enter:

   ```powershell
   Enter-PSSession $sess
   ```

   You should get a [`lon-svr4.adatum.com`] title in your command prompt. From this point, all commands that you enter run on **LON-SVR4**.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

    ```powershell
    Import-Module Servermanager
    ```

    Next, enter the following command, and then select Enter:

    ```powershell
    Get-WindowsFeature Windows-Server-Backup
    ```

    Ensure that the **Install State for Windows Server Backup** feature is **Available**.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

    ```powershell
    Install-WindowsFeature Windows-Server-Backup
    ```

    Wait until you get the result. Ensure that **True** displays in the **Success** column.

1. Repeat the command:

    ```powershell
     Get-WindowsFeature Windows-Server-Backup
    ```

    Ensure that the **Install State for Windows Server Backup** feature is now **Installed**.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

    ```powershell
    wbadmin /?
    ```

    You'll get the list of commands that are available for the Windows Server Backup command-line tool.

1. In the **Administrator: Windows PowerShell** window, enter the following command, and then select Enter:

    ```powershell
    Get-Command -Module WindowsServerBackup -CommandType Cmdlet
    ```

    You'll get a list of available PowerShell cmdlets for Windows Server Backup.

### Task 2: Perform a backup

1. In the PowerShell window where you have a remote PowerShell session opened for **`lon-svr4.adatum.com`**, enter the following commands, and then select Enter:

   ```powershell
   $Policy = New-WBPolicy
   $Filespec = New-WBFileSpec -FileSpec "C:\Files"
   ```

1. After you have run the commands from the previous step, where you defined variables for the backup policy and the file path to back up, add this to the backup policy by entering the following command, and then selecting Enter:

   ```powershell
   Add-WBFileSpec -Policy $Policy -FileSpec $FileSpec
   ```

1. Now, you must configure a backup location on the **LON-SVR4** network share by entering the following commands, and then selecting Enter:

   ```powershell
   $Cred = Get-Credential
   $NetworkBackupLocation = New-WBBackupTarget -NetworkPath "\\LON-SVR4\BackupShare" -Credential $Cred
   ```

   >**Note**: When prompted, sign in as **Adatum\\Administrator** with password **Pa55w.rd**.

1. Now you must add this backup location to the backup policy by entering the following command, and then selecting Enter (if prompted, enter Y, and then select Enter):

   ```powershell
   Add-WBBackupTarget -Policy $Policy -Target $NetworkBackupLocation
   ```

1. Before starting a backup job, you must configure more options to enable Volume Shadow Copy Service backups by entering the following command, and then selecting Enter:

   ```powershell
   Set-WBVssBackupOptions -Policy $Policy -VssCopyBackup
   ```

1. To start a backup job, in order to back up the content of the **C:\\Files** folder on **LON-SVR4** to a network share on **LON-SVR4**, you must enter the following command, and then select Enter:

   ```powershell
   Start-WBBackup -Policy $Policy
   ```

   Wait until you receive the "The backup operation completed" message.

1. On **LON-SVR4**, open File Explorer, and then browse to **C:\\BackupShare**. Open the folder, and then ensure that the backup files are there.

1. Close all PowerShell windows.

**Results**: After completing this exercise, you should have configured Windows Server Backup and performed a backup on **LON-SVR4**.