# Get-UnknownDevices
Featured in my blog on FoxDeploy.com


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


