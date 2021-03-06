# Module 2 - Installing Windows Server 2016 #

Duration: 60 minutes

## Scenario
Your team in the IT department at Adatum Corporation just purchased a new server that has no operating system. The team decides to install Windows Server 2016 Datacenter in Server Core mode to test Server Core functionality. Your task is to perform the installation and configuration of this server. You will name it **LON-SVR1**, give it a static IP address of **172.16.0.26**, and join it to the **Adatum.com** domain with all other default settings.

## Objectives
After completing this lab, you will be able to: 
1. Install the Server Core option for Windows Server 2016.
1. Configure Server Core.

## Lab Setup
For this lab, you will use the available virtual machine environment. Before you begin the lab, complete the following steps:
1. On the host computer, start **PowerShell** as Administrator
1. Execute the following script to download important training files:
    ```powershell
    $url = "https://github.com/sslukin/ws2016-training/archive/refs/heads/main.zip"
    $zip = "c:\ws2016.zip"
    $expand = "C:\ws2016-training-main"
    Start-BitsTransfer -Source $url -Destination $zip -TransferType Download
    Expand-Archive $zip -DestinationPath c:\
    Copy-Item "$expand\Labs" -Destination c:\Labs -Recurse
    Remove-Item $zip, $expand -Confirm:$false -Force -Recurse
    ```
1. Execute the following script to diable Windows updates:
    ```powershell
    Stop-Service wuauserv
    Set-Service wuauserv –startup disabled
    ```
1. Execute the following script to install virtual machine with domain controller for your labs:
    ```powershell
    powershell.exe -ExecutionPolicy Bypass -File "C:\Labs\Lab02\Prepare-Lab02.ps1"
    ```
1. Wait approximately 20-30 minutes until you see a message **Setup completed**. 
1. Meanwhile review the Powershell script responsible for automated installation located at **C:\Labs\Lab02\Prepare-Lab02.ps1**
1. In the **Actions** pane, click **Connect**. Wait until the virtual machine starts.
1. Sign in by using the following credentials:
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**
1. In **Hyper‑V Manager**, right-click **LON-SVR1**, and then select **Connect**. In the virtual machine connection window, click **Media**, point to **DVD Drive**, and then click **Insert Disk**.
1. Browse to **C:\iso**, select **.iso** file, and then click **Open**.

## Exercise 1: Installing Server Core

### Exercise Scenario
You determine that Server Core offers you the best installation option and decide to evaluate a server that uses Server Core.
The main tasks for this exercise are as follows:
1. Install Windows Server 2016 Datacenter on LON-SVR1

#### Task 1: Install Windows Server 2016 Datacenter on LON-SVR1
1. In the **LON-SVR1** Virtual Machine Connection window, click the **Start** icon.
1. When **LON-SVR1** starts Windows Setup, install **Windows Server 2016 Core** by using the **Windows Server 2016 Datacenter** option.
1. Use the following product key when propmpted:  
    **CB7KF-BWN84-R7R2Y-793K2-8XDDG**  
      
    > For more information read this article  
    https://docs.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys
1. Use the **Custom** option rather than the **Update** option, accepting all other default values and license agreements.
1. Use **Pa55w.rd** for the Administrator’s password.
1. Verify that when the installation is complete, the **Command Prompt** window on **LON-SVR1** opens with a **C:\Users\Administrator> prompt**.

> Results: After completing this exercise, you will have successfully installed the Windows Server 2016 Core operating system on **LON-SVR1**.
 
## Exercise 2: Completing post-installation tasks on Windows Server 2016 Core

### Exercise Scenario
You must now complete the installation of Server Core by configuring the post-installation settings and joining it to the **Adatum.com** domain. You will also install the DNS Server role.

The main tasks for this exercise are as follows:
1. Use Windows PowerShell and Sconfig.cmd to configure the settings of Server Core

