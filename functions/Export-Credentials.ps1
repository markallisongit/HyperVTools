Function Export-Credentials
{
<#
.SYNOPSIS 
Export-Credentials gets credentials from the user and exports to a secure file.

.DESCRIPTION
Uses Get-Credential to get a credential from the user then writes it to a secure file with Export-CliXml

.PARAMETER ExportPath
The path where the credential should be exported, including file name

.EXAMPLE   
Export-Credentials -ExportPath \\FILESERVER\VMConfigs\HyperVAdminCredentials.xml

Exports credentials to file \\FILESERVER\VMConfigs\HyperVAdminCredentials.xml
#>
[cmdletbinding()] 
param 
(
    [Parameter(Mandatory)]
    [ValidateScript({
        if ($_ -match ".+\.xml\b") {
            $true
        }
        else { 
            throw "-ExportPath needs to be a valid path ending with .xml" }
        }
    )]
    [string]$ExportPath
)

PROCESS
{

    Get-Credential | Export-Clixml -Path $ExportPath -Force
    Write-Output "Credentials exported to $ExportPath"
}
}