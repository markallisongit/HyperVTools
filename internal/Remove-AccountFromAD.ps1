Function Remove-AccountFromAD 
{
    [CmdletBinding()]
    param (
        [string]$MachineName, 
        [System.Management.Automation.PSCredential]$Credential
    )
    # Remove the computer account if it already exists
    $advm = ""
    try
    {
        $advm = Get-ADComputer -Identity $MachineName -Credential $Credential
    } catch {
        # don't do anything
    }
    if ($advm -ne "")
    {
        Write-Verbose "Removing existing computer account $MachineName from AD"
        Get-ADComputer -Identity $MachineName -Credential $Credential | Remove-ADObject -Recursive -Confirm:$false -Credential $Credential
    }    
}