# Hyper-V Tools
This module allows you to create New Hyper-V VMs to a standard build, including a command to remove them too.

I build and create a lot of VMs in a lab environment for testing things out. I thought I'd share it and let people contribute if they want. The code structure is loosely based on [dbatools](http://dbatools.io) so thanks to those guys! 

Supported guest operating systems:
  * Windows Server 2016 Core
  * Windows Server 2016
  * Windows Server 2012 R2
  * Windows Server 2008 R2

Tested on: 
 * Hyper-V 2016 Core
 * Hyper-V 2012 R2 Core

# Usage
## New-HyperVVM
 * **-ConfigFilePath**: Path to the config file which specifies options for the build
 * **-Verbose**: Verbose output

### Example
`New-HyperVVM -ConfigFile \\FILESERVER\VMConfigs\MyVMConfig.json \\FILESERVER\Credentials\HyperVAdminCredentials.xml -Verbose`. Creates a new VM with verbose output.

## Remove-HyperVVM
 * **-VMHostName**: The name of the Hyper-V Host where the VM resides
 * **-VMName**: The name of the VM (not the network name, the name in Hyper-V)
 * **-HyperVAdminCredentialsPath**: The path to the Hyper-V Admin credentials file
 * **-Verbose**: Verbose output

### Example
`Remove-HyperVVM -VMHostName HyperV -VMName MyVM -Verbose`. Deletes the VM *MyVM* from Hyper-V host *HyperV* including all VHDs with verbose output.

# Requirements
**Important please read or the tool will likely fail.**

There is a fair amount of setup required, but this only needs to be done once and then you can quickly and easily build VMs from then on.

## Credentials
Hyper-V Administrator credentials need to be supplied and exported to an encrypted file. To export the credentials, a helper function has been included `Export-Credentials -ExportPath`. Use this to export the Hyper-V Administrator credentials and the Golden Image Admin credentials to files which will be referenced by the attributes in the config files and will be loaded during the build. Be aware that the generated files are locked to the machine they are generated on for security. **They are not portable.**

If creating VMs in a domain, these credentials must have **join domain** privileges in the OU you are placing the VM in, and **Remove Computer** privileges. The account must be in the Hyper-V Administrators group or Local Administrators group on the Hyper-V host you are deploying to.

### Examples
If you have a Jenkins build server, log on to it, install HyperV-Tools and then run:
`Export-Credentials -ExportPath D:\Jenkins\Credentials\HyperVAdminCredentials.xml`

`Export-Credentials -ExportPath D:\Jenkins\Credentials\GoldenImageAdminCredentials.xml`

