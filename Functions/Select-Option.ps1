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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$fieldUnique,
        [Parameter(Mandatory = $false)]
        [Array]$showFields,
        [Parameter(Mandatory = $false)]
        [String]$indexField,
        [Parameter(Mandatory = $false)]
        [ValidateSet("all", "parent", "none")]
        [String]$extraOption = "all"
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
        }
        else {
            $options | Format-Table | Out-Host
        }

        if ($extraOption -eq "all") {
            do {
                $optionIndex = Read-Host "Choose $indexField (0 for all)"
            } until ( ($options.$indexField -contains $optionIndex) -or ($optionIndex -eq '0') )
        }
        elseif ($extraOption -eq "parent") {
            do {
                $optionIndex = Read-Host "Choose $indexField (0 for parent)"
            } until ( ($options.$indexField -contains $optionIndex) -or ($optionIndex -eq '0') )
        }
        else {
            do {
                $optionIndex = Read-Host "Choose $indexField"
            } until ($options.$indexField -contains $optionIndex)
        }

        if ($optionIndex -eq '0') {
            if ($extraOption -eq "all") {
                $option = $options
            }
            elseif ($extraOption -eq "parent") {
                $option = @{$returnField = ".."}
            }
        }
        else {
            $option = $options | Where-Object { $_.$indexField -eq $optionIndex }
        }

        Write-Output $option.$returnField
    }
    End {
    }
}
