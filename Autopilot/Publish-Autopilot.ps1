if ($psISE) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
} else {
    $ScriptRoot = $PSScriptRoot
}

$ShortName = Read-Host "Client Short name"

$TenantInfoFiles = @()
$TenantInfoFiles += Get-ChildItem "X:\OSDCloud\Config\Scripts\Autopilot\TenantInfo_*.7z"
#$TenantInfoFiles += Get-ChildItem "$((Get-Volume | Where-Object { $_.FileSystemLabel -eq 'OSDCloudUSB' }).DriveLetter):\

if ($TenantInfoFiles.Name -contains ("TenantInfo_$($Shortname).7z")) {
    $TenantInfoFile = $TenantInfoFiles | Where-Object { $_.Name -eq "TenantInfo_$($Shortname).7z" }
}

if (Test-Path "$($TenantInfoFile.FullName)") {
    Write-Host "Sync DateTime"
    $DateTime = Invoke-RestMethod "https://postman-echo.com/time/now"
    $datetimeFormatted = [datetime]::Parse($datetime)
    Set-Date -Date $datetimeFormatted

    Write-Host "Extract encrypted 7z file"
    $Arguments = 'x -aoa "{0}" -o"{1}" -p"{2}"' -f "$($TenantInfoFile.FullName)", "$ScriptRoot", (New-Object PSCredential 0, (Read-Host -Prompt "7z Encryption Password" -AsSecureString)).GetNetworkCredential().Password
    $7za = Start-Process "$ScriptRoot\7z\7za.exe" -ArgumentList $Arguments -Wait -PassThru
    if ($7za.ExitCode -ne 0) {
        Write-Warning "7za exit code <> 0 ($($7za.ExitCode))"
    } elseif (-not (Test-Path "$ScriptRoot\TenantInfo.json")) {
        Write-Warning "Extraction failed (No TenantInfo.json file found) !"
    } else {
        Write-Host "Extract ok"
        $Continue = $true
    }

    If ($Continue) {
        $TenantInfo = Get-Content "$ScriptRoot\TenantInfo.json" | ConvertFrom-Json
        Remove-Item "$ScriptRoot\TenantInfo.json" -Force

        Write-Host "Connect to MSGraph"
        Connect-MSGraphApp -Tenant $TenantInfo.TenantId -AppId $TenantInfo.AppId -AppSecret $TenantInfo.AppSecret

        Remove-Variable TenantInfo

        Write-Host "Upload AutopilotInfo.csv"
        Import-AutoPilotCSV -csvFile "$ScriptRoot\AutopilotInfo.csv"

    #    Write-Host "Publish AutopilotInfo.csv"
    #    &$ScriptRoot\Get-WindowsAutopilotInfoWinPE.ps1 -Online -TenantId $TenantInfo.TenantId -AppId $TenantInfo.AppId -AppSecret $TenantInfo.AppSecret
    }
} else {
    Write-Warning "File doesn't exist!"
}

# Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
