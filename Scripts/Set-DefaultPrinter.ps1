# Set config file location
$ConfigFile = "~\DefaultPrinter.config"

<#
 # Test if the $ConfigFile exists. If the $ConfigFile already exits, set default
 # printer to the printer specified in the $ConfigFile. If the $ConfigFile doesn't
 # exist, ask user to enter the name of the printer to set as default and save the
 # first result as $UserInput. Then, do a wildcard search for the first installed
 # printer that matches $UserInput, and write that value to the $ConfigFile.
 #> 

if ((Test-Path $ConfigFile) -eq $false) {
    $UserInput = Read-Host -Prompt "Enter name of printer to set as default"
    (Get-Printer |
        Where-Object Name -like "*$UserInput*" |
        Select-Object -First 1).Name |
        Out-File $ConfigFile
} 

# Set default printer to the printer name listed in $ConfigFile
(New-Object -ComObject WScript.Network).SetDefaultPrinter((Get-Content $ConfigFile))