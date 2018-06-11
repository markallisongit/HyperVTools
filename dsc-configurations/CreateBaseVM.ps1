Configuration CreateBaseVM
{
    param
    (
        [Parameter(Mandatory)]
        [string[]]$VMHostName,

        [Parameter(Mandatory)]
        [string]$VMName,

        [Parameter(Mandatory)]
        [string]$VMTemplatePath,

        [Parameter(Mandatory)] 
        [string]$StartupMemory,

        [Parameter(Mandatory)]
        [string]$MinimumMemory,

        [Parameter(Mandatory)]
        [string]$MaximumMemory,
        
        [Parameter(Mandatory)]
        [String]$SwitchName,

        [Parameter(Mandatory)]
        [Uint32]$ProcessorCount,

        [Parameter(Mandatory)]
        [int]$Generation,

        [Parameter(Mandatory)]
        [string]$Notes,        

        [Parameter(Mandatory=$false)]
        [string]$VHDPath="E:\VHDs",

        [ValidateSet('Off','Paused','Running')]
        [String]$State = 'Running',

        [Switch]$WaitForIP
    )
    $ErrorActionPreference = "Stop"
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -module xHyper-V

    Node $VMHostName
    {
        $NewSystemVHDPath = "$VHDPath\$VMName-System.vhdx"

        # create the VM out of the vhd.
        xVMHyperV CreateBaseVM
        {
            Ensure          = 'Present'
            Name            = $VMName
            VhdPath         = $NewSystemVHDPath
            SwitchName      = $SwitchName
            State           = $State
            Generation      = $Generation
            StartupMemory   = ($StartupMemory/[uint64]1)
            MinimumMemory   = ($MinimumMemory/[uint64]1)
            MaximumMemory   = ($MaximumMemory/[uint64]1)
            ProcessorCount  = $ProcessorCount
            RestartIfNeeded = $true
            WaitForIP       = $WaitForIP 
            Notes           = $Notes
        }
    }
}