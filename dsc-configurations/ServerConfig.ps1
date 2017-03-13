Configuration ServerConfig
{
    param
    (
        [Parameter(Mandatory)]
        [string]$MachineName,
        
        [Parameter(Mandatory)]
        [string]$IsCore,
        
        [string]$SNMPManager,
        [string]$SNMPCommunity        
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $MachineName
    {        
        # Enable Remote Desktop
        Registry RemoteDesktop
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server"
            ValueName = "fDenyTSConnections"
            ValueData = 0
            ValueType = "Dword"
        }

        # Remove Unattend File
        File UnattendFile
        {
            Ensure = "Absent"
            DestinationPath = "C:\Windows\Panther\Unattend\Unattend.xml"  
            Force = $true                      
        }

        if ($SNMPCommunity)
        {            
            WindowsFeature SNMPService
            {
                Ensure = "Present"
                Name = "SNMP-Service"
                IncludeAllSubFeature = $true
            }

            if ($IsCore -eq "N") {
                WindowsFeature SNMPRSAT {
                    Ensure = 'Present'
                    Name = 'RSAT-SNMP'           
                    DependsOn = "[WindowsFeature]SNMPService"
                }
            }

            Registry ConfigureSNMPPermittedManagers
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
                ValueName = "1"
                ValueData = $SNMPManager
                ValueType = "String"
                DependsOn = "[WindowsFeature]SNMPService"
            } 

            Registry ConfigureSNMPValidCommunities
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities"
                ValueName = $SNMPCommunity
                ValueData = 4
                ValueType = "Dword"
                DependsOn = "[WindowsFeature]SNMPService"
            } 
        }
    }
}
