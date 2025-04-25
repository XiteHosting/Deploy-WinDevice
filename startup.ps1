if ($psISE) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
} else {
    $ScriptRoot = $PSScriptRoot
}

$url = "https://github.com/XiteHosting/Deploy-WinDevice/archive/refs/heads/main.zip"
$DownloadOutput = "$($env:TEMP)\Deploy-WinDevice.zip"
$BranchName = "Deploy-WinDevice-main"
$ArchiveOutput = "$($env:TEMP)"
$Destination = "$($env:TEMP)\Deploy-WinDevice"

if (Test-Path "$DownloadOutput") { Remove-Item "$DownloadOutput" }
if (Test-Path "$ArchiveOutput\$BranchName") { Remove-Item "$ArchiveOutput\$BranchName" -Recurse }
if (Test-Path "$Destination") { Remove-Item "$Destination" -Recurse }

Write-Host "`n### Download latest script version"
#Import-Module BitsTransfer
#Start-BitsTransfer -Source $url -Destination $DownloadOutput
Invoke-WebRequest -Uri $url -OutFile $DownloadOutput
Expand-Archive -Path $DownloadOutput -DestinationPath $ArchiveOutput -Force
Remove-Item $DownloadOutput
Move-Item "$ArchiveOutput\$BranchName" $Destination

. "$Destination\Functions\Select-Option.ps1"
. "$Destination\Functions\Ask-Confirmation.ps1"

Write-Host "`n### You may remove USB Stick if you don't need the locally stored images"

Write-Host "`n### Choose Autopilot action"
$AutopilotOptions = @(
  [PSCustomObject]@{Return = "Publish"; Action = "Publish Autopilot Info to Tenant"}
  [PSCustomObject]@{Return = "LocalCSV"; Action = "Create AutopilotInfo.csv on USB stick"}
  [PSCustomObject]@{Return = "Display"; Action = "Display Autopilot Info"}
  [PSCustomObject]@{Return = "Skip"; Action = "Skip"}
)
$AutopilotOption = Select-Option -list $AutopilotOptions -returnField Return -showFields Action -extraOption Default -defaultValue "Publish"

if ($AutopilotOption -eq 'Publish') {
  # TODO: Open 7z file
  Write-Host "### Run publish later so all user actions are together"
} elseif ($AutopilotOption -eq 'LocalCSV') {
  # TODO: Change to drive selection
  $Drive = "$((Get-Volume -FileSystemlabel "OSDCloudUSB").DriveLetter):"
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  if (Test-Path "$($Drive)\AutopilotInfo.csv") {
    $AutopilotInfo = Import-CSV "$($Drive)\AutopilotInfo.csv"
    $AutopilotInfo += Import-CSV "$Destination\Autopilot\AutopilotInfo.csv"
    $AutopilotInfo | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-CSV -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File "$($Drive)\AutopilotInfo.csv"
  } else {
    Copy-Item "$Destination\Autopilot\AutopilotInfo.csv" "$($Drive)\AutopilotInfo.csv"
  }
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
} elseif ($AutopilotOption -eq 'Display') {
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  Import-CSV "$Destination\Autopilot\AutopilotInfo.csv" | Format-List
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
}

$OSVersion = 'Windows 11'
$OSActivation = 'Retail'

Write-Host "`n### Choose Edition to install"
$OSEditions = @(
  [PSCustomObject]@{Edition = "Pro"}
  [PSCustomObject]@{Edition = "Education"}
)
if ($AutopilotOption -eq 'skip') {
  $OSEditions += [PSCustomObject]@{Edition = "Home"}
}
$OSEdition = Select-Option -list $OSEditions -returnField Edition -extraOption Default -defaultValue "Pro"

Write-Host "`n### Choose language to install"
$OSLanguages = @(
  [PSCustomObject]@{LangCode = "nl-nl"; Language = "Dutch"}
  [PSCustomObject]@{LangCode = "en-us"; Language = "English (United States)"}
  [PSCustomObject]@{LangCode = "fr-fr"; Language = "French"}
  [PSCustomObject]@{LangCode = "de-de"; Language = "German"}
)
$OSLanguage = Select-Option -list $OSLanguages -returnField LangCode -extraOption Default -defaultValue "nl-nl"

Write-Host "`n### Choose release to install"
$ReleaseIds = Get-OSDCatalogOperatingSystems | Where-Object { ($_.OperatingSystem -eq $OSVersion) -and ($_.License -eq $OSActivation) -and ($_.LanguageCode -eq $OSLanguage) } | Select-Object -Property ReleaseId -Unique
$ReleaseIds += [PSCustomObject]@{ReleaseId = 'Latest'}
$ReleaseId = Select-Option -list $ReleaseIds -returnField ReleaseId -extraOption Default -defaultValue 'Latest'

if ($ReleaseId -eq 'Latest') {
  # TO DO: Get latest ReleaseId more intelligently (Split on H, highest first, highest last)
  $OSBuild = $ReleaseIds[0].ReleaseId
} else {
  $OSBuild = $ReleaseId
}

Write-Host "`n### Install Windows Updates right before OOBE?"
$WindowsUpdate = @(
  [PSCustomObject]@{Return = 'y'; Answer = 'Yes'}
  [PSCustomObject]@{Return = 'n'; Answer = 'No'}
)
$WindowsUpdate = Select-Option -list $WindowsUpdate -returnField Return -showFields Answer -extraOption Default -defaultValue 'y'

if ($WindowsUpdate -eq 'y') {
  $WindowsUpdate = $true
} else {
  $WindowsUpdate = $false
}

Write-Host "`n### Manually confirm Clear-Disk for each drive?"
Write-Warning "Choose Yes if you have multiple drives (default is NO) !"
$ClearDiskConfirm = @(
  [PSCustomObject]@{Return = 'y'; Answer = 'Yes'}
  [PSCustomObject]@{Return = 'n'; Answer = 'No'}
)
$ClearDiskConfirm = Select-Option -list $ClearDiskConfirm -returnField Return -showFields Answer -extraOption Default -defaultValue 'n'

if ($ClearDiskConfirm -eq 'y') {
  $ClearDiskConfirm = $true
} else {
  $ClearDiskConfirm = $false
}

Write-Host "`n"
Write-Host "#################################"
Write-Host "            Summary"
Write-Host "Autopilot:        $AutopilotOption"
Write-Host "OSVersion:        $OSVersion"
Write-Host "OSActivation:     $OSActivation"
Write-Host "OSEdition:        $OSEdition"
Write-Host "OSLanguage:       $OSLanguage"
Write-Host "OSReleaseId:      $ReleaseId"
Write-Host "OSBuild:          $OSBuild"
Write-Host "WindowsUpdate:    $WindowsUpdate"
Write-Host "ClearDiskConfirm: $ClearDiskConfirm"
Write-Host "#################################"
Write-Host "`n"

$Continue = Ask-Confirmation -Message "Correct" -HideCancel

if ($Continue -eq 'y') {
  if ($AutopilotOption -eq 'Publish') {
    & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
    & "$Destination\Autopilot\Publish-Autopilot.ps1"
    Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
  }
  
  $Global:MyOSDCloud = [ordered]@{
    OEMActivation = [bool]$true
    ClearDiskConfirm = [bool]$ClearDiskConfirm
    Restart = [bool]$true
    RecoveryPartition = [bool]$true
    WindowsUpdate = [bool]$WindowsUpdate
    WindowsUpdateDrivers = [bool]$WindowsUpdate
    SyncMSUpCatDriverUSB = [bool]$true
  }
  
  Start-OSDCloud -OSVersion $OSVersion -OSEdition $OSEdition -OSLanguage $OSLanguage -OSBuild $OSBuild -OSActivation $OSActivation -Firmware -SkipAutopilot -SkipODT
} else {
  Write-Warning "Too bad, please reboot or relaunch script manually"
}
