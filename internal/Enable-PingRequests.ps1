Function Enable-PingRequests 
{
    [CmdletBinding()]
    param (
        [string]$IpAddress, 
        [System.Management.Automation.PSCredential]$Credential, 
        [bool]$Version2012OrLater
    )
    if($Version2012OrLater) {
        Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock {Set-NetFirewallRule -name FPS-ICMP4-ERQ-In -Enabled True}
    } else {
        Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock { & netsh firewall set icmpsetting 8 enable }
    }
}