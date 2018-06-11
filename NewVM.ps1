[cmdletbinding()] 
param 
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$ConfigFilePath,
    [Parameter(Position = 1, Mandatory = $true)]
    [string]$AdministratorPassword,
    [Parameter(Position = 2, Mandatory = $false)]
    [string]$DomainJoinPassword
)

# wrapper for automation
Import-Module .\HyperVTools.psd1 -Force
New-HyperVVM -ConfigFilePath $ConfigFilePath -AdministratorPassword ($AdministratorPassword | ConvertTo-SecureString -AsPlainText -Force)  -DomainJoinPassword ($DomainJoinPassword | ConvertTo-SecureString -AsPlainText -Force)  -Verbose