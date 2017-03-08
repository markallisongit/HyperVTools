Function Read-CredentialsFromFile 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$CredentialsFilePath
    )
    
    try
    {
        Write-Verbose "Reading credentials from $CredentialsFilePath"
        Import-Clixml $CredentialsFilePath
    }
    catch {
        Write-Error "Could not read credentials from file $CredentialsFilePath"
        throw
    }
}