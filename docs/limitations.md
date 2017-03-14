# Known limitations
## Windows Server 2008 R2 builds
Some issues were encountered with Windows Server 2008 R2. As few of these are being built these days, effort has not been put in to solve these outstanding problems.
 * bginfo scheduled task will not be created
 * SNMP service will not be configured
 * If specifying a data drive, it will be left RAW and unformatted
 * Build time is significantly longer, perhaps more than 3X, than 2012 R2 onwards

## Windows Server 2012 (not R2)
This has not been tested. See the readme.md for supported versions.

## Hyper-V host in a WORKGROUP
The tool has been tested in a domain environment. It has not been tested with Hyper-V in a WORKGROUP. Guest VMs in a WORKGROUP with the Hyper-V host in a domain is supported and tested.

# GitHub Issues list
For a list of outstanding issues see the list on [GitHub](https://github.com/markallisongit/HyperVTools/issues)
