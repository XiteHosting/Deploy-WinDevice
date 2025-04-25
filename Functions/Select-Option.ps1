Function Select-Option {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $list,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("field")] # Old Name
        [String]$returnField,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$fieldUnique = $true,
        [Parameter(Mandatory = $false)]
        [Array]$showFields,
        [Parameter(Mandatory = $false)]
        [String]$indexField,
        [Parameter(Mandatory = $false)]
        [ValidateSet("all", "parent", "none", "default")]
        [String]$extraOption = "all",
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
	[String]$defaultValue
    )
    Begin {
    }
    Process {
        if ($fieldUnique) {
            $options = $list
        } else {
            $options = $list | Select-Object -Property @{N = "$returnField"; E = "$returnField"} -Unique
        }

        if (($null -eq $indexField) -or ($indexField -eq "")) {
            $indexField = 'index'
            $options = $options | Select-Object -Property index, * # index bestaat nog niet, en dan werkt dat niet via $indexField

            $optionsCount = 1
            $options | ForEach-Object { $_.Index = $optionsCount; $optionsCount++ }
        }

        if (($null -ne $showFields) -or ($showFields -eq "")) {
            if ($indexField -ne $showFields) {
                $options | Select-Object -Property (@($indexField) + $showFields) | Format-Table | Out-Host
            } else {
                $options | Select-Object -Property $indexField | Format-Table | Out-Host
            }
        } else {
            $options | Format-Table | Out-Host
        }

        if ($extraOption -eq "all") {
            do {
                $optionIndex = Read-Host "Choose $indexField (0 for all)"
            } until ( ($options.$indexField -contains $optionIndex) -or ($optionIndex -eq '0') )
        } elseif ($extraOption -eq "parent") {
            do {
                $optionIndex = Read-Host "Choose $indexField (0 for parent)"
            } until ( ($options.$indexField -contains $optionIndex) -or ($optionIndex -eq '0') )
        } elseif ( ($extraOption -eq "default") -and ("" -ne $defaultValue) ) {
            $defaultValueString = ($options | Where-Object { $_.$returnField -eq $defaultValue }).$returnField

            if ( ($null -ne $defaultValueString) -and ('' -ne $defaultValueString) ) {
                do {
                    $optionIndex = Read-Host "Choose $indexField (0 for $defaultValueString)"
                } until ( ($options.$indexField -contains $optionIndex) -or ($optionIndex -eq '0') )
            } else {
                $extraOption = 'none'
            }
        }

        if ('none' -eq $extraOption) {
            do {
                $optionIndex = Read-Host "Choose $indexField"
            } until ($options.$indexField -contains $optionIndex)
        }

        if ($optionIndex -eq '0') {
            if ($extraOption -eq "all") {
                $option = $options
            } elseif ($extraOption -eq "parent") {
                $option = @{$returnField = ".."}
            } elseif ($extraOption -eq 'default') {
		$option = $options | Where-Object { $_.$returnField -eq $defaultValue }
            }
        } else {
            $option = $options | Where-Object { $_.$indexField -eq $optionIndex }
        }

        Write-Output $option.$returnField
    }
    End {
    }
}
