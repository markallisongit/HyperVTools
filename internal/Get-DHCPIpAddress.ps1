Function Get-DHCPIpAddress
{
    [CmdletBinding()]
    param (
        [System.Management.Automation.Runspaces.PSSession]$Session, 
        [string]$VMName, 
        [int]$Generation    
    )
    
    if($Generation -eq 2) {
        # this command is only supported from 2012 onwards
        Invoke-Command -Session $Session -ScriptBlock {
            $IpAddress = Get-VM -Name $using:VMName | Get-VMNetworkAdapter | Select-Object -ExpandProperty IpAddresses
            if($IpAddress -is [System.Array])
            {
                $IpAddress[0] # get the first address in the array
            }
            else
            {
                $IpAddress
            }
        }
    }
    else {
        # this is for Windows 2008 R2 and earlier (only tested on 2008 R2)
        Invoke-Command -Session $Session -ScriptBlock {            
            $Vm = Get-WmiObject -Namespace root\virtualization\v2 -Query "Select * From Msvm_ComputerSystem Where ElementName='$using:VMName'"
            
            if($vm.GetRelated("Msvm_KvpExchangeComponent").GuestIntrinsicExchangeItems)
            {
                $vm.GetRelated("Msvm_KvpExchangeComponent").GuestIntrinsicExchangeItems | % { ` 
                    $GuestExchangeItemXml = ([XML]$_).SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text()='NetworkAddressIPv4']")
                    
                    if ($GuestExchangeItemXml -ne $null) 
                    { 
                        [string]$GuestExchangeItemXml.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value
                    }    
                }
            }                       
        }
    }
}