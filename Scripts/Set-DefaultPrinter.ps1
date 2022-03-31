# Set config file location
$ConfigFile = "~\DefaultPrinter.config"

<#
 # Test if $ConfigFile exists. If $ConfigFile already exits, set default printer
 # to the printer specified in the $ConfigFile. If $ConfigFile doesn't exist, ask
 # user to enter the name of the printer to set as default and save that value as
 # $UserInput. Then, do a wildcard search for installed printers that match
 # $UserInput, and set that value equal to $ConfigFile
 #> 

if ((Test-Path $ConfigFile) -eq $false) {
    $UserInput = Read-Host -Prompt "Enter name of printer to set as default"
    (Get-Printer |
        Where-Object Name -like "*$UserInput*").Name |
        Out-File $ConfigFile
} 

# Set default printer to the printer name listed in $ConfigFile
(New-Object -ComObject WScript.Network).SetDefaultPrinter((Get-Content $ConfigFile))