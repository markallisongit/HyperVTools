Function Install-DscResourceModule
{
    [CmdletBinding()]
    param (
        [string]$ModuleName
    )
    if (! (Get-DscResource -Module $ModuleName)) 
    {
        Write-Verbose "Installing module $ModuleName"
        Find-Module -Includes DscResource -Name $ModuleName | Install-Module -Force # requires elevation
    }
}
