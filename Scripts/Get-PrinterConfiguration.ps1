
$ErrorActionPreference = "SilentlyContinue"

$printer = ( Read-Host -Prompt "Enter printer name, or 'exit'" )

if ( $printer -eq "exit" ) { exit }

$result = ( Get-Printer |
    Where-Object Name -Like "*$printer*" |
    Select-Object Name,PortName,DriverName |
    Select-Object -First 1 )

do { 
Clear-Variable IP,pingTest,pingResult,model,display,jobCount,errorCount,firstJob,lastJob
$IP = ( Get-PrinterPort -Name ( $result ).Portname.PrinterHostAddress )
Test-Connection $IP -Count 1

if ( $? -eq $true ){ 
    $pingResult = "Online"
    $hostname = ( [System.Net.Dns]::GetHostByName( $env:computerName ) ).HostName
    
   ##QUERY SMNP FOR PRINTER MODEL
    $SNMP = New-Object -ComObject olePrn.OleSNMP
    $SNMP.Open( $IP, "public" )
    $model = $SNMP.Get( ".1.3.6.1.2.1.25.3.2.1.3.1" )
    $display = $SNMP.Get( ".1.3.6.1.2.1.43.16.5.1.2.1.1" )
    $SNMP.Close(  )

 } else { 
    $pingResult = "Offline"
 }

$firstJob = (Get-PrintJob -PrinterName $printerName | Select-Object UserName,DocumentName,SubmittedTime,JobStatus -First 1 | findstr ":")
$lastJob = (Get-PrintJob -PrinterName $printerName | Select-Object UserName,DocumentName,SubmittedTime,JobStatus -Last 1 | findstr ":")

$jobCount = ( Get-PrintJob -PrinterName $(( $result ).Name ) | findstr : ).Count
$errorCount = ( Get-PrintJob -PrinterName $(( $result ).Name ) | Where-Object JobStatus -like '*error*' | findstr : ).Count

if ( $pingResult -eq "Online" ){ 
    Write-Host -Object "
Name      : $(( $result ).Name )
IP        : $IP
Ping      : $pingResult" -ForegroundColor Green } elseif ( $pingResult -eq "Offline" ) { 
    Write-Host -Object "
Name      : $(( $result ).Name )
IP        : $IP
Ping      : $pingResult" -ForegroundColor Red
 }
Write-Host -Object "
Driver    : $(( $result ).DriverName ) 
Model     : $model 

Display   : $display

======================================
| Job Total: $jobCount     Jobs w/ Errors: $errorCount |
======================================

Oldest Job : $firstJob
Newest Job : $lastJob"

if ( $pingResult -eq "Online" ){ 
    Write-Host "
PowerShell>  Add-printer -ConnectionName '\\$hostname\$(( $result ).Name )'" -ForegroundColor Yellow }

    Write-Host "
======================================================
|Enter 'test'      to Print a Test Page              |
|Enter 'clear'     to Remove Jobs with Error Status  |
|Enter 'cleartest' to Remove All Test Pages          |
|Enter 'find'      to Find User's Print Jobs         |
|Enter 'exit'      to exit                           |
======================================================
" -ForegroundColor DarkGray

$printerCheck = ( Read-Host -Prompt "Enter New Printer Name, or Press Enter to Check Again" )

Clear-Host

if ( $printerCheck -eq 'test' ) { 
    Get-CimInstance Win32_Printer -Filter "name LIKE '%$(( $result ).Name )%'" | Invoke-CimMethod -MethodName PrintTestPage
 }elseif
( $printerCheck -eq 'clear' ) { 
    $(( $result ).Name ) | Get-PrintJob | Where-Object JobStatus -like '*error*' | Remove-PrintJob
 }elseif
( $printerCheck -eq 'cleartest' ) { 
    $(( $result ).Name ) | Get-PrintJob | Where-Object DocumentName -like '*Test Page*' | Remove-PrintJob
 }elseif
( $printerCheck -eq 'find' ) { 
    $user = Read-Host -Prompt "Enter username, or leave blank to get all print jobs"
    Clear-Host
    Get-Printer | Get-PrintJob | Where-Object UserName -Like "*$user*" | Select-Object Username,PrinterName,DocumentName,SubmittedTime,JobStatus | Sort-Object SubmittedTime
    Read-Host -Prompt "Press Enter to Continue"
    Clear-Host
 }elseif
( $printerCheck -eq 'exit' ) { 
    exit
 }elseif
( $printerCheck -eq '' ) { 
    Write-Host "Checking $(( $result ).Name ) again..." } else { 
    $result = ( Get-Printer | Where-Object Name -Like "*$printerCheck*" | Select-Object Name,PortName,DriverName | Select-Object -First 1 ) }

 }
until 
( 
    $printers -eq ""
 )