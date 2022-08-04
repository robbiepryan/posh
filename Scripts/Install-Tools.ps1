$moduleURL = "https://raw.githubusercontent.com/robbiepryan/posh/main/Scripts/Search-VTSEventLog.ps1"; $moduleName = "VTS"; $filename = "VTS.psm1"; $modulePath = $env:PSModulePath -split ";" | Select-String "$env:USERNAME" | Select-Object -First 1; if (-not (Test-Path $modulePath\$moduleName)) {New-Item -Path $modulePath\$moduleName -ItemType Directory -Force}; $content = Invoke-WebRequest -uri $moduleURL | Select-Object -ExpandProperty Content; $content | Out-File -FilePath "$modulePath\$moduleName\$filename" -Force; Import-Module -Verbose $moduleName