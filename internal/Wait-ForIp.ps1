Function Wait-ForIp
{
    [CmdletBinding()]
    param (
        [System.Management.Automation.Runspaces.PSSession]$Session, 
        [string]$VMName, 
        [int]$Generation    
    )

    Write-Verbose "Waiting for IP Address to come online..."
    while(!([string]$DHCPIpAddress = Get-DHCPIpAddress $Session $VMName $Generation))
    {        
        Start-Sleep -seconds 5
    }
    if($DHCPIpAddress.Split(".")[0] -eq "169")
    {
        Write-Verbose "Waiting for DHCP Server to provide address. AutoConfig Address is currently $DHCPIpAddress"
    }
    while((([string]$DHCPIpAddress = Get-DHCPIpAddress $Session $VMName $Generation).Split(".")[0]) -ne "10")
    {
        Start-Sleep -Seconds 1
    }
    $DHCPIpAddress
}