[cmdletbinding()] 
param 
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$ConfigFilePath,
    [Parameter(Position = 1, Mandatory = $true)]
    [securestring]$AdministratorPassword,
    [Parameter(Position = 2, Mandatory = $false)]
    [securestring]$DomainJoinPassword
)

# wrapper for automation
Import-Module .\HyperVTools.psd1 -Force
New-HyperVVM -ConfigFilePath $ConfigFilePath -AdministratorPassword $AdministratorPassword -DomainJoinPassword $DomainJoinPassword -Verbose