# Get-UnknownDevices
#####Featured in my blog on [FoxDeploy.com - Using PowerShell to find driver and devices for Device Manager](http://foxdeploy.com/2015/07/31/using-powershell-to-find-drivers-for-device-manager/)
When building a new system image for MDT or SCCM, it is common to need to lay down a new OS image and troubleshoot missing drivers.  This tool simplifies detemining what device is really meant by 'Unknown Device' in the Device Manager


Based [.off of this great post by Johan Arwidmark of Deployment Research](http://deploymentresearch.com/Research/Post/306/Back-to-basics-Finding-Lenovo-drivers-and-certify-hardware-control-freak-style), this cmdlet can be used on a new system to help locate the names and IDs of device drivers.  The Cmdlet can be used without parameters, which will return a listing of all the devices with missing drivers.  Or, it can be run on a machine without web acess, using -Export to export a file.  The file should then be copied to a machine with web access where the -Import param can be used to import this file

This tool aims to help you easily solve device manager woes like this one

![alt tag](https://github.com/1RedOne/Get-UnknownDevices/blob/master/img/unhappy_device_manager.png)

#How to use

####Standalone mode

`.\Get-UnknownDevices.ps1 `

In this case, the cmdlet was run without any parameters which returns a list of any missing drivers and the likely source file, according to the PCIDatabase

    VendorID DeviceID DevMgrName                                                                LikelyName                                                         
    -------- -------- ----------                                                                ----------                                                         
    8086     1E2D     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E2D Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
    8086     1E26     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E26 Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
    1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...                         
    8086     1E31     Intel(R) USB 3.0 eXtensible Host Controller - 1.0 (Microsoft)                                                                                
    1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...                         


####Running on a system with no Internet Access.

 1. First, run the cmdlet with -Export
 
   `.\Get-UnknownDevices.ps1 -Export C:\temp\DriverExport.csv`
    >Export file created at C:\temp\DriverExport.csv, please copy to a machine with web access, and rerun this tool, using the -Import flag

 2. Copy the file over to a system with Web Access and speciy the file as the -Import file
 
     .\Get-UnknownDevices.ps1 -Import C:\temp\DriverExport.csv

     VendorID DeviceID DevMgrName                         LikelyName                       
     -------- -------- ----------                         ----------                       
     1186     4300     DGE-530T Gigabit Ethernet Adapter. Used on DGE-528T Gigabit adapt...
    
    
#Changes / troubleshooting
Currently this tool only parses devices and hardware IDs in the format of DEV_#### or VEN_####, in a future version, support for PID or other ID types will be added.


