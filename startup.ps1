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
if (Test-Path "$ArchiveOutput\$BranchName") { Remove-Item "$Destination" -Recurse }

#Import-Module BitsTransfer
#Start-BitsTransfer -Source $url -Destination $DownloadOutput
Invoke-WebRequest -Uri $url -OutFile $DownloadOutput
Expand-Archive -Path $DownloadOutput -DestinationPath $ArchiveOutput -Force
Remove-Item $DownloadOutput
Move-Item "$ArchiveOutput\$BranchName\*" $ArchiveOutput
Remove-Item "$ArchiveOutput\$BranchName" -Force

Write-Host "Autopilot"
Write-Host "Options: Publish Hash, Local CSV, Skip"
$AutopilotOption = 'Publish'


# Local CSV: To Do

if ($AutopilotOption -eq 'Publish') {
  & "$ArchiveOutput\Autopilot\Publish-Autopilotinfo.ps1"
}

# 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
