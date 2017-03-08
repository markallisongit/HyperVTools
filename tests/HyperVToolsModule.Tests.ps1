$here = Split-Path $MyInvocation.MyCommand.Path
$module = 'HyperVTools'
Get-Module HyperVTools | Remove-Module -Force
Import-Module .\HyperVTools.psd1 -Force
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests\.', '.'

Describe "$module tests" -Tags 'General' {
    <#
    Context 'Validate inputs' {
        It 'has no config file passed' {
            Mock .\New-HyperVVM.ps1 { throw ParamterArgumentValidationError }
            .\New-HyperVVM.ps1 | Should Throw
        }
    }
#>
    $functionsDirectory = "functions"
    $testsDirectory = "tests"

    Context "Validate Module $module" {
        It "the $module module $module.psm1 exists" {
            "$module.psm1" | Should Exist
        }

        It "the HyperVTools module manifest $module.psd1 exists" {
            "$module.psd1" | Should Exist
            "$module.psd1" | Should Contain "$module"
        }

        It "the module has functions as separate files in the $functionsDirectory directory" {
            "$functionsDirectory\*.ps1" | Should Exist
        }
    }
    $functions = (
        'New-HyperVVM',
        'Test-HyperVVM',
        'Remove-HyperVVM')


    foreach ($function in $functions)
    {
        Context "Test Function $function" {
            It "$functionsDirectory\$function.ps1 exists" {
                "$functionsDirectory\$function.ps1" | Should Exist
            }
            
            It "$function has a help block" {
                "$functionsDirectory\$function.ps1" | Should Contain '<#'
                "$functionsDirectory\$function.ps1" | Should Contain '.SYNOPSIS'
                "$functionsDirectory\$function.ps1" | Should Contain '.DESCRIPTION'
                "$functionsDirectory\$function.ps1" | Should Contain '.EXAMPLE'
            }

            It "$functionsDirectory\$function.ps1 is a full function" {
                "$functionsDirectory\$function.ps1" | Should Contain 'function'
                "$functionsDirectory\$function.ps1" | Should Contain 'cmdletbinding'
                "$functionsDirectory\$function.ps1" | Should Contain 'param'
            }
        }
<#
        Context "$function has tests" {
            It "$testsDirectory\$function.Tests.ps1 exists" {
                "$testsDirectory\$function.Tests.ps1" | Should Exist
            }
        }
#>
    }    
}