#### Task 1: Use Windows PowerShell and Sconfig.cmd to configure the settings of Server Core
1. Open **PowerShell** on **LON-SVR1**.
2. Use the `$env:computername` and `Get-NetIPAddress` cmdlets to display the **LON-SVR1** host name and IPv4 address information.
3. Note that the name is random and that the address is automatically derived from a DHCP Server.
4. Run the `Sconfig.cmd` tool on **LON-SVR1**. Use the tool to set the following:
    - IP Address settings:
        - Address: **172.16.0.26**
        - Subnet Mask: **255.255.0.0**
        - Default Gateway: **172.16.0.1**
        - Preferred DNS Server: **172.16.0.01**
    - Join the **Adatum.com** domain and use **Adatum\administrator** credentials.
    - Rename the computer **LON-SVR1** and use **Adatum\Administrator** credentials.
    - Restart the computer.
5. After **LON-SVR1** starts, sign in as **Administrator** with the password **Pa55w.rd** .
6. Start **PowerShell**, and then use the `$env:computername` and `Get-NetIPAddress` cmdlets to display the **LON-SVR1** host name and IPv4 address information.
7. Note that the name is **LON-SVR1** and that the address is **172.16.0.26**.
8. Type the following, and then press **Enter**:
    ```powershell
    Install-WindowsFeature DNS
    ```
> Results:  After completing this exercise, you will have successfully configured the domain and network settings of Server Core and install an additional role.
 
## Exercise 3: Performing remote management

### Exercise Scenario
Now that you added the **DNS Server** role to Server Core on **LON-SVR1**, you want to explore configuring the DNS settings and configuration by using GUI tools on other Windows Server with Desktop Experience systems.

The main tasks for this exercise are as follows:
1. Enable remote management with Server Manager
2. Add **LON-SVR1** to **DNS Manager** on **LON-DC1** and then add the **Adatum.com** zone to **LON-SVR1** as a secondary zone 
3. Examine the new zone information on **LON-SVR1**
4. Prepare for the next module

### Task 1: Enable remote management with Server Manager
1. On **LON-DC1**, in **Server Manager**, add **LON-SVR1** to the **Computer** list. 
2. Open **DNS Manager**, and then add **LON-SVR1** as a name server in the **Adatum.com** zone.
3. In **DNS Manager**, allow zone transfers to all name servers, and then set **Notify** to **172.16.0.26**.

### Task 2: Add LON-SVR1 to DNS Manager on LON-DC1 and then add the Adatum.com zone to LON-SVR1 as a secondary zone
1. In **DNS Manager**, on **LON-DC1**, add **LON-SVR1** as an additional **DNS server** by using the **Connect to DNS Server** window.
2. In **DNS Manager**, add the **Adatum.com** zone as a secondary zone on **LON-SVR1**, using **LON-DC1** as the master **DNS server**.
3. Refresh **DNS Manager**, and then verify that **LON-SVR1** has the **Adatum.com** zone information and resource records from **LON-DC1**.

### Task 3: Examine the new zone information on LON-SVR1
1. Return to **LON-SVR1**.
2. Use the dnscmd command to enumerate the zones and note the type of zone for **Adatum.com**:

    ```powershell
    Dnscmd /enumzones
    ```
3. Use `dnscmd` to enumerate the zones on **LON-DC1** and note the type of zone for **Adatum.com**:

    ```powershell
    Dnscmd LON-DC1 /enumzones
    ```
4. Display the DNS client server address by using PowerShell:

    ```powershell
    Get-DnsClientServerAddress
    ```
5. Set the **LON-SVR1** DNS server address, replacing the **X** with the actual interface index number from **step 4**:

    ```powershell
    Set-DnsClientServerAddress -InterfaceIndex X -ServerAddresses ("172.16.0.26", "172.16.0.01")
    ```
6. Verify the results. Use the **PowerShell** command from **Step 4**.

> Results: After completing this exercise, you will have configured the DNS Server settings on LON-SVR1 remotely.
 
## Lab Review

**Question**

In the lab, you used the Install-WindowsFeature cmdlet in Windows PowerShell to install the DNS Server role on LON-SVR1. How could you do this remotely?

**Answer**

You can use many methods to add a server role to a Server Core installation of Windows Server 2016 remotely. You can use Windows PowerShell remotely from one computer to another by using a PSSession command sequence. You can also add the Server Core system to a Server with Desktop Experience system’s Server Manager and then install the role or feature by using the Add roles and features Wizard in Server Manager.