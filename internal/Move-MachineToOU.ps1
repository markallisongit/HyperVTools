Function Move-MachineToOU 
{
    [CmdletBinding()]
    param (
        [string]$MachineName, 
        [string]$OU, 
        [System.Management.Automation.PSCredential]$Credential
    )

    if((Get-ADComputer $MachineName).DistinguishedName -notmatch $OU)
    {
        Write-Verbose "Moving $MachineName to $OU OU"
        Get-ADComputer $MachineName -Credential $Credential | Move-ADObject -Credential $Credential -TargetPath $OU
    }

}
