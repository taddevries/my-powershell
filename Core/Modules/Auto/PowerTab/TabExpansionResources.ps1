
Data Resources {
@{
    ## Default resources
    setup_wizard_caption = "Launch the setup wizard to create a PowerTab configuration file and database?"
    setup_wizard_message = "PowerTab can be setup manually without the setup wizard."
    setup_wizard_choice_profile_directory = "&Profile Directory"
    setup_wizard_choice_install_directory = "&Installation Directory"
    setup_wizard_choice_appdata_directory = "&Application Data Directory"
    setup_wizard_choice_isostorage_directory = "Isolated &Storage"
    setup_wizard_choice_other_directory = "&Other Directory"
    setup_wizard_config_location_caption = "Where should the PowerTab configuration file and database be saved?"
    setup_wizard_config_location_message = "Any existing PowerTab configuration will be overwritten."
    setup_wizard_other_directory_prompt = "Enter the directory path for storing the PowerTab configuration file and database"
    setup_wizard_err_path_not_valid = "The given path's format is not supported."
    setup_wizard_add_to_profile = "Add the following text to the PowerShell profile to launch PowerTab with the saved configuration."
    setup_wizard_upgrade_existing_database_caption = "Upgrade existing tab completion database?"
    setup_wizard_upgrade_existing_database_message = "An existing tab completion database has been detected."
    update_tabexpansiondatabase_type_conf_caption = "Update .NET type list in tab completion database from currently loaded types?"
    update_tabexpansiondatabase_type_conf_inquire = "Loading .NET types."
    update_tabexpansiondatabase_type_conf_description = "Loading .NET types."
    update_tabexpansiondatabase_wmi_conf_caption = "Update WMI class list in tab completion database?"
    update_tabexpansiondatabase_wmi_conf_inquire = "Loading WMI classes."
    update_tabexpansiondatabase_wmi_conf_description = "Loading WMI classes."
    update_tabexpansiondatabase_wmi_activity = "Adding WMI Classes"
    update_tabexpansiondatabase_com_conf_caption = "Update COM class list in tab completion database?"
    update_tabexpansiondatabase_com_conf_inquire = "Loading COM classes."
    update_tabexpansiondatabase_com_conf_description = "Loading COM classes."
    update_tabexpansiondatabase_com_activity = "Adding COM Classes"
    update_tabexpansiondatabase_computer_conf_caption = "Update computer list in tab completion database from 'net view'?"
    update_tabexpansiondatabase_computer_conf_inquire = "Loading computer names."
    update_tabexpansiondatabase_computer_conf_description = "Loading computer names."
    update_tabexpansiondatabase_computer_activity = "Adding computer names"
    import_tabexpansiondatabase_ver_success = "TabExpansion database imported from '{0}'"
    export_tabexpansiondatabase_ver_success = "TabExpansion database exported to '{0}'"
    import_tabexpansionconfig_ver_success = "Configuration imported from '{0}'"
    export_tabexpansionconfig_ver_success = "Configuration exported to '{0}'"
    invoke_tabactivityindicator_prog_status = "PowerTab is retrieving or displaying available tab expansion options."
    global_choice_yes = "&Yes"
    global_choice_no = "&No"
}
}

$ResourceFiles = @(
        @{"FileName"="Resources";"Variable"="Resources";"Cultures"=@("en-US")}
    )


############

