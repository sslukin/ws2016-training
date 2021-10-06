# Module 4: Configuring storage technologies and components

## Scenario
You are a Storage Administrator in Adatum Corporation, and part of your job is to ensure that your data storage systems meet both short-term and long-term business needs that evolve regularly.

## Objectives
After completing this lab, you will be able to:
1. Configure iSCSI storage.
1. Configure and manage shares.

## Lab Setup
For this lab, you will use the available virtual machine environment. Before you begin the lab, you must complete the following steps:
1. On the host computer, start Hyper‑V Manager.
2. In Hyper‑V Manager, click LON‑DC1, and then in the Actions pane, click Start.
3. In the Actions pane, click Connect. Wait until the virtual machine starts.
4. Sign in by using the following credentials:
    - User name: Adatum\Administrator
    - Password: Pa55w.rd
    - Domain: Adatum
5. Repeat steps 2 through 4 for LON‑SVR1.

## Exercise 1: Configuring iSCSI storage

### Exercise Scenario
You need to implement highly available iSCSI storage by using MPIO. There are two independent network paths between the file server and the iSCSI target. You will configure MPIO to use both paths to provide redundancy at the network level.

The main tasks for this exercise are as follows:
1. Install the iSCSI target feature
2. Create and configure an iSCSI target
3. Configure MPIO
4. Connect to the iSCSI target
5. Initialize the iSCSI disks

### Task 1: Install the iSCSI target feature

1. On **LON-DC1**, in **Server Manager**, install the **iSCSI Target Server** role service in **File and Storage Services**.

### Task 2: Create and configure an iSCSI target

1. On **LON‑DC1**, in **Server Manager**, in **File and Storage Services**, browse to **iSCSI**.
2. Create a new iSCSI virtual disk with the following settings:
    - Name: iSCSIDisk1
    - Disk size: 5 GB
    - iSCSI target: New
    - Target name: LON‑DC1
    - Access servers: 10.100.100.3,10.200.100.3
3. Create a second iSCSI virtual disk with the following settings:
    - Name: iSCSIDisk2
    - Disk size: 5 GB
    - iSCSI target: LON‑DC1

### Task 3: Configure MPIO

1. On **LON-SVR1**, in **Server Manager**, add the **Multipath I/O** feature.
2. After installation is complete, restart **LON-SVR1**, and then sign in as **Adatum\Administrator** with the password **Pa55w.rd**
3. In **Server Manager**, on the **Tools** menu, open **iSCSI Initiator**.
4. In the **iSCSI Initiator**, perform a quick connect to the target 10.100.100.2.
5. In **Server Manager**, on the **Tools** menu, open **MPIO**.
6. In **MPIO** Properties, on the **Discover Multi-Paths** tab, add support for **iSCSI devices**, and then restart when prompted.
7. After restarting, sign in as **Adatum\Administrator** with the password **Pa55w.rd**
8. In **Server Manager**, open **MPIO**, and then verify that **MSFT2005iSCSIBusType_0x9** is listed as a device.

### Task 4: Connect to the iSCSI target

1. On **LON-SVR1**, in **Server Manager**, on the **Tools** menu, open **iSCSI Initiator**.
2. On the **Targets** tab, disconnect from all sessions.
3. Connect again, select the following options, and then enter the **Advanced settings**:
    - Enable multi-path
    - Add this connection to the list of Favorite Targets.
4. In the **Advanced Settings** dialog box, select the following settings:
    - Local adapter: Microsoft iSCSI Initiator
    - Initiator IP: 10.100.100.3
    - Target Portal IP: 10.100.100.2 / 3260
5. Connect a second time, select the following options, and then enter the **Advanced settings**:
    - Enable multi-path
    - Add this connection to the list of Favorite Targets.
6. In the **Advanced Settings** dialog box, select the following settings:
    - Local adapter: Microsoft iSCSI Initiator
    - Initiator IP: 10.200.100.3
    - Target Portal IP: 10.200.100.2 / 3260
7. On the **Volumes and Devices** tab, select the **Auto Configure** option.
8. On the **Targets** tab, select the iqn.1991-05.com.microsoft:lon-dc1-lon-dc1-target target, and then view the **Devices**.
9. For **MPIO**, verify that:
    - Load balance policy: Round Robin
    - The path details match the IP addresses you configure for source and destination addresses

