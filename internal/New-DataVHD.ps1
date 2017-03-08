Function New-DataVHD
{
     [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string[]]$VMHostName,

        [Parameter(Mandatory)]
        [string[]]$VMName,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$MaximumSize     
    )

    Configuration NewVHD
    {
        param
        (
            [Parameter(Mandatory)]
            [string[]]$VMHostName,
                        
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Path,

            [Parameter(Mandatory)]
            [string]$MaximumSize,

            [ValidateSet("Vhd","Vhdx")]
            [string]$Generation="Vhdx",

            [ValidateSet("Present","Absent")]
            [string]$Ensure = "Present"        
        )

        Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
        Import-DscResource -module xHyper-V

        Node $VMHostName
        {
            xVHD NewVHD
            {
                Ensure           = $Ensure
                Name             = $Name
                Path             = $Path
                Generation       = $Generation
                MaximumSizeBytes = ($MaximumSize/[uint64]1)
            }
        }
    }
    $Name = "$VMName-Data"
    NewVHD -VMHostName $VMHostName -Name $Name -Path $Path -MaximumSize $MaximumSize
    Start-DscConfiguration -Wait -Verbose -Path .\NewVHD\ -Credential $Credential -Force
}
