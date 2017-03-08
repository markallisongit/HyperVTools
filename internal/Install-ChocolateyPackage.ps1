Function Install-ChocolateyPackage 
{
    [CmdletBinding()]
    param (
        [string]$package, 
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    # need some validation!


    Write-Verbose "Installing chocolatey package $package"
    invoke-command -Session $Session { & choco install $using:package -y }
}