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

#Import-Module BitsTransfer
#Start-BitsTransfer -Source $url -Destination $DownloadOutput
Invoke-WebRequest -Uri $url -OutFile $DownloadOutput
Expand-Archive -Path $DownloadOutput -DestinationPath $ArchiveOutput -Force
Remove-Item $DownloadOutput
Move-Item "$ArchiveOutput\$BranchName" $Destination

Write-Host "Autopilot"
$AutopilotOption = Read-Host -Prompt "Publish, LocalCSV, Display, Skip"

if ($AutopilotOption -eq 'Publish') {
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  & "$Destination\Autopilot\Publish-Autopilot.ps1"
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
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

$OSEdition = Read-Host -Prompt "Pro, Home, Education"

$OSLanguage = Read-Host -Prompt "nl-nl, en-us, fr-fr, de-de"

$OSBuild = Read-Host "Use latest build? (Y/n)
if ($OSBuild -eq 'y') {
  $ReleaseId = Get-OSDCatalogOperationgSystems | Where-Object { ($_.OperatingSystem -eq $OSVersion) -and ($_.License -eq $OSActivation) -and ($_.LanguageCode -eq $OSLanguage) } | Select-Object -Property ReleaseId -Unique
  # TO DO: Get latest ReleaseId more intelligently (Split on H, highest first, highest last)
  $OSBuild = $ReleaseId[0]
}

$WindowsUpdate = Read-Host "Run Windows Update before OOBE? (Y/n)"
if ($WindowsUpdate -eq 'y') {
  $WindowsUpdate = $true
} else {
  $WindowsUpdate = $false

$Global:MyOSDCloud = [ordered]@{
  OEMActivation = [bool]$true
  ClearDiskConfirm = [bool]$true # Indien meerdere drives, anders geen keuze
  Restart = [bool]$true
  RecoveryPartition = [bool]$true
  WindowsUpdate = [bool]$WindowsUpdate
  WindowsUpdateDrivers = [bool]$WindowsUpdate
  SyncMSUpCatDriverUSB = [bool]$true
}

Start-OSDCloud -OSVersion $OSVersion -OSEdition $OSEdition -OSLanguage $OSLanguage -OSBuild $OSBuild -Firmware -SkipAutopilot -SkipODT
