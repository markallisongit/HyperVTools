Function Disable-Firewall 
{
    [CmdletBinding()]
    param (
        [string]$IpAddress, 
        [System.Management.Automation.PSCredential]$Credential, 
        [bool]$Version2012OrLater
    )
    if($Version2012OrLater) {
        Invoke-Command -ComputerName $IpAddress -Credential $Credential {Set-NetFirewallProfile -Profile Domain -Enabled False}
    } else {
        Invoke-Command -ComputerName $IpAddress -Credential $Credential { & netsh advfirewall set domainprofile state off }
    }
}