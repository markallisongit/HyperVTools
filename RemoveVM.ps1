[cmdletbinding()] 
param 
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$VMHostName,
    [Parameter(Position = 1, Mandatory = $true)]
    [string]$VMName,
    [Parameter(Position = 2, Mandatory = $false)]
    [[System.Management.Automation.PSCredential]]$Credentials
)

# wrapper for automation
Import-Module .\HyperVTools.psd1 -Force
New-HyperVVM Remove-HyperVVM -VMHostName $VMHostName -VMName $VMName -HyperVAdminCredentials $Credentials