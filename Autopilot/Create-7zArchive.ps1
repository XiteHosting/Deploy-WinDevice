if ($psISE) {
    Write-Host "ISE Running"
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath        
} else {
    Write-Host "ISE Not Running"
    $ScriptRoot = $PSScriptRoot
}

$ShortName = Read-Host "Client Short name"

if (Test-Path "$ScriptRoot\TenantInfo_$($ShortName).7z") {
    Write-Warning "File already exists!"
} else {
    Write-Host "Give Tenant App Configuration"
    Write-Warning "No input checks, copy paste values !"
    $TenantId = Read-Host -Prompt "Tenant Id"
    $AppId = Read-Host -Prompt "App Id"
    $AppSecret = Read-Host -Prompt "App Secret" -AsSecureString

    Write-Host "Create encrypted 7z file"
    $TenantInfo = @{TenantId = $TenantId; AppId = $AppId; AppSecret = (New-Object PSCredential 0, $AppSecret).GetNetworkCredential().Password}
    $TenantInfo | ConvertTo-Json | Out-File "$ScriptRoot\TenantInfo.json"
    $Arguments = 'a "{0}" "{1}" -sdel -p"{2}"' -f "$TenantInfo_$($ShortName).7z", "$ScriptRoot\TenantInfo.json", (New-Object PSCredential 0, (Read-Host -Prompt "7z Encryption Password" -AsSecureString)).GetNetworkCredential().Password
    Start-Process "$ScriptRoot\7za.exe" -ArgumentList $Arguments -Wait

    if (Test-Path "$ScriptRoot\TenantInfo.json") {
        Write-Warning "Source file TenantInfo.json still exists, is the 7z created correctly?"
    }

    Write-Host "Testing encrypted 7z file"
    $Arguments = 't "{0}" -p"{1}"' -f "$TenantInfo_$($ShortName).7z", (New-Object PSCredential 0, (Read-Host -Prompt "7z Encryption Password" -AsSecureString)).GetNetworkCredential().Password
    $7za = Start-Process "$ScriptRoot\7za.exe" -ArgumentList $Arguments -Wait -PassThru
    if ($7za.ExitCode -ne 0) {
        Write-Warning "Couldn't open 7z file with specified password !"
    } else {
        Write-Host "Password ok"
    }
}