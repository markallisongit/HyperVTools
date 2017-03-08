Function Initialize-Network 
{
    [CmdletBinding()]
    param (
        [string]$TempIpAddress, 
        [string]$IpAddress, 
        [string]$DefaultGateway, 
        [string[]]$DNSServers, 
        [System.Management.Automation.PSCredential]$GoldenImageAdminCred, 
        [bool]$Version2012OrLater
    )

    # Change IP Address (as a job so it can run in background and not hang)
    Write-Verbose "Changing IP Address to static: $IpAddress"
    if($Version2012OrLater) {
        $job = Invoke-Command -ComputerName $TempIpAddress -Credential $GoldenImageAdminCred -ScriptBlock {Get-NetIpAddress | Where-Object {$_.InterfaceAlias -match "Ethernet" -and $_.AddressFamily -eq "IPv4"} | New-NetIPAddress -IPAddress $using:IpAddress -PrefixLength 24 -DefaultGateway $using:DefaultGateway} -AsJob
    } else {
        # we have to do this for servers earlier than 2012
        $job = Invoke-Command -ComputerName $TempIpAddress -Credential $GoldenImageAdminCred -ScriptBlock {
            $wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
            $wmi.EnableStatic($using:IpAddress, "255.255.255.0")
            $wmi.SetGateways($using:DefaultGateway, 1)
            $wmi.SetDNSServerSearchOrder($using:DNSServers)
        } -AsJob
    }

    Write-Verbose "Waiting for IP address change to take effect"
    while ((Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}  

    if($Version2012OrLater) {
        Write-Verbose "Configuring DNS client"
        Invoke-Command -ComputerName $IpAddress -Credential $GoldenImageAdminCred {Get-NetIpAddress | Where-Object {$_.InterfaceAlias -match "Ethernet" -and $_.AddressFamily -eq "IPv4"} | Set-DnsClientServerAddress -ServerAddresses ($using:DNSServers)}
    }
}