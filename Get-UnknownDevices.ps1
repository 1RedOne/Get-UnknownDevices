<#
.Synopsis
   When building a new system image for MDT or SCCM, it is common to need to lay down a new OS image and troubleshoot missing drivers.  This tool simplifies detemining what device is really meant by 'Unknown Device' in the Device Manager
.DESCRIPTION
   Based off of this great post by Johan Arwidmark of Deployment Research, this cmdlet can be used on a new system to help locate the names and IDs of device drivers.  The Cmdlet can be used without parameters, which will return a listing of all the devices with missing drivers.  Or, it can be run on a machine without web acess, using -Export to export a file.  The file should then be copied to a machine with web access where the -Import param can be used to import this file
.INPUTS
   To determine drivers from a system without internet access, use the -Import switch to specify the path to an import.csv file
   To determine drivers for the local system, no input is needed
.OUTPUTs
   In regular mode, emits PowerShell objects, containing a VendorID, DeviceId, DevMgrName and LikelyName properties
   In -Export mode, creates a import.csv file which can be copied and uses on a remote machine to resolve drivers (as web access is needed)
.EXAMPLE
    .\Get-UnknownDevices.ps1 

VendorID DeviceID DevMgrName                                                                LikelyName                                                         
-------- -------- ----------                                                                ----------                                                         
8086     1E2D     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E2D Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
8086     1E26     Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controller - 1E26 Intel(R) 7 Series/C216 Chipset Family USB Enhanced Host Controll...
1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...                         
8086     1E31     Intel(R) USB 3.0 eXtensible Host Controller - 1.0 (Microsoft)                                                                                
1B21     1042     ASMedia USB 3.0 eXtensible Host Controller - 0.96 (Microsoft)             Asmedia ASM104x USB 3.0 Host Controller...                         

In this case, the cmdlet was run without any parameters which returns a list of any missing drivers and the likely source file, according to the PCIDatabase
.EXAMPLE
   .\Get-UnknownDevices.ps1 -Export C:\temp\DriverExport.csv

    >Export file created at C:\temp\DriverExport.csv, please copy to a machine with web access, and rerun this tool, using the -Import flag
.EXAMPLE
    .\Get-UnknownDevices.ps1 -Import C:\temp\DriverExport.csv

VendorID DeviceID DevMgrName                         LikelyName                       
-------- -------- ----------                         ----------                       
1186     4300     DGE-530T Gigabit Ethernet Adapter. Used on DGE-528T Gigabit adapt...
.LINK
   Copy and paste any of the links below for more information about this cmdlet
   start http://www.Foxdeploy.com
   start http://deploymentresearch.com/Research/Post/306/Back-to-basics-Finding-Lenovo-drivers-and-certify-hardware-control-freak-style
