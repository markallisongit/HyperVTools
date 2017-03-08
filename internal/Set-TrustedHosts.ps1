Function Set-TrustedHosts 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$MachineName
    )
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $MachineName -Concatenate -Force
}
