$returnTrue = 'yes', 'ye', 'y', 'ja', 'j'
$returnFalse = 'no', 'n', 'neen', 'nee', 'ne', 'n'
$returnCancel = 'cancel', 'c'

Function Ask-Confirmation {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [Parameter(Mandatory = $false)]
        [Switch]$HideCancel = $false,
        [Parameter(Mandatory = $false)]
        [switch]$HideNo = $false
    )

    Begin {
        $returnTrueInternal = $returnTrue
        $returnFalseInternal = $returnFalse
        $returnCancelInternal = $returnCancel

        $textOptions = "Yes"
        $listOptions = $returnTrueInternal

        if (-not $HideNo) {
            $textOptions += " / No"
            $listOptions += $returnFalseInternal
        }

        if (-not $HideCancel) {
            $textOptions += " / Cancel"
            $listOptions += $returnCancelInternal
        }
    }

    Process {
        do {
            $confirm = Read-Host "$($Message)? ($($textOptions))"
        } until ($listOptions -contains $confirm)

        if ($returnTrue -contains $confirm) {
            "y"
        } elseif ($returnFalse -contains $confirm) {
            "n"
        } elseif ($returnCancel -contains $confirm) {
            "c"
        } else {
            "ERR"
        }
    }

    End {

    }
}
