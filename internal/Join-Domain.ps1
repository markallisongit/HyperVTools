Function Join-Domain 
{
    param (
        [string]$IpAddress, 
        [string]$Domain, 
        [string]$ou, 
        [System.Management.Automation.PSCredential]$GoldenImageAdminCred, 
        [System.Management.Automation.Runspaces.PSSession]$Session, 
        [bool]$Version2012OrLater, 
        [string]$VMName
    )        
    if($Version2012OrLater)
    {        
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred -scriptblock {Add-Computer -DomainName $using:domain -OUPath $using:ou -Credential $using:DomainAdminCred }
        Write-Verbose "Rebooting"
        Restart-Computer -ComputerName $IpAddress -Wait -For WinRM -Protocol WSMan -Credential $DomainAdminCred -Force         
    } else {
        <#
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred -scriptblock  {
            $hostname = hostname
            Write-Verbose "Running netdom join /d:$using:domain $MachineName /OU:$ou"
            & netdom join /d:$using:domain $MachineName /OU:$ou
        } #>
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred -scriptblock {Add-Computer -DomainName $using:domain }
        Write-Verbose "Rebooting"
        Invoke-Command -Session $Session { Stop-VM $using:VMName -Passthru | Start-VM }
        Write-Verbose "Waiting for machine to boot up..."
        while ((Invoke-Command -ComputerName $IpAddress  {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}
    }
}