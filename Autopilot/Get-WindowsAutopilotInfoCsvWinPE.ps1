if ($psISE) {
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath        
} else {
    $ScriptRoot = $PSScriptRoot
}

$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber

#Register PCPKsp
Copy-Item "$ScriptRoot\oa3\PCPKsp.dll" "X:\Windows\System32\PCPKsp.dll"
rundll32 X:\Windows\System32\PCPKsp.dll,DllInstall

#Run OA3Tool
Start-Process "$ScriptRoot\oa3\oa3tool.exe" -WorkingDirectory "$ScriptRoot\oa3" -ArgumentList "/Report /ConfigFile=""$ScriptRoot\oa3\OA3.cfg"" /NoKeyCheck" -Wait

If (Test-Path $ScriptRoot\oa3\OA3.xml) 
{
	#Read Hash from generated XML File
	[xml]$xmlhash = Get-Content -Path "$ScriptRoot\oa3\OA3.xml"
	$hash=$xmlhash.Key.HardwareHash

	#Delete XML File
	Remove-Item $ScriptRoot\oa3\OA3.xml
 
 	#Create CSV File

	$computers = @()
	$product=""
	# Create a pipeline object
	$c = New-Object psobject -Property @{
 		"Device Serial Number" = $serial
		"Windows Product ID" = $product
		"Hardware Hash" = $hash
		"Group Tag" = $GroupTag
	}
	
 	$computers += $c
	$computers | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File "$ScriptRoot\AutopilotInfo.csv"
}
