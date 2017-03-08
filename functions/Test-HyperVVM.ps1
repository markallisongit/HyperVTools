Function Test-HyperVVM
{    
<#
.SYNOPSIS 
Test-HyperVVM tests to see if the VM exists and returns $true or $false. 

.DESCRIPTION
Connects to the Hyper-V Host and looks to see if the VM exists on the host. If it exists, returns $true, if not returns $false.

.PARAMETER VMHostName
The network name of the Hyper-V host where the VM resides.

.PARAMETER VMName
The name of the VM on the Hyper-V host. NOTE: this will likely not be the same name as the network name of the VM. It is the name of the virtual machine.

.PARAMETER Credential
This credential must have Hyper-V Administrator rights on the target Hyper-V Host.

.NOTES
Author: Mark Allison

Requires: 
    Admin rights on the Hyper-V host.




This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE   
Test-HyperVVM -VMHostName HyperV -VMName NyVM -Credential (Get-Credential)
#>    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VMHostName, 
        
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    PROCESS
    {
        $exists = $false
        if (Invoke-Command -ComputerName $VMHostName -Credential $Credential { Get-VM -Name $using:VMName -ErrorAction SilentlyContinue } )
        {
            $exists = $true
        }
        $exists
    }
}