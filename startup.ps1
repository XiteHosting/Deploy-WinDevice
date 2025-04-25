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
$AutopilotOption = Read-Host -Prompt "Publish Hash, Local CSV, Display, Skip"

if ($AutopilotOption -eq 'Publish') {
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  & "$Destination\Autopilot\Publish-Autopilot.ps1"
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
} elseif ($AutopilotOption -eq 'LocalCSV') {
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  # Append to destination
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
} elseif ($AutopilotOption -eq 'Display') {
  & "$Destination\Autopilot\Get-WindowsAutopilotInfoCsvWinPE.ps1"
  Import-CSV "$Destination\Autopilot\AutopilotInfo.csv" | Format-List
  Remove-Item "$Destination\Autopilot\AutopilotInfo.csv"
}