#>
Function Get-UnknownDevices{
[CmdletBinding()]
Param([ValidateScript({test-path (Split-Path $path)})]$Export,
      [ValidateScript({test-path $path})]$Import,
      [ValidateScript({test-path $path})]$Cab,
      [switch]$test)
begin {
        $i = 0
        
        if ($Import){
            $devices = Import-Csv $import
            }
            else {
            
            if ($Test){
                #For Testing, pull all devices
                $devices = Get-WmiObject Win32_PNPEntity | Where-Object{$_.ConfigManagerErrorCode -eq 0} | Select Name, DeviceID
                #For testing, I'm purposefully pulling Ethernet drivers
                $unknown_Dev = $devices | where Name -like "*int*"                
                }
                else{
                    #if not running in -Test
                    #For Prod, Query WMI and get all of the devices with missing drivers
                    $devices = Get-WmiObject Win32_PNPEntity | Where-Object{$_.ConfigManagerErrorCode -ne 0} | Select Name, DeviceID
                    #For production
                    $unknown_Dev = $devices
                }
        }

        

        

        if ($Export){
            $unknown_Dev | export-csv $Export 
            Write-host "Export file created at $Export, please copy to a machine with web access, and rerun this tool, using the -Import flag"
            BREAK
            }
        
        
        

        $unknown_Dev | % {$i++}
        $count = $i

        Write-verbose "$i unknown devices found on $env:COMPUTERNAME"
        If ($VerbosePreference -eq 'Continue'){
            $unknown_Dev | Format-Table}

            
        $FoldersToImport = new-object System.Collections.ArrayList
}


process{
        forEach ($device in $unknown_Dev){
            Write-Debug "to test the current `$device, $($device.Name), stop here"

            #Pull out specific values for VendorID and DeviceID, from the objects in $Unknown_dev
            $vendorID = ($device.DeviceID | Select-String -Pattern 'VEN_....' | select -expand Matches | select -expand Value) -replace 'VEN_',''
            $deviceID = ($device.DeviceID | Select-String -Pattern 'DEV_....' | select -expand Matches | select -expand Value) -replace 'DEV_',''

            if ($deviceID.Length -eq 0){
                Write-Verbose "found a null device, skipping..."
                Continue}

            if ($cab){
            #need to filter to include only those with matching $vendorId too
            $path = get-childitem $cabpath -recurse -include "*.inf" | select-string -pattern "ControlFlags" | gci | select-string $deviceID -list| gci | select-string -pattern $VendorID -list | Tee-Object -Variable Driver |  % {split-path $_.Path -Parent }

            $path | select -unique | ForEach {$FoldersToImport.add($_) | out-null}

            #drivers / folders
            [pscustomobject]@{Device=$device.Name;
                    DriverFiles=($driver.Filename |Select -unique) -join ',';
                    DriverFolders=($path | select -unique )-join "`n"}
            #"The drivers for the device $($device.Name) appear to be $($driver.Filename -join ',') which are found in this dir: $path"
            Continue
            }

            Write-Verbose "Searching for devices with Vendor ID of $vendorID and Device ID of $deviceID "

            $url = "https://devicehunt.com/search/type/pci/vendor/$vendorID/device/$deviceID"
            try {$res = Invoke-WebRequest $url -UserAgent InternetExplorer}
         catch [System.NotSupportedException]{Write-warning "You need to launch Internet Explorer once before running this";return}
         
            $matches = ($res.ParsedHtml.getElementsByTagName('p') | select -expand innerHtml).Split()[1] 
            Write-Verbose "Found $matches matches"

            $htmlCells = $res.ParsedHtml.getElementsByTagName('tr')  | select -skip 4 -Property *html*
            Write-Debug "test `$htmlCells for the right values $htmlCells"
            
            #
            $matchingDev = ($htmlCells.InnerHtml | Select-String -Pattern $vendorID | select -expand Line).ToString().Split("`n")
            if ($matchingDev.count -ge 1){
                    [pscustomobject]@{VendorID=$vendorID;DeviceID=$deviceID;DevMgrName=$device.Name;LikelyName=$matchingDev[1] -replace '<TD>','' -replace '</TD>',''}}
                else{CONTINUE}

                }
}
end{

    "To enable all of the unknown devices on your system, import drivers from these paths"
    $FoldersToImport | select -Unique
}
}

<#
To do :

Add parameter sets, where -CAB forces the user to specify a Cab path

add support for unzipping actual cabs files

rewrite help docs

#>


<#
#experiemental weird stuff below

#Finds infs with matching device IDs
get-childitem $cabpath -recurse -include "*.inf" | select-string -pattern $deviceID -list| select Path

#need to filter to include only those with matching $vendorId too
$path = get-childitem $cabpath -recurse -include "*.inf" | select-string -pattern "ControlFlags" | gci | select-string $deviceID -list| gci | select-string -pattern $VendorID -list | Tee-Object -Variable Driver |  % {split-path $_.Path -Parent }

#drivers / folders

"The drivers for the device $($device.Name) appear to be $($driver.Filename -join ',') which are found in this dir: $path"
#>
