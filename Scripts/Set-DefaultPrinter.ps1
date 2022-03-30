$path = "~\DefaultPrinter.config"

if ((Test-Path $path) -eq $false) {
    $user_input = Read-Host -Prompt "Enter name of printer to set as default"
    (Get-Printer |
        Where-Object Name -like "*$user_input*").Name |
        Out-File $path    
} 

(New-Object -ComObject WScript.Network).SetDefaultPrinter((Get-Content $path))