Function Update-Resource {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $FileName
        ,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $Variable
        ,
        [Parameter(Position = 2, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Globalization.CultureInfo[]]
        $Cultures
    )

    process {
        [System.Globalization.CultureInfo]$ControlCulture = "en"
        $ResourceCollection = @{}
        $BaseResources = (Get-Variable $Variable).Value
        $BaseKeys = $BaseResources.Keys.GetEnumerator() | Sort-Object

        ## Update control resources
        [String[]]$ModifiedKeys = @()
        [Bool]$Modified = $false
        $ControlResources = Import-Resources $ControlCulture -FileName $FileName
        $ControlKeys = $ControlResources.Keys.GetEnumerator() | Sort-Object
        Compare-Object $BaseKeys $ControlKeys -IncludeEqual | ForEach-Object {
            $Key = $_.InputObject
            switch -exact ($_.SideIndicator) {
                '<=' {
                    ## This key is new since last update, add to control
                    $ControlResources[$Key] = $BaseResources[$Key]
                    $Modified = $true
                    Write-Host "A new key has been identified: $Key"  # TODO: Improve message
                }
                '=>' {
                    ## This key was removed since last update, remove from control
                    $ControlResources.Remove($Key)
                    $Modified = $true
                    Write-Host "A key has been removed: $Key"  # TODO: Improve message
                }
                '==' {
                    ## Key still here, check if value has changed
                    if ($BaseResources[$Key] -cne $ControlResources[$Key]) {
                        ## Value changed, add key to changed list and update control
                        $ModifiedKeys += $Key
                        $ControlResources[$Key] = $BaseResources[$Key]
                        $Modified = $true
                        Write-Host "The value for key '$Key' has been modified."  # TODO: Improve message
                    }
                }
            }
        }
        if ($Modified) {
            Export-Resources $ControlCulture $ControlResources -FileName $FileName
        }

        ## Update localized languages
        foreach ($Culture in $Cultures) {
            $Modified = $false
            $CultureResources = Import-Resources $Culture -FileName $FileName
            $CultureKeys = $CultureResources.Keys.GetEnumerator() | Sort-Object
            Compare-Object $BaseKeys $CultureKeys -IncludeEqual | ForEach-Object {
                $Key = $_.InputObject
                switch -exact ($_.SideIndicator) {
                    '<=' {
                        ## This key is new since last update, add to culture
                        $CultureResources[$Key] = $BaseResources[$Key]
                        $Modified = $true
                        Write-Host "Adding key '$Key' to '$($Culture.Name)'"  # TODO: Improve message
                        Write-Verbose "  Value: '$($BaseResources[$Key])'"
                    }
                    '=>' {
                        ## This key was removed since last update, remove from culture
                        $CultureResources.Remove($Key)
                        $Modified = $true
                        Write-Host "Removing key '$Key' from '$($Culture.Name)'"  # TODO: Improve message
                    }
                    '==' {
                        ## Key still here, check if value has changed
                        if ($ModifiedKeys -contains $Key) {
                            ## Value changed, add key to changed list and update culture
                            Write-Host "Key '$Key' has changed, updating value in '$($Culture.Name)' from base resources"  # TODO: Improve message
                            Write-Verbose "  Old value: '$($CultureResources[$Key])'"
                            Write-Verbose "  New value: '$($BaseResources[$Key])'"
                            $CultureResources[$Key] = $BaseResources[$Key]
                            $Modified = $true
                        }
                    }
                }
            }

            ## Update culture resources
            if ($Modified) {
                Export-Resources $Culture $CultureResources -FileName $FileName
            }
        }
    }
}


Function Import-Resources {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Globalization.CultureInfo]
        $Culture
        ,
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName = "Resources"
    )

    process {
        if (Test-Path "$PSScriptRoot\$($Culture.Name)\$FileName.psd1") {
            Import-LocalizedData -BindingVariable "TempResources" -FileName $FileName -UICulture $Culture -ErrorAction SilentlyContinue
            $TempResources
        } else {
            @{}
        }

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}


