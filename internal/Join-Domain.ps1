Function Join-Domain 
{
    param (
        [string]$IpAddress, 
        [string]$Domain, 
        [string]$ou, 
        [System.Management.Automation.PSCredential]$DomainJoinCred,
        [System.Management.Automation.PSCredential]$GoldenImageAdminCred
    )        
     
    Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred -scriptblock { Add-Computer -DomainName $using:domain -OUPath $using:ou -Credential $using:DomainJoinCred }
    Write-Verbose "Rebooting"
    Restart-Computer -ComputerName $IpAddress -Wait -For WinRM -Protocol WSMan -Credential $DomainJoinCred -Force         
    
}