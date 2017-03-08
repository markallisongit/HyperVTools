Function Test-VMNetworkConfiguration 
{
    [CmdletBinding()]
    param (
        [string]$IpAddress, 
        [string]$DefaultGateway, 
        [string[]]$DNSServers
    )

    $configuredCorrectly = $false
    # make sure optional params are set correctly
    if ($IpAddress -or $DefaultGateway -or ($DNSServers.Count -gt 0)) # at least one of these has been set
    {
        if ($IpAddress -and $DefaultGateway -and ($DNSServers.Count -gt 0)) # if one is set they must all be set
        {
            $configuredCorrectly = $true
        }
    }
    else {
        Write-Verbose "DHCP will be used. Static IP was not specified."
        $configuredCorrectly = $true
    }
    $configuredCorrectly
}