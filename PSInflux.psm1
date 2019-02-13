$global:PSInfluxStringStorageVariableWithOversizedNameToAvoidConflicts = New-Object -TypeName System.Collections.Generic.List[string]

<#
.SYNOPSIS
Adds a measurement to the InfluxDB String

.DESCRIPTION
Adds a measurement to the InfluxDB string. Multiple Measurements can be included in a single string. A single string with multiple measurements can b e sent to InfluxDB and is ideal for minimizing system resource impact on the influxDB.

.PARAMETER measurement
Name of Measurement

.PARAMETER tags
An array containing tags you want attached to this measurement. Tags can help when designing dashboards.

.PARAMETER value
Current Value of measurement

.EXAMPLE
Add-InfluxData -measurement DiskFreePercent -tags "Server Storage-01","Drive C" -value "14"

#>
function Add-InfluxData {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]
        $measurement,
        [Parameter(Mandatory=$false)]
        [string[]]
        $tags,
        [Parameter(Mandatory=$true)]
        [string]
        $value
    )
    
    begin {
    }
    
    process {
       # add line to store of previous lines .. and maybe some validation here so it doesn't bork if measurement and tags are not provided?
       Write-Verbose "Running Add Block"
       $line = "$measurement,$($tags -join ',') value=$value"
       [void]$global:PSInfluxStringStorageVariableWithOversizedNameToAvoidConflicts.Add($line)
    }
    
    end {
    }
}


<#
.SYNOPSIS
Returns Current Influx Data String.

.DESCRIPTION
Returns Current Influx Data String with formatting.

.EXAMPLE
Get-InfluxDataString

#>

function Get-InfluxData {
    [CmdletBinding()]
    param (
    )
    
    begin {
    }
    
    process {
        # output current line(s)
        Write-Verbose "Running Get Block"
        $global:PSInfluxStringStorageVariableWithOversizedNameToAvoidConflicts -join "`n "
    }
    
    end {
    }
}

<#
.SYNOPSIS
Clears the Influx Data String.

.DESCRIPTION
Clears the Influx Data String, typically used after sending a Influx Data String to an Influx Database, to prepare a new Influx Data String for a different Database.

.EXAMPLE
Reset-InfluxData

#>

function Reset-InfluxData {
    [CmdletBinding()]
    param (
    )
    
    begin {
            # ifdbBody has not been run before, or reset was called
            Write-Verbose "Running Reset Block"
            Remove-Variable ifdbLines -ErrorAction SilentlyContinue
            $global:PSInfluxStringStorageVariableWithOversizedNameToAvoidConflicts = New-Object -TypeName System.Collections.Generic.List[string]  #i hope
    }
    
    process {

    }
    
    end {
    }
}

<#
.SYNOPSIS
Send Constructed Influx Data String to InfluxDB

.DESCRIPTION
Send Constructed Influx Data String to InfluxDB

.PARAMETER Uri
Uri including http(s), IP, and Port for the InfluxDB Instance

.PARAMETER Database
Name of Database on InfluxDB Instance

.PARAMETER KeepData
By default, this function will wipe the 

.EXAMPLE
Send-InfluxData -uri https://ifdb.domain.com:8086 -database MyData

#>

function Send-InfluxData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Uri,
        [Parameter(Mandatory=$true)]
        [String]
        $Database,
        [Parameter(Mandatory=$false)]
        [switch]
        $KeepData
    )
    
    begin {
    }
    
    process {
        # Make sure there's actually something to send
        if ( ($PSInfluxStringStorageVariableWithOversizedNameToAvoidConflicts | Measure-Object).count -ne 0 ){
            try{
                Invoke-RestMethod -uri ($uri + "/write?db=" + $database) -Method Post -body (Get-InfluxData)
            }
            Catch{
                # If Invoke-RestMethod fails, don't reset the data.
                Write-Output $_
                $KeepData = $true
            }
        }else{
            Throw "No Data to send. Please add data and try again."
        }
    }
    
    end {
        if ($KeepData){
            Write-Output "KeepData was detected, Influx Data string NOT reset."
        }else {
            Reset-InfluxData
        }
    }
}