### Task 5: Initialize the iSCSI disks

1. On **LON-SVR1**, in **Server Manager**, in **File and Storage Services**, browse to **Disks**.
2. Select an offline disk with a bus type of **iSCSI**, and then bring it online.
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

> Results:  After completing this exercise, you should have successfully configured an iSCSI target that uses MPIO for redundancy.

## Exercise 2: Configuring and managing the share infrastructure

### Exercise Scenario
After configuring iSCSI storage for LON-SVR1, you need to create shares to support clients that are running both Windows and Linux operating systems.

The main tasks for this exercise are as follows:
1. Create an SMB share on iSCSI storage
2. Create an NFS share on iSCSI storage
3. Use Windows PowerShell to view share information
4. Disable the legacy SMB1 protocol
5. Prepare for the next module

### Task 1: Create an SMB share on iSCSI storage
1. On **LON-SVR1**, in **Server Manager**, in **File and Storage Services**, browse to **Shares**.
2. Create a new share by using the following settings:
    - File share profile: SMB Share – Quick
    - Select by volume: J:
    - Share name: Data
    - Enable access-based enumeration
    - Add permission: Domain Users, Modify

### Task 2: Create an NFS share on iSCSI storage
1. On **LON-SVR1**, in **Server Manager**, in **File and Storage Services**, browse to **Shares**.
2. Create a new share with the following settings:
    - File share profile: NFS Share – Quick
    - Select by volume: K:
    - Share name: LinuxData
    - Authentication method: Kerberos v5 authentication(Krb5)
    - Add share permission: All Machines, Read / Write

### Task 3: Use Windows PowerShell to view share information
1. On **LON-DC1**, open **File Explorer**, and then browse to **\\\LON-SVR1\Data**.
2. Create a new text file named **NewFile.txt**, and then open it in **Notepad**.
3. On **LON-SVR1**, open a **Windows PowerShell** prompt.
4. At the **Windows PowerShell** prompt, type the following command, and then press **Enter**:
    ```powershell
    Get-NfsShare
    ```
5. Type the following command, and then press **Enter**:
    ```powershell
    Get-NfsShare LinuxData | FL *
    ```
6. Type the following command, and then press **Enter**:
    ```powershell
    Get-SmbShare
    ```
7. Type the following command, and then press **Enter**:
    ```powershell
    Get-SmbShare Data | FL *
    ```
8. Type the following command, and then press Enter:
    ```powershell
    Get-SmbSession
    ```
9. Type the following command, and then press Enter:
    ```powershell
    Get-SMBSession -ClientUserName Adatum\Administrator | FL *
    ```
10. Type the following command, and then press Enter:
    ```powershell
    Get-SmbOpenFile
    ```

>Note: There are two entries for Adatum\Administrator. File Explorer creates one, and Notepad creates the other. If NewFile.txt is not included, it is because the file connection is maintained only for brief periods when you open the file initially or save it. If you do not see two entries, switch to LON-DC1, close Notepad, and then double-click NewFile.txt. Then, on LON-SVR1, repeat step 10. 

11. Leave the Windows PowerShell prompt open for the next task.

### Task 4: Disable the legacy SMB1 protocol

1. On LON-SVR1, at the **Windows PowerShell** prompt, type the following command, and then press **Enter**:
    ```powershell
    Set-SmbServerConfiguration -AuditSmb1Access $true
    ```
2. Type the following command, and then press **Enter**:
    ```powershell
    Get-SmbServerConfiguration | FL enable*
    ```
3. Type the following command, and then press **Enter**:
    ```powershell
    Set-SmbServerConfiguration -EnableSMB1Protocol $false
    ```
4. Type the following command, and then press **Enter**:
    ```powershell
    Get-WindowsFeature *SMB*
    ```
5. Type the following command, and then press **Enter**:
    ```powershell
    Remove-WindowsFeature FS-SMB1
    ```

### Task 5: Prepare for the next module

After you finish the lab, revert the virtual machines to their initial state by completing the following steps:
1. On the host computer, switch to the Hyper‑V Manager console.
2. In the Virtual Machines list, right-click LON‑DC1, and then click Revert.
3. In the Revert Virtual Machine dialog box, click Revert.
4. Repeat steps 2 and 3 for LON-SVR1.

> Results: After completing this exercise, you should have successfully created SMB and NFS shares.