Function Export-Resources {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [System.Globalization.CultureInfo]
        $Culture
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        $Resources
        ,
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName = "Resources"
    )

    process {
        $Contents = "`@{`n    ## $($Culture.Name)`r`n"
        foreach ($Key in ($Resources.Keys | Sort-Object)) {
            $Contents += "    {0} = `"{1}`"`r`n" -f $Key,$Resources[$Key]
        }
        $Contents += "}"
        
        Set-Content -Path "$PSScriptRoot\$($Culture.Name)\$FileName.psd1" -Value $Contents

        trap [System.Management.Automation.PipelineStoppedException] {
            ## Pipeline was stopped
            break
        }
    }
}

<#
$mod = (get-module -All PowerTab)[0]
& $mod Update-Resources -verbose
#>


$ResourceFiles | ForEach-Object {Update-Resource @_}
# SIG # Begin signature block
# MIIbaQYJKoZIhvcNAQcCoIIbWjCCG1YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7zvfcsDUywRtPpmb9J3i/P0q
# kQygghYbMIIDnzCCAoegAwIBAgIQeaKlhfnRFUIT2bg+9raN7TANBgkqhkiG9w0B
# AQUFADBTMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xKzAp
# BgNVBAMTIlZlcmlTaWduIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EwHhcNMTIw
# NTAxMDAwMDAwWhcNMTIxMjMxMjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UE
# ChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUg
# U3RhbXBpbmcgU2VydmljZXMgU2lnbmVyIC0gRzMwgZ8wDQYJKoZIhvcNAQEBBQAD
# gY0AMIGJAoGBAKlZZnTaPYp9etj89YBEe/5HahRVTlBHC+zT7c72OPdPabmx8LZ4
# ggqMdhZn4gKttw2livYD/GbT/AgtzLVzWXuJ3DNuZlpeUje0YtGSWTUUi0WsWbJN
# JKKYlGhCcp86aOJri54iLfSYTprGr7PkoKs8KL8j4ddypPIQU2eud69RAgMBAAGj
# geMwgeAwDAYDVR0TAQH/BAIwADAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3Js
# LnZlcmlzaWduLmNvbS90c3MtY2EuY3JsMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AudmVyaXNp
# Z24uY29tMA4GA1UdDwEB/wQEAwIHgDAeBgNVHREEFzAVpBMwETEPMA0GA1UEAxMG
# VFNBMS0zMB0GA1UdDgQWBBS0t/GJSSZg52Xqc67c0zjNv1eSbzANBgkqhkiG9w0B
# AQUFAAOCAQEAHpiqJ7d4tQi1yXJtt9/ADpimNcSIydL2bfFLGvvV+S2ZAJ7R55uL
# 4T+9OYAMZs0HvFyYVKaUuhDRTour9W9lzGcJooB8UugOA9ZresYFGOzIrEJ8Byyn
# PQhm3ADt/ZQdc/JymJOxEdaP747qrPSWUQzQjd8xUk9er32nSnXmTs4rnykr589d
# nwN+bid7I61iKWavkugszr2cf9zNFzxDwgk/dUXHnuTXYH+XxuSqx2n1/M10rCyw
# SMFQTnBWHrU1046+se2svf4M7IV91buFZkQZXZ+T64K6Y57TfGH/yBvZI1h/MKNm
# oTkmXpLDPMs3Mvr1o43c1bCj6SU2VdeB+jCCA8QwggMtoAMCAQICEEe/GZXfjVJG
# Q/fbbUgNMaQwDQYJKoZIhvcNAQEFBQAwgYsxCzAJBgNVBAYTAlpBMRUwEwYDVQQI
# EwxXZXN0ZXJuIENhcGUxFDASBgNVBAcTC0R1cmJhbnZpbGxlMQ8wDQYDVQQKEwZU
# aGF3dGUxHTAbBgNVBAsTFFRoYXd0ZSBDZXJ0aWZpY2F0aW9uMR8wHQYDVQQDExZU
# aGF3dGUgVGltZXN0YW1waW5nIENBMB4XDTAzMTIwNDAwMDAwMFoXDTEzMTIwMzIz
# NTk1OVowUzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMSsw
# KQYDVQQDEyJWZXJpU2lnbiBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqcqypMzNIK8KfYmsh3XwtE7x38EP
# v2dhvaNkHNq7+cozq4QwiVh+jNtr3TaeD7/R7Hjyd6Z+bzy/k68Numj0bJTKvVIt
# q0g99bbVXV8bAp/6L2sepPejmqYayALhf0xS4w5g7EAcfrkN3j/HtN+HvV96ajEu
# A5mBE6hHIM4xcw1XLc14NDOVEpkSud5oL6rm48KKjCrDiyGHZr2DWFdvdb88qiaH
# XcoQFTyfhOpUwQpuxP7FSt25BxGXInzbPifRHnjsnzHJ8eYiGdvEs0dDmhpfoB6Q
# 5F717nzxfatiAY/1TQve0CJWqJXNroh2ru66DfPkTdmg+2igrhQ7s4fBuwIDAQAB
# o4HbMIHYMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# dmVyaXNpZ24uY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAwQQYDVR0fBDowODA2oDSg
# MoYwaHR0cDovL2NybC52ZXJpc2lnbi5jb20vVGhhd3RlVGltZXN0YW1waW5nQ0Eu
# Y3JsMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIBBjAkBgNVHREE
# HTAbpBkwFzEVMBMGA1UEAxMMVFNBMjA0OC0xLTUzMA0GCSqGSIb3DQEBBQUAA4GB
# AEpr+epYwkQcMYl5mSuWv4KsAdYcTM2wilhu3wgpo17IypMT5wRSDe9HJy8AOLDk
# yZNOmtQiYhX3PzchT3AxgPGLOIez6OiXAP7PVZZOJNKpJ056rrdhQfMqzufJ2V7d
# uyuFPrWdtdnhV/++tMV+9c8MnvCX/ivTO1IbGzgn9z9KMIIGcDCCBFigAwIBAgIB
# JDANBgkqhkiG9w0BAQUFADB9MQswCQYDVQQGEwJJTDEWMBQGA1UEChMNU3RhcnRD
# b20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERpZ2l0YWwgQ2VydGlmaWNhdGUgU2ln
# bmluZzEpMCcGA1UEAxMgU3RhcnRDb20gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkw
# HhcNMDcxMDI0MjIwMTQ2WhcNMTcxMDI0MjIwMTQ2WjCBjDELMAkGA1UEBhMCSUwx
# FjAUBgNVBAoTDVN0YXJ0Q29tIEx0ZC4xKzApBgNVBAsTIlNlY3VyZSBEaWdpdGFs
# IENlcnRpZmljYXRlIFNpZ25pbmcxODA2BgNVBAMTL1N0YXJ0Q29tIENsYXNzIDIg
# UHJpbWFyeSBJbnRlcm1lZGlhdGUgT2JqZWN0IENBMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEAyiOLIjUemqAbPJ1J0D8MlzgWKbr4fYlbRVjvhHDtfhFN
# 6RQxq0PjTQxRgWzwFQNKJCdU5ftKoM5N4YSjId6ZNavcSa6/McVnhDAQm+8H3HWo
# D030NVOxbjgD/Ih3HaV3/z9159nnvyxQEckRZfpJB2Kfk6aHqW3JnSvRe+XVZSuf
# DVCe/vtxGSEwKCaNrsLc9pboUoYIC3oyzWoUTZ65+c0H4paR8c8eK/mC914mBo6N
# 0dQ512/bkSdaeY9YaQpGtW/h/W/FkbQRT3sCpttLVlIjnkuY4r9+zvqhToPjxcfD
# YEf+XD8VGkAqle8Aa8hQ+M1qGdQjAye8OzbVuUOw7wIDAQABo4IB6TCCAeUwDwYD
# VR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFNBOD0CZbLhL
# GW87KLjg44gHNKq3MB8GA1UdIwQYMBaAFE4L7xqkQFulF2mHMMo0aEPQQa7yMD0G
# CCsGAQUFBwEBBDEwLzAtBggrBgEFBQcwAoYhaHR0cDovL3d3dy5zdGFydHNzbC5j
# b20vc2ZzY2EuY3J0MFsGA1UdHwRUMFIwJ6AloCOGIWh0dHA6Ly93d3cuc3RhcnRz
# c2wuY29tL3Nmc2NhLmNybDAnoCWgI4YhaHR0cDovL2NybC5zdGFydHNzbC5jb20v
# c2ZzY2EuY3JsMIGABgNVHSAEeTB3MHUGCysGAQQBgbU3AQIBMGYwLgYIKwYBBQUH
# AgEWImh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL3BvbGljeS5wZGYwNAYIKwYBBQUH
# AgEWKGh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL2ludGVybWVkaWF0ZS5wZGYwEQYJ
# YIZIAYb4QgEBBAQDAgABMFAGCWCGSAGG+EIBDQRDFkFTdGFydENvbSBDbGFzcyAy
# IFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVjdCBTaWduaW5nIENlcnRpZmljYXRl
# czANBgkqhkiG9w0BAQUFAAOCAgEAcnMLA3VaN4OIE9l4QT5OEtZy5PByBit3oHiq
# QpgVEQo7DHRsjXD5H/IyTivpMikaaeRxIv95baRd4hoUcMwDj4JIjC3WA9FoNFV3
# 1SMljEZa66G8RQECdMSSufgfDYu1XQ+cUKxhD3EtLGGcFGjjML7EQv2Iol741rEs
# ycXwIXcryxeiMbU2TPi7X3elbwQMc4JFlJ4By9FhBzuZB1DV2sN2irGVbC3G/1+S
# 2doPDjL1CaElwRa/T0qkq2vvPxUgryAoCppUFKViw5yoGYC+z1GaesWWiP1eFKAL
# 0wI7IgSvLzU3y1Vp7vsYaxOVBqZtebFTWRHtXjCsFrrQBngt0d33QbQRI5mwgzEp
# 7XJ9xu5d6RVWM4TPRUsd+DDZpBHm9mszvi9gVFb2ZG7qRRXCSqys4+u/NLBPbXi/
# m/lU00cODQTlC/euwjk9HQtRrXQ/zqsBJS6UJ+eLGw1qOfj+HVBl/ZQpfoLk7IoW
# lRQvRL1s7oirEaqPZUIWY/grXq9r6jDKAp3LZdKQpPOnnogtqlU4f7/kLjEJhrrc
# 98mrOWmVMK/BuFRAfQ5oDUMnVmCzAzLMjKfGcVW/iMew41yfhgKbwpfzm3LBr1Zv
# +pEBgcgW6onRLSAn3XHM0eNtz+AkxH6rRf6B2mYhLEEGLapH8R1AMAo4BbVFOZR5
# kXcMCwowggg4MIIHIKADAgECAgIHqTANBgkqhkiG9w0BAQUFADCBjDELMAkGA1UE
# BhMCSUwxFjAUBgNVBAoTDVN0YXJ0Q29tIEx0ZC4xKzApBgNVBAsTIlNlY3VyZSBE
# aWdpdGFsIENlcnRpZmljYXRlIFNpZ25pbmcxODA2BgNVBAMTL1N0YXJ0Q29tIENs
# YXNzIDIgUHJpbWFyeSBJbnRlcm1lZGlhdGUgT2JqZWN0IENBMB4XDTEyMTAxMDIz
# MzU0OFoXDTE0MTAxMzAwMjE0MFowgY8xGTAXBgNVBA0TEFMzRUM3Yzh4Y1lOMnBQ
# cXUxCzAJBgNVBAYTAlVTMRUwEwYDVQQIEwxTb3V0aCBEYWtvdGExEzARBgNVBAcT
# ClJhcGlkIENpdHkxFDASBgNVBAMTC1RhZCBEZVZyaWVzMSMwIQYJKoZIhvcNAQkB
# FhR0YWRkZXZyaWVzQGdtYWlsLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAKb2chsYUh+l9MhIyQc+TczABVRO4rU3YOwu1t0gybek1d0KacGTtD/C
# SFWutUsrfVHWb2ybUiaTN/+P1ChqtnS4Sq/pyZ/UcBzOUoFEFlIOv5NxTjv7gm2M
# pR6LwgYx2AyfdVYpAfcbmAH0wXfgvA3i6y9PEAlVEHq3gf11Hf1qrQKKD+k7ZMHG
# ozQhmtQ9MxfF4VCG9NNSU/j7TXJG+j7sxlG0ADxwjMo+iA7R1ANs6N2seOnvcNvQ
# a3YP4SwHv0hUgz9KBXHXCdA7LG8lGlLp4s0bbyPxagZ1+Of0qnTyG4yq5qij8Wsa
# xAasi1sRYM6rO6Dn5ISaIF1lJmQIOYPezivKenDc3o9yjbb4jPDUjT7M2iK+VRfc
# FPEbcxHJ+FpUAvTYPOEeDO2LkriuRvUkkMTYiXWpqUVojLk3JDlcCRkE5cykIMdX
# irx82lxQpiZGkFrfrGQPMi6DAALX85ZUiDQ10iGyXANtubJkhAnp5hn4Q5JA4tpR
# ty6MlZh94TjeFlbXq9Y2phRi3AWqunOMAxX8gSHfbrmAa7gNkaBoVZd2tlVrV1X+
# lnnnb3yO0SuErx3bfhS++MgrisERscGgcY+vB5trw05FMGfK5YkzWZF2eIE/m70T
# 2rfmH9tUnElgJHTqEu4L8txmnNZ/j8ZzyLNY5+n8XqGghtTqeIxLAgMBAAGjggOd
# MIIDmTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAuBgNVHSUBAf8EJDAiBggr
# BgEFBQcDAwYKKwYBBAGCNwIBFQYKKwYBBAGCNwoDDTAdBgNVHQ4EFgQU/zkKtNmi
# KcWBOqQkxr6qsIyjrGUwHwYDVR0jBBgwFoAU0E4PQJlsuEsZbzsouODjiAc0qrcw
# ggIhBgNVHSAEggIYMIICFDCCAhAGCysGAQQBgbU3AQICMIIB/zAuBggrBgEFBQcC
# ARYiaHR0cDovL3d3dy5zdGFydHNzbC5jb20vcG9saWN5LnBkZjA0BggrBgEFBQcC
# ARYoaHR0cDovL3d3dy5zdGFydHNzbC5jb20vaW50ZXJtZWRpYXRlLnBkZjCB9wYI
# KwYBBQUHAgIwgeowJxYgU3RhcnRDb20gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkw
# AwIBARqBvlRoaXMgY2VydGlmaWNhdGUgd2FzIGlzc3VlZCBhY2NvcmRpbmcgdG8g
# dGhlIENsYXNzIDIgVmFsaWRhdGlvbiByZXF1aXJlbWVudHMgb2YgdGhlIFN0YXJ0
# Q29tIENBIHBvbGljeSwgcmVsaWFuY2Ugb25seSBmb3IgdGhlIGludGVuZGVkIHB1
# cnBvc2UgaW4gY29tcGxpYW5jZSBvZiB0aGUgcmVseWluZyBwYXJ0eSBvYmxpZ2F0
# aW9ucy4wgZwGCCsGAQUFBwICMIGPMCcWIFN0YXJ0Q29tIENlcnRpZmljYXRpb24g
# QXV0aG9yaXR5MAMCAQIaZExpYWJpbGl0eSBhbmQgd2FycmFudGllcyBhcmUgbGlt
# aXRlZCEgU2VlIHNlY3Rpb24gIkxlZ2FsIGFuZCBMaW1pdGF0aW9ucyIgb2YgdGhl
# IFN0YXJ0Q29tIENBIHBvbGljeS4wNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2Ny
# bC5zdGFydHNzbC5jb20vY3J0YzItY3JsLmNybDCBiQYIKwYBBQUHAQEEfTB7MDcG
# CCsGAQUFBzABhitodHRwOi8vb2NzcC5zdGFydHNzbC5jb20vc3ViL2NsYXNzMi9j
# b2RlL2NhMEAGCCsGAQUFBzAChjRodHRwOi8vYWlhLnN0YXJ0c3NsLmNvbS9jZXJ0
# cy9zdWIuY2xhc3MyLmNvZGUuY2EuY3J0MCMGA1UdEgQcMBqGGGh0dHA6Ly93d3cu
# c3RhcnRzc2wuY29tLzANBgkqhkiG9w0BAQUFAAOCAQEAMDdkGhWaFooFqzWBaA/R
# rf9KAQOeFSLoJrgZ+Qua9vNHrWq0TGyzH4hCJSY4Owurl2HCI98R/1RNYDWhQ0+1
# dK6HZ/OmKk7gsbQ5rqRnRqMT8b2HW7RVTVrJzOOj/QdI+sNKI5oSmTS4YN4LRmvP
# MWGwbPX7Poo/QtTJAlxXkeEsLN71fabQsavjjJORaDXDqgd6LydG7yJOlLzs2zDr
# dSBOZnP8VD9seRIZtMWqZH2tGZp3YBQSTWq4BySHdsxsIgZVZnWi1HzSjUTMtbcl
# P/CKtZKBCS7FPHJNcACouOQbA81aOjduUtIVsOnulVGT/i72Grs607e5m+Z1f4pU
# FjGCBLgwggS0AgEBMIGTMIGMMQswCQYDVQQGEwJJTDEWMBQGA1UEChMNU3RhcnRD
# b20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERpZ2l0YWwgQ2VydGlmaWNhdGUgU2ln
# bmluZzE4MDYGA1UEAxMvU3RhcnRDb20gQ2xhc3MgMiBQcmltYXJ5IEludGVybWVk
# aWF0ZSBPYmplY3QgQ0ECAgepMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSWfVmqhopdzo5Olw3c
# QFXMcDjJHjANBgkqhkiG9w0BAQEFAASCAgBYoh/8smSWEabRXEwXUNk8ov844hqE
# Zu51bYWgUWUguVMMJOMql3vDcEecD/Ue9k99onyWl8PMfcZ+xtM40ZDM0GL+iUzt
# XGz+biBHD8vZ9Oh7bxIShKesns9AAgVlp9pKtpQOjDXjk9Nz9RbMyh6HAR3ZrxgG
# cPhVCjdEOqLdmqauK/FF1qExRDxxQSWvOpP5fTg+J76lRp+1oOoZA/vTjcs2VGgu
# lAhBaX/3cvJR/fRkOciMSdbgQe6ZM4Qi4HA/98Wnhi0iN86vTr0pdC2aquaiDeiN
# yDo8zz4zC9pu/Ati4DfIvHdq11UDsKRDowM2p7e6c7Uq0aAOTbjTzYNEVq8ZF9zH
# fwdSHd70ozIDWHbBFBwTRkbDl8g7+VMrclei+RffTjS5cyfsBI+yRqn/WhuXj9UX
# Q+sqSvUbwmrPn9AWhjKJbIGwwhc56udNqZZgLrAS8JAZYcOI0blKvZq5Jcni4Vet
# PQxQ7DCYbqxOL8idPesWwjHXcf66BRMNBlJtYrsKgOTi4oSPRtBthNj96i94DQdf
# GnYHrTUSKXB2A3J/JBEZ6BulcpOMQHiWEsgv7aKzkbnmtygJEyZwQXPuGr5+MDcy
# mBTF+uSvtCCeV1yvxuGuKL47a9xtZQrBQZt8/Bs5/4N7OKZuhGORtRnwJQk4pALa
# xUNeGtLZOXkTfaGCAX8wggF7BgkqhkiG9w0BCQYxggFsMIIBaAIBATBnMFMxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjErMCkGA1UEAxMiVmVy
# aVNpZ24gVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQQIQeaKlhfnRFUIT2bg+9raN
# 7TAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG
# 9w0BCQUxDxcNMTIxMDI3MDI0NDUxWjAjBgkqhkiG9w0BCQQxFgQUyAgetv3iC/HS
# AIfOOzQDlfNigLIwDQYJKoZIhvcNAQEBBQAEgYBw9tyJnaJaNohtSf1G8aH6TgXm
# ln6iNyJ5bwXUVLOgGoXqPL80aGmsVB9xUzfVgEWKdvRXkDw3KIHQRU3sQELpZycf
# 9viQWEAeMqeBlCulsaLF1Dc8hor1kB0AZpx2yeG/hJCSCLbZ3NOcAmuw24sGQ5I9
# KdsTD1MJPxlsmqN2tw==
# SIG # End signature block
