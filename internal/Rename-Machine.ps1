Function Rename-Machine 
{
    [CmdletBinding()]
    param (
        [string]$MachineName, 
        [string]$IPAddress, 
        [System.Management.Automation.PSCredential]$Credential, 
        [System.Management.Automation.Runspaces.PSSession]$Session, 
        [bool]$Version2012OrLater, 
        [string]$VMName
    )
    
    if($Version2012OrLater) {
        Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock { Rename-Computer -NewName $using:MachineName -Force }
        Write-Verbose "Rebooting"
        Restart-Computer -ComputerName $IpAddress -Wait -For WinRM -Protocol WSMan -Credential $Credential -Force        
    } else {        
        Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock { 
            $hostname = hostname
            & netdom renamecomputer $hostname /NewName:$using:MachineName /Force 
        }
        Write-Verbose "Rebooting"
        Invoke-Command -Session $Session { Stop-VM $using:VMName -Passthru | Start-VM }
        #Write-Verbose "Waiting for machine to shutdown..."
        #while ((Invoke-Command -ComputerName $IPAddress -Credential $GoldenImageAdminCred {"Test"} -ErrorAction SilentlyContinue) -eq "Test") {Start-Sleep -Seconds 1}
        Write-Verbose "Waiting for machine to boot up..."
        while ((Invoke-Command -ComputerName $IPAddress -Credential $Credential {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}
    }  
}