## Sysprepped operating system images
The tool creates VMs using pre-prepared sys-prepped images. These must be supplied by you and placed in a location accessible from the Hyper-V server with read permissions to the share. Keep the images minimal and allow the tool to configure the machines. It is recommended that you perform the following in the preparation of the image:

 * Download latest updates
 * Activate windows where required
 * Create an unattend.xml answer file and place in `C:\Windows\Panther\Unattend\` in the VHD of the sys-prepped image file
 * Keep a note of the local admin password for the image
 * Resist the temptation to configure the OS image beyond the above points

Look up how to sysprep a Windows operating system, it's beyond the scope of this document.

Once prepared, put the images somewhere like `\\FILESERVER\GoldenImages\<OS_Name>` for each OS you want to build and then reference that location in your build json file (see Config section below).

## Windows domain
A windows domain where the Hyper-V host is joined to and where the VM is deployed to is required. This may be extended to workgroups in the future.

# Config

## Per VM
The builds are controlled by two json config files. The required parameter: `ConfigFilePath` specifies the full path to the VM-specific configuration file and will overwrite and/or augment the `Common-Config` file. Put as many attributes as you can into Common-Config to make VM-specific configurations minimal.

## Common
 `Common-Config.json` must be located in the same directory as `ConfigFilePath` which is a set of attributes common to all VMs that will be created and should be tailored specific to your environment. The common file saves you having to create the same parameters over and over again in the Per VM config files.

## Config file attributes
See examples section below for example configurations. These can be placed in either config file specified above.
* **VMHostName**: The Hyper-V HostName to deploy VMs to
* **VMTemplatePath**: The path to the golden image used to build the VM (pre-prepared)
* **VMName**: The name of the VM in Hyper-V
* **MachineName**: The network name of the machine (excluding the domain)
* **VHDPath**: The path to the System drive *folder* on the Hyper-V host. This is where the guest VHD will be copied to from the sysprepped image VHD.
* **SwitchName**: Name of the Hyper-V Virtual switch to be connected.
* **Domain**: Domain to join to
* **OU**: The OU to place the computer account into, exluding the domain. E.g. `"ou=AutoCreatedVMs,ou=Computer"`
* **ProcessorCount**: Number of vCPUs to assign
* **StartupMemory**: Memory to configure on start-up
* **MinimumMemory**: Minimum memory value
* **MaximumMemory**: Maximum memory value
* **Generation**: 2 for 2012 onwards. Use 1 for 2008 R2 or earlier and Linux
* **IsCore**: Y or N indicates to the build whether this is a Core version of Windows or not
* **HyperVAdminCredentialsPath**: path on your workstation/server where the tools is run from to the credentials file created in the *Requirements* section above.
* **GoldenImageAdminCredentialsPath**: path on your workstation/server where the credentials are stored for the local admin account in the sysprepped image. See *Requirements* section above.
* **[InstallChocolatey]**: Optional. "Y" installs chocolatey package manager
* **[ChocolateyPackages]**: Optional if **InstallChocolatey** is not set. List of chocolatey packages to install
* **[DataVHDPath]**: Optional. Will create a data drive as D: in the VM. The path to the Data drive *folder* on the Hyper-V host.
* **[DataVHDMaxSize]**: Optional if **DataVHDPath** not specified. The max size of the data drive (e.g 512MB, 10GB, 1TB) 
* **[IpAddress]**: Optional. Set this for a static IP Address. If omitted, DHCP is used
* **[DefaultGateway]**: Optional. If setting **IpAddress**, this must be set too. If omitted, DHCP is used
* **[DNSServers]**: Optional. List of DNS Servers to use. If omitted, DHCP is used
* **[SNMPManager]**: Optional. The name of the SNMP server if you want to monitor with SNMP
* **[SNMPCommunity]**: Optional if **SNMPManager** not specified. The community name for the snmp server
* **[RunState]**: Optional. Sets the final run state. Off, Running, Paused, Saved. Defaults to Off
* **[DisableTimeSynchronization]** Optional, defaults to "Y". Can be "Y" or "N". Sets time synchronization with the Hyper-V host. It is recommended to install nettime with chocolatey and set this to "Y". See Common-Config example below.

# Examples
## Common-Config.json
```
{
    "VMHostName": "helium",
    "VHDPath" : "D:\\VHDs",
    "DataVHDPath" : "D:\\VHDs",
    "DataVHDMaxSize" : "10GB",    
    "SwitchName" : "Lab",
    "Domain" : "company.local",
    "OU" : "ou=AutoCreatedVMs,ou=Computer",
    "ProcessorCount" : "2",
    "StartupMemory" : "2GB",
    "MinimumMemory" : "512MB",
    "MaximumMemory" : "8GB",
    "SNMPManager" : "snmpserver.company.local",
    "SNMPCommunity" : "1w8NQVOz",    
    "Generation" : "2",
    "IsCore" : "N",
    "RunState" : "Off",
    "HyperVAdminCredentials" : "D:\\Jenkins\\Credentials\\HyperVAdminCredentials.xml",
    "GoldenImageAdminCredentials" : "D:\\Jenkins\\Credentials\\GoldenImageAdminCredentials.xml",
    "InstallChocolatey" : "Y",
    "ChocolateyPackages" : [
        "nettime",
        "bginfo"
    ],
    "DisableTimeSynchronization" : "Y"
}
```
## -ConfigFilePath
## <VMName>.json
This is an example for building a Windows Server 2016 VM. Values in here will *overwrite* anything specified in Common-Config.json.
```
{
    "VMTemplatePath" : "\\\\fileserver\\VMTemplates\\Windows 2016 Template\\System.vhdx",
    "VMName" : "Windows Server 2016",
    "MachineName" : "WINDOWS2016-VM1",
    "ProcessorCount" : "4",
    "VHDPath" : "E:\\VHDs",
    "IpAddress" : "10.10.10.46",
    "DefaultGateway" : "10.10.10.4",
    "DNSServers" : [
        "10.10.10.1",
        "4.4.4.4"
    ],
    "RunState" : "Running"
}
```
## Effective configuration from above examples
The above two configs will result in an effective configuration that looks like this. Remember that `ConfigFilePath` config file overwrites anything in Common-Config.json:
```
{
    "VMHostName": "helium",
    "VMTemplatePath" : "\\\\fileserver\\VMTemplates\\Windows 2016 Template\\System.vhdx",    
    "VHDPath" : "E:\\VHDs",
    "DataVHDPath" : "D:\\VHDs",
    "DataVHDMaxSize" : "10GB",    
    "SwitchName" : "Lab",
    "Domain" : "company.local",
    "OU" : "ou=AutoCreatedVMs,ou=Computer",
    "ProcessorCount" : "4",
    "StartupMemory" : "2GB",
    "MinimumMemory" : "512MB",
    "MaximumMemory" : "8GB",
    "SNMPManager" : "snmpserver.localdomain",
    "SNMPCommunity" : "1w8NQVOz",     
    "Generation" : "2",
    "IsCore" : "N",
    "HyperVAdminCredentials" : "D:\\Jenkins\\Credentials\\HyperVAdminCredentials.xml",
    "GoldenImageAdminCredentials" : "D:\\Jenkins\\Credentials\\GoldenImageAdminCredentials.xml", 
    "RunState" : "Running",    
    "InstallChocolatey" : "Y",
    "ChocolateyPackages" : [
        "nettime",
        "bginfo"
    ],
    "DisableTimeSynchronization" : "Y",
    "IpAddress" : "10.10.10.46",
    "DefaultGateway" : "10.10.10.4",
    "DNSServers" : [
        "10.10.10.1",
        "4.4.4.4"
    ]

}
```
You do not need to create the effective configuration, the tool will combine Common-Config and the ConfigFilePath configuration. This is just to illustrate what the final effective configuration would be in this example.