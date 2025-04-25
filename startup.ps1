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
