Function Remove-HyperVVM
{
<#
.SYNOPSIS 
Remove-HyperVVM deletes a Hyper-V VM and all disks attached to it, including all checkpoints. 

.DESCRIPTION
Removes a Hyper-V VM from a Hyper-V host then deletes the drives that were attached to the VM and the checkpoints that were made during the lifetime of the VM.

.PARAMETER VMHostName
The network name of the Hyper-V host where the VM resides.

.PARAMETER VMName
The name of the VM on the Hyper-V host. NOTE: this will likely not be the same name as the network name of the VM. It is the name of the virtual machine.

.PARAMETER HyperVAdminCredentialsPath
Removing a Hyper-V VM requires admin credentials. This is the path to the credentials file. If they don't exist you can create them with Export-Credentials

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
    Admin rights on the Hyper-V host. Can be specified as an encrypted xml file.




This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE   
Remove-HyperVVM -VMHostName HyperV -VMName MyVM -Verbose

Removes the VM called MyVM from Hyper-V host HyperV.
#>    
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$VMHostName,

    [Parameter(Mandatory)]
    [string]$VMName,

    [Parameter(Mandatory)]
    [string]$HyperVAdminCredentialsPath
)

PROCESS
{
    $ErrorActionPreference = "Stop"
    $verbose = $VerbosePreference -ne 'SilentlyContinue'
    $retryTimes = 3

    if([string]::IsNullOrEmpty($JenkinsPath))
    {
        $JenkinsPath = "D:\Jenkins"
    }
    $tries = 0
    $HyperVAdminCredentials = Read-CredentialsFromFile $HyperVAdminCredentialsPath
    if (Test-HyperVVM -VMHost $VMHostName -VMName $VMName -Credential $HyperVAdminCredentials )
    {
        $VMHostSession = New-PSSession -ComputerName $VMHostName -Credential $HyperVAdminCredentials
        $VMState = Invoke-Command -Session $VMHostSession { (Get-VM -ComputerName $using:VMHostName -Name $using:VMName).State }
        Write-Verbose "$(Get-Date -Format u) $VMName exists and is $($VMState.Value)"

        if($VMState.Value -eq "Saved") {
            Invoke-Command -Session $VMHostSession { Start-VM -Name $using:VMName } 
            while (((Invoke-Command -Session $VMHostSession { (Get-VM -ComputerName $using:VMHostName -Name $using:VMName).State })).Value -ne "Running") {Start-Sleep -Seconds 1} 
        }
        if($VMState.Value -eq "Paused") {
            Invoke-Command -Session $VMHostSession { Resume-VM -Name $using:VMName }    
            while (((Invoke-Command -Session $VMHostSession { (Get-VM -ComputerName $using:VMHostName -Name $using:VMName).State })).Value -ne "Running") {Start-Sleep -Seconds 1} 
        }
        
        $NumDisks = Invoke-Command -Session $VMHostSession { (Get-VMHardDiskDrive -VMName $using:VMName).Count }
        Write-Verbose "$(Get-Date -Format u) Found $NumDisks hard disks on $VMName"
        
        Write-Verbose "$(Get-Date -Format u) Merging Checkpoints"
        try {
            $tries++
            Invoke-Command -Session $VMHostSession { Get-VM $using:vmname| Stop-VM -Passthru | Get-VMSnapshot | Remove-VMSnapshot }
            while ((Invoke-Command -Session $VMHostSession { (Get-VM $using:vmname|Get-VMSnapshot).Count }) -gt 0) { Start-Sleep -seconds 1 }            
            while ((Invoke-Command -Session $VMHostSession { (Get-VM $using:vmname).Status }) -eq "Merging disks") { Start-Sleep -seconds 1 }
        }
        catch {
            Write-Error "Failed to Stop VM and take a checkpoint. "
            if ($tries -le $retryTimes)
            {
                Write-Warning "Failed to stop and take a checkpoint. Trying the remove again. $tries tries out of $retryTimes"
                Remove-HyperVVM -VMHostName $VMHostName -VMName $VMName -HyperVAdminCredentialsPath $HyperVAdminCredentialsPath
            }
            throw
        }    

        # Start-Sleep -seconds 5 # make sure that the checkpoint really has finished
        try {
            Write-Verbose "$(Get-Date -Format u) Deleting hard disk files"
            Invoke-Command -Session $VMHostSession { Get-VM $using:VMName | Get-VMHardDiskDrive | ForEach-Object { Remove-item -Path $_.Path -Force } }
        }
        catch
        {
            # ignore
        }
    
        Write-Verbose "$(Get-Date -Format u) Deleting VM $VMName"
        Invoke-Command -Session $VMHostSession { Remove-VM $using:VMName -Confirm:$false -Force }    
    }
    else
    {
        write-warning "$VMName not found on $VMHostName."
    }
}
}
