$moduleURL = "https://raw.githubusercontent.com/robbiepryan/posh/main/Scripts/vtsTools.ps1"
$moduleName = "VTS"
$filename = "$moduleName.psm1"

Set-ExecutionPolicy Bypass -Scope Process

if ($env:USERNAME -eq "SYSTEM") {
    $modulePath = "$env:SystemDrive\Tools"
} else {
    $modulePath = $env:PSModulePath -split ";" |
    Select-String "$env:USERNAME" |
    Select-Object -First 1
}

if (-not (Test-Path $modulePath\$moduleName)) {
    New-Item -Path $modulePath\$moduleName -ItemType Directory -Force |
    Out-Null
}

Remove-Item "$modulePath\$moduleName\$filename" -Force

Invoke-WebRequest -uri $moduleURL -UseBasicParsing |
Select-Object -ExpandProperty Content |
Out-File -FilePath "$modulePath\$moduleName\$filename" -Force
Import-Module -Verbose $modulePath\$moduleName