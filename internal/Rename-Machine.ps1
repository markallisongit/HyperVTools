Function Rename-Machine 
{
    [CmdletBinding()]
    param (
        [string]$MachineName, 
        [string]$IPAddress, 
        [System.Management.Automation.PSCredential]$Credential
    )
    

    Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock { Rename-Computer -NewName $using:MachineName -Force }
    Write-Verbose "Rebooting"
    Restart-Computer -ComputerName $IpAddress -Wait -For WinRM -Protocol WSMan -Credential $Credential -Force        
 
}