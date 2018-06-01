Function New-HyperVVM
{
<#
.SYNOPSIS 
New-HyperVVM creates a new Hyper-V VM to a standard build defined in this set of tools. 

.DESCRIPTION
Creates a new Hyper-V virtual machine with a standard configuration which is defined in this module. As there are many configuration options that can be given for a VM, these must be specified in a JSON file and passed to the New-HyperVVM function to build the VM.

.PARAMETER ConfigFilePath
The path to the JSON configuration file with a set of options for the VM build.

.PARAMETER AdministratorPassword
[securestring] 
The password of the local administrator account for the image. This is required for login before domain join.

.PARAMETER DomainJoinPassword
[securestring] 
If joining to the domain, this is the password for the account with domain join privileges. If blank, an attempt to join to the domain will not be attempted.

.PARAMETER Verbose
Shows details of the build, if omitted minimal information is output.

.NOTES
Author: Mark Allison

Requires: 
    Admin rights on the Hyper-V host.
    Sysprepped Golden images for the operating systems you want to build.
    Admin passwords for the golden images.

The golden images should be created without any configuration and allow the PowerShell module to perform any configuration. The golden images should be sysprepped with product key applied and an unattend file placed inside.



This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE   
New-HyperVVM -ConfigFile \\FILESERVER\VMConfigs\MyVMConfig.json -Verbose

Creates a new VM with the configuration specified in file \\FILESERVER\VMConfigs\MyVMConfig.json with Verbose output.
#>
[cmdletbinding()] 
param 
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$ConfigFilePath,
    [Parameter(Position = 1, Mandatory = $true)]
    [securestring]$AdministratorPassword,
    [Parameter(Position = 2, Mandatory = $false)]
    [securestring]$DomainJoinPassword
)


PROCESS
{
    try {
        Write-Verbose "Determining if PowerShell is running as an Admin." 
        if(! (Test-PSUserIsAdmin))
        {
            throw "This script must be run as Administrator"
        }
        # check for xHyper-V module, and install if missing   
        Install-DscResourceModule "xHyper-V"
        
        $workingdir = Split-Path $script:MyInvocation.MyCommand.Path -Parent 
        Write-Verbose "Working directory: $workingdir"

        $CommonConfigFilePath = (Split-Path $ConfigFilePath ) + "\Common-Config.json"
        Write-Verbose "Reading common config file from $CommonConfigFilePath"        
        $CommonConfig = Get-Content $CommonConfigFilePath | ConvertFrom-Json 

        Write-Verbose "Reading $ConfigFilePath config file"
        $Config = Get-Content $ConfigFilePath | ConvertFrom-Json 

        Write-Verbose "Configuring config variables"
        [string[]]$variables = ($Config | get-member -Name * -MemberType NoteProperty).Name
        foreach ($v in $variables)
        {
            Set-Variable -name $v -value ($Config.$v) -Force -Verbose 
        }
        [string[]]$variables = ($CommonConfig | get-member -Name * -MemberType NoteProperty).Name
        foreach ($v in $variables)
        {
            if(-not (Test-Path variable:$v))
            {
                Set-Variable -name $v -value ($CommonConfig.$v) -Force -Verbose:$verbose 
            }
        }
        
        # Write-Verbose "Validating attributes in config files"
        # Test-Configuration $variables

        $GoldenImageAdminCredential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Administrator', $AdministratorPassword)
        $DomainJoinCred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DomainJoinAccount, $DomainJoinPassword)

        Write-Verbose "Creating session to Hyper-V host $VMHostName"
        $VMHostSession = New-PSSession -ComputerName $VMHostName -Name "VMHostSession"     # create an admin session to the VMHost
        
        Write-Verbose "Checking to see if $VMName already exists on $VMHostName"
        if(Test-HyperVVM $VMHostName $VMName)
        {
            throw "VM $VMName already exists on host $VMHostName. Choose a different name."
        }

        Write-Verbose "Copying image file from $VMTemplatePath to $VHDPath"
        if(Test-Path "TargetSystemImage:\$VMName-System.vhdx")
        {
            throw "$TargetPath\$VMName-System.vhdx already exists"
        }

        Invoke-Command -Session $VMHostSession -scriptblock {
            $FileName = $using:VMTemplatePath | Split-Path -leaf    
            & robocopy ($using:VMTemplatePath | Split-Path) $using:VHDPath $FileName /NFL /NDL /NJH /NJS /nc /ns /np
            Rename-Item -Path "$using:VHDPath\$FileName" -NewName $using:VMName-System.vhdx
        }
    
        $WaitForIp=$false
        if($Generation -eq 2) { $WaitForIp = $true }

        Write-Verbose "WaitforIp: $WaitForIp"
        Write-Verbose "Generation: $Generation"

        CreateBaseVM `
            -VMHostName $VMHostName `
            -VMName $VMName `
            -VMTemplatePath $VMTemplatePath `
            -ProcessorCount $ProcessorCount `
            -StartupMemory $StartupMemory `
            -MinimumMemory $MinimumMemory `
            -MaximumMemory $MaximumMemory `
            -SwitchName $SwitchName `
            -VHDPath $VHDPath `
            -Generation $Generation `
            -WaitForIp:$WaitForIp `
            -State "Off" `
            -Verbose:$verbose
        Start-DscConfiguration -Wait -Verbose -Path .\CreateBaseVM\ -Force

        if($DataVHDMaxSize -and $DataVHDPath)
        {
            Write-Verbose "Creating drive for data at $DataVHDPath, maxsize $DataVHDMaxSize"
            $VHDName = "$VMName-Data"
            NewVHD -VMHostName $VMHostName -Name $VHDName -Path $DataVHDPath -MaximumSize ($DataVHDMaxSize/[uint64]1)
            Start-DscConfiguration -Wait -Verbose -Path .\NewVHD\ -Force            

            if($DataVHDPath)
            {
                $DataVHDFilePath = "$DataVHDPath\$VMName-Data.vhdx"
            } else {
                $DataVHDFilePath = "$VHDPath\$VMName-Data.vhdx"
            }
            Write-Verbose "Attaching drive to VM"
            Invoke-Command -Session $VMHostSession { Add-VMHardDiskDrive -VMName $using:VMName -Path $using:DataVHDFilePath }
        }

        Invoke-Command -Session $VMHostSession -ScriptBlock { Start-VM -Name $using:VMName }
        if ((get-service winrm).Status -ne 'Running') {
            Start-Service WinRM
        }
        $TrustedHosts = Get-Item -Path WSMan:\localhost\Client\TrustedHosts -Force | Select-Object -ExpandProperty Value

        if($IpAddress)
        {
            Set-TrustedHosts $IpAddress.ToString()
            Write-Verbose "Added $IpAddress to TrustedHosts"
        }

        if(! (Test-VMNetworkConfiguration $IpAddress $DefaultGateway $DNSServers))
        {
            throw "IpAddress: $IpAddress; DefaultGateway: $DefaultGateway; DNS Server Count: $($DNSServers.Count). All or none must be set."
        }

        Write-Verbose "Waiting for initial boot and DHCP to provide an IP Address"
        $TempIpAddress = Wait-ForIp $VMHostSession $VMName $Generation
        
        Write-Verbose "DHCP IP Address is $TempIpAddress"

        Set-TrustedHosts $TempIpAddress.ToString()
        Write-Verbose "Added $TempIpAddress, $MachineName to TrustedHosts"

        Write-Verbose "Waiting for WinRM..."
        while ((Invoke-Command -ComputerName $TempIpAddress -Credential $GoldenImageAdminCredential {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}    

        Write-Verbose "Removing old account from AD"
        Remove-AccountFromAD $MachineName $DomainJoinCred

        Write-Verbose "IpAddress : $IpAddress"
        if($IpAddress)
        {
            Initialize-Network $TempIpAddress $IpAddress $DefaultGateway $DNSServers $GoldenImageAdminCredential
        }
        else {
            $IpAddress = $TempIpAddress
        }

        Write-Verbose "Enable ping on all profiles"
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCredential -ScriptBlock {Set-NetFirewallRule -name FPS-ICMP4-ERQ-In -Enabled True}        

        Write-Verbose "Disabling firewall for Domains"
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCredential {Set-NetFirewallProfile -Profile Domain -Enabled False}

        Write-Verbose "Renaming computer to $MachineName"
        Rename-Machine $MachineName $IpAddress $GoldenImageAdminCredential

        if (-not ([string]::IsNullOrEmpty($DomainJoinPassword))) {
            $FullOU = "$OU,dc=" + $domain.Replace(".",",dc=")
            Write-Verbose "Joining $MachineName to domain $domain in ou $FullOU"
            Join-Domain $IpAddress $Domain $FullOU $DomainJoinCred $GoldenImageAdminCredential
        }
      
        Write-Verbose "Create admin session to $MachineName"
        $VMGuestSession = New-PSSession -ComputerName $MachineName -Credential $DomainJoinCred

        Write-Verbose "Configuring VM $MachineName"
        ServerConfig -MachineName $MachineName -IsCore $IsCore -SNMPManager $SNMPManager -SNMPCommunity $SNMPCommunity
        Start-DscConfiguration -Wait -Verbose -Path .\ServerConfig\ -Force -Credential $DomainJoinCred            

        if($DataVHDMaxSize)
        {
            Write-Verbose "Formatting data drive and making ready for first use"
            Invoke-Command -Session $VMGuestSession { 
                Get-Disk | 
                Where-Object PartitionStyle -eq 'RAW' | 
                Initialize-Disk -PartitionStyle GPT -PassThru | 
                New-Partition -AssignDriveLetter -UseMaximumSize | 
                Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -confirm:$false }
        }
        
        if ($InstallChocolatey -eq "Y")
        {
            invoke-command -Session $VMGuestSession { Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression }

            foreach ($package in $ChocolateyPackages)
            {
                Install-ChocolateyPackage $package $VMGuestSession              
            }
            
            # create scheduled task to start BgInfo - will do in DSC one day
            if ($ChocolateyPackages -contains "bginfo" -and $IsCore -eq "N")
            {
                Write-Verbose "Copying bginfo config to VM"
                Copy-Item -Path "$workingdir\configs\BGInfoConfig.bgi" -Destination "\\$MachineName\c$\ProgramData\chocolatey\lib\bginfo\tools"
                Write-Verbose "Creating BgInfo logon task"
                Invoke-Command -ComputerName $MachineName -ScriptBlock {
                    $libDir = "$env:ProgramData\chocolatey\lib\bginfo\tools"                    
                    $action = New-ScheduledTaskAction -Execute "$libDir\bginfo.exe" -Argument "$libDir\BGInfoConfig.bgi /TIMER:0 /silent /accepteula" -WorkingDirectory $libDir;
                    $trigger =  New-ScheduledTaskTrigger -AtLogOn;
                    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'BgInfo' -Description 'Paint bginfo'

                }
            }              
        }

        Write-Verbose "Empty Recycle bin"
        invoke-command -Session $VMGuestSession {Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue }

        Write-Verbose "Shutting down so we can take a checkpoint"
        Stop-Computer -ComputerName $MachineName -Confirm:$false -Credential $DomainJoinCred
        do {
            Start-Sleep -Seconds 1
        } until ((Invoke-Command -Session $VMHostSession { (Get-VM -Name $using:VMName).State }).Value -eq "Off")

        if ($DisableTimeSynchronization -eq "Y")
        {
            Write-Verbose "Disable Time Synchronization"
            Invoke-Command -Session $VMHostSession { Disable-VMIntegrationService -Name "Time Synchronization" -VMName $using:VMName }
        }
    
        Write-Verbose "Taking a Checkpoint"
        invoke-command -ComputerName $VMHostName { Get-VM $using:VMName | Checkpoint-VM -SnapshotName "Initial checkpoint after auto-build" }
        
        if($RunState -ne "Off") 
        {        
            Write-Verbose "Setting run state to $Runstate"
            
            Invoke-Command -Session $VMHostSession { 
                if ((Get-VM -Name $using:VMName).State -ne "Running")
                {
                    Write-Verbose "Starting VM $using:VMName..."
                    Start-VM -Name $using:VMName
                }
            }

            # wait for WinRM                
            while ((Invoke-Command -ComputerName $MachineName {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}       
            
            if ($Runstate -eq "Saved") {
                Invoke-Command -Session $VMHostSession { Save-VM -Name $using:VMName }
            } 
            if($Runstate -eq "Paused") {
                Invoke-Command -Session $VMHostSession { Suspend-VM -Name $using:VMName }
            }
        }
    }
    catch {
        Write-Verbose "Error: $?"
    <#
        TODO
        check if VM was created
        if not, check disk files
        if exist, delete them
        #>
        if(Get-PSDrive -Name TargetSystemImage -ErrorAction SilentlyContinue) 
        {
            Remove-PSDrive -Name TargetSystemImage
        }        
        throw
    }
    finally {
        Write-Verbose "Removing old mof files"
        if (Test-Path ".\CreateBaseVM")
        {
            Write-Verbose "Removing $workingdir\CreateBaseVM"
            Remove-Item -Path ".\CreateBaseVM" -Recurse -Force -Confirm:$false
        }
        if (Test-Path ".\ServerConfig")
        {
            Write-Verbose "Removing .\ServerConfig"
            Remove-Item -Path ".\ServerConfig" -Recurse -Force -Confirm:$false
        }
        if (Test-Path ".\NewVHD")
        {
            Write-Verbose "Removing .\NewVHD"
            Remove-Item -Path ".\NewVHD" -Recurse -Force -Confirm:$false
        }

        if ($TrustedHosts)
        {
            
            Write-Verbose "Resetting TrustedHosts"
            $TrustedHosts | ForEach-Object {Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $_.ToString() -Force}     

        }
    }
}    
}