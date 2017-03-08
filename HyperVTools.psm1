# All internal functions privately available within the toolset
foreach ($function in (Get-ChildItem "$PSScriptRoot\internal\*.ps1"))
{
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)	
}

# All exported functions
foreach ($function in (Get-ChildItem "$PSScriptRoot\functions\*.ps1"))
{
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}

# All DSC Configurations
foreach ($configuration in (Get-ChildItem "$PSScriptRoot\dsc-configurations\*.ps1"))
{
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($configuration))), $null, $null)
}