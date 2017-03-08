Function Get-WindowsVersion 
{    
    [CmdletBinding()]
    param (
        [string]$IpAddress, 
        [System.Management.Automation.PSCredential]$Credential
    )
    Invoke-Command -ComputerName $IpAddress -Credential $Credential -ScriptBlock { [environment]::OSVersion.Version }
}
