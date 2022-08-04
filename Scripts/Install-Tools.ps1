$moduleURL = "https://raw.githubusercontent.com/robbiepryan/posh/main/Scripts/Get-vtsTools.ps1"
$moduleName = "VTS"
$filename = "VTS.psm1"

if ($env:USERNAME -eq "SYSTEM") {
    $modulePath = "$env:SystemDrive\Tools"
}
else {
    $modulePath = $env:PSModulePath -split ";" |
    Select-String "$env:USERNAME" |
    Select-Object -First 1
}

if (-not (Test-Path $modulePath\$moduleName)) {
    New-Item -Path $modulePath\$moduleName -ItemType Directory -Force |
    Out-Null
}

$content = Invoke-WebRequest -uri $moduleURL -UseBasicParsing |
Select-Object -ExpandProperty Content

$content |
Out-File -FilePath "$modulePath\$moduleName\$filename" -Force
Import-Module -Verbose $modulePath\$moduleName