Function Initialize-DataDrive 
{
    [CmdletBinding()]
    param (
        [System.Management.Automation.Runspaces.PSSession]$Session, 
        [bool]$Version2012OrLater
    )

    if($Version2012OrLater)
    {
        Invoke-Command -Session $Session { Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -confirm:$false }
    } else {
        Write-Warning "Older version of Windows detected. Data drive will be left raw and unformatted."
        # NOT WORKING - PERMISSIONS ISSUES. do nothing for now, leave the drive raw

        <#
         Invoke-Command -Session $Session -ScriptBlock {
             New-Item -Path C:\Temp -ItemType Directory -Force
                 $DiskPartCommand = @"
select volume 0
remove letter D
select disk 1
attributes disk clear readonly
clean
convert gpt
create partition primary
format quick fs=ntfs label="Data"
assign letter=D
"@;   
            $DiskPartCommand -replace '\n',"`r`n" | Out-File "\\tulip\software\diskpart.txt" -Force 
            Copy-Item "\\tulip\software\diskpart.txt" C:\Temp
            #$user = $using:DomainAdminCred.UserName
            #& icacls C:\Temp /grant $user:F /T

         }          
            # & diskpart /s "$env:appdata\diskpart.txt" > "$env:appdata\diskpart.log"
         #>
        }
    }
