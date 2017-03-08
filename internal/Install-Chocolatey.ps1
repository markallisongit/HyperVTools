Function Install-Chocolatey
{
    [CmdletBinding()]
    param (
        [bool]$Version2012OrLater, 
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    Write-Verbose "Install chocolatey"
    if($Version2012OrLater)
    {
        invoke-command -Session $Session { Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression }
    } else {        
        invoke-command -Session $Session { 
            Set-ExecutionPolicy Unrestricted
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
        }
    }
}