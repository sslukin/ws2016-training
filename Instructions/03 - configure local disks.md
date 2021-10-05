# Module 2 - Configuring local disks #

Duration: 40 minutes

## Scenario
Your manager has asked you to add disk space to a file server that is running on a virtual machine. This virtual machine will potentially grow significantly in size in the upcoming months and you might need flexibility in your storage options. Your manager has asked you to optimize the cluster and sector size for virtual machines usage to accommodate large file sizes for storage on virtual machines. You need to assess the best options for storage and ease of expansion for potential future use.

## Objectives
After completing this lab, you should be able to:
1. Create and manage virtual hard disks.
1. Resize volumes.

## Lab Setup
For this lab, you will use the available virtual machine environment. Before beginning the lab, you must complete the following steps:
1. On the host computer, start **Hyper-V Manager**.
1. In Hyper-V Manager, click **LON-DC1**, and then in the **Actions** pane, click **Start**.
1. In the **Actions** pane, click **Connect**. Wait until the virtual machine starts.
1. Sign in by using the following credentials: 
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**
	- Domain: **Adatum**
1. In **Hyper-V Manager**, click **LON-SVR1**, and then in the **Actions** pane, click **Start**.
1. In the **Actions** pane, click **Connect**. Wait until the virtual machine starts.
1. Sign in by using the following credentials: 
    - User name: **Adatum\Administrator**
	- Password: **Pa55w.rd**
	- Domain: **Adatum**

## Exercise 1: Creating and managing volumes

### Exercise Scenario
In the test lab, you start by creating a number of volumes on the installed hard disks.

The main tasks for this exercise are as follows:
1. Create a hard disk volume and format for ReFS
2. Create a mirrored volume

### Task 1: Create a hard disk volume and format for ReFS
1. On **LON-SVR1**, open **Windows PowerShell (Admin)**. 
2. Create a new volume formatted for **ReFS** by using all the available disk space on **Disk 1**. Use the following Windows PowerShell cmdlets to complete this process: 

    - List all the available disks that have yet to be initialized:
    
        `Get-Disk | Where-Object PartitionStyle –Eq "RAW"`
    - Initialize disk 2: 
    
		`Initialize-disk 2`
    - Review the partition table type: 
		
        `Get-disk`
    - Create an ReFS volume by using all the available space on disk 1: 
    
        `New-Partition -DiskNumber 2 -UseMaximumSize -AssignDriveLetter | Format-Volume -NewFileSystemLabel "Simple" -FileSystem ReFS`
1. Open File Explorer, and verify that the new drive is created and formatted. What is the drive letter? 

### Task 2: Create a mirrored volume
1. Open **Disk Management**, and initialize all remaining disks. 
1. Create a new volume on **Disk 3** and **Disk 4** with the following properties: 
	- Disks: **Disk 3** and **Disk 4**
	- File system: **NTFS**
	- Quick format: **Yes**
	- Drive letter: **M**
	- Volume label: **Mirror**

> Results:  After completing this exercise, you should have successfully created several volumes.
 
## Exercise 2: Resizing volumes

### Exercise Scenario
You create a new volume, and then realize that you must resize it. You decide to use **Diskpart.exe** to complete this process. 

The main tasks for this exercise are as follows:
1. Create a simple volume and resize it
2. Shrink a volume
3. Prepare for the next exercise

 ## Task 1: Create a simple volume and resize it
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

## Task 2: Shrink a volume
1. In the **Windows PowerShell (Admin)** window, run the following command:
    `Shrink desired=15000`  
2. Switch to **Disk Management**. 
3. Verify the presence of an **NTFS** volume on **Disk 5** of size approximately **5 GB**.
4. Close the **Windows PowerShell (Admin)** window.

## Task 3: Prepare for the next exercise
1. On the host computer, start Hyper-V Manager.
2. In the Virtual Machines list, right-click LON-DC1, and then click Revert.
3. In the Revert Virtual Machine dialog box, click Revert.
4. Repeat steps 2 and 3 for LON-SVR1.
5. Restart your computer and select LON-HOST1 when prompted.
6. Sign in as Administrator with the password Pa55w.rd. 

> Results: After completing this exercise, you should have successfully resized a volume.
 
## Exercise 3: Managing virtual hard disks

### Exercise Scenario
You are required to create and configure virtual hard disks for use in a Windows Server 2016 server computer. The virtual hard disk is for the Sales department. You decide to use Windows PowerShell to achieve these objectives. First, you must install the Windows PowerShell Hyper-V module. 

The main tasks for this exercise are as follows:
1. Install the Hyper-V module
2. Create a virtual hard disk
3. Reconfigure the virtual hard disk
4. Prepare for the next module
 
### Task 1: Install the Hyper-V module
1.      On your host computer, open Server Manager and install the Hyper-V server role and management tools.
2.      Restart your computer and select 20740C-LON-HOST1 when prompted.
	      
> Note: Your computer might restart several times following installation of the Hyper-V components. 
	
3.      Sign in as Administrator with the password Pa55w.rd. 

### Task 2: Create a virtual hard disk
1. On your host computer, open Windows PowerShell (Admin). 
2. At the Windows PowerShell command prompt, type the following command, and then press Enter: 

	```powershell
	New-VHD -Path c:\sales.vhd -Dynamic -SizeBytes 10Gb | Mount-VHD -Passthru | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false -Force
	```

> Note: If you receive a Microsoft Windows pop-up dialog box prompting you to format the disk, close it and continue.

### Task 3: Reconfigure the virtual hard disk

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

### Task 4: Prepare for the next module

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
