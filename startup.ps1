if ($psISE) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
} else {
    $ScriptRoot = $PSScriptRoot
}

$url = "https://github.com/XiteHosting/Deploy-WinDevice/archive/refs/heads/main.zip"
$DownloadOutput = "$($env:TEMP)\Deploy-WinDevice.zip"
$ArchiveOutput = "$($env:TEMP)\Deploy-WinDevice"


#Import-Module BitsTransfer
#Start-BitsTransfer -Source $url -Destination $DownloadOutput
Invoke-WebRequest -Uri $url -OutFile $DownloadOutput
Expand-Archive -Path $DownloadOutput -DestinationPath $ArchiveOutput -Force
Remove-Item $DownloadOutput
Move-Item "$ArchiveOutput\Deploy-WinDevice-main\*" $ArchiveOutput
Remove-Item "$ArchiveOutput\Deploy-WinDevice-main"

Write-Host "Autopilot"
Write-Host "Options: Publish Hash, Local CSV, Skip"
$AutopilotOption = 'Publish'


# Local CSV: To Do

if ($AutopilotOption -eq 'Publish') {
  "$ArchiveOutput\Autopilot\Publish-Autopilotinfo.ps1"
}
