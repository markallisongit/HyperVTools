Function Initialize-Network 
{
    [CmdletBinding()]
    param (
        [string]$TempIpAddress, 
        [string]$IpAddress, 
        [string]$DefaultGateway, 
        [string[]]$DNSServers, 
        [System.Management.Automation.PSCredential]$GoldenImageAdminCred
    )

    # Change IP Address (as a job so it can run in background and not hang)
    Write-Verbose "Changing IP Address to static: $IpAddress"
    $job = Invoke-Command -ComputerName $TempIpAddress -Credential $GoldenImageAdminCred -ScriptBlock {Get-NetIpAddress | Where-Object {$_.InterfaceAlias -match "Ethernet" -and $_.AddressFamily -eq "IPv4"} | New-NetIPAddress -IPAddress $using:IpAddress -PrefixLength 24 -DefaultGateway $using:DefaultGateway} -AsJob

    Write-Verbose "Waiting for IP address change to take effect"
    while ((Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}  

    Write-Verbose "Setting DNS Servers"
    Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred {Get-NetIpAddress | Where-Object {$_.InterfaceAlias -match "Ethernet" -and $_.AddressFamily -eq "IPv4"} | Set-DnsClientServerAddress -ServerAddresses ($using:DNSServers)}
}