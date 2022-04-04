$ErrorActionPreference = "SilentlyContinue"

function FindUserPrintJobs {
    while ($user -ne "back") {
        $user = Read-Host -Prompt "`nEnter username to search, leave blank to get all print jobs, or enter 'back' to go back"
    Clear-Host
    Get-Printer | Get-PrintJob | Where-Object UserName -Like "*$user*" |
        Select-Object Username,PrinterName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime |
        Format-List
    }
}

function SendTestPage {
    Get-CimInstance Win32_Printer -Filter "name LIKE '%$(($printer).Name )%'" |
        Invoke-CimMethod -MethodName PrintTestPage |
        Out-Null
}

function RemoveJobsWithErrors {
    $(($printer).Name ) |
        Get-PrintJob |
        Where-Object JobStatus -like '*error*' |
        Remove-PrintJob
}

function RemoveTestPages {
    $(($printer).Name ) |
        Get-PrintJob |
        Where-Object DocumentName -like '*Test Page*' |
        Remove-PrintJob
}

function GetFirstLastPrintJobs {
    ( ( Get-PrintJob -PrinterName $($printer).Name )[0..-1] |
        Select-Object UserName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime |
        Format-Table )
}

function PausePrinting {
    (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").pause() | Out-Null
}

function ResumePrinting {
    (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").resume() | Out-Null
}

function TestCommonPorts {
    Write-Host "Starting common ports test. This could take a while...`n"
    $nmapPath = 'C:\Program Files (x86)\Nmap\nmap.exe'
    if ((Test-Path $nmapPath) -eq $true) {
        Set-Location "C:\Program Files (x86)\Nmap\"
        .\nmap.exe -p 9100,515,631 $IP
    } else {
    Test-NetConnection $IP -Port 9100 | Out-Null
    Test-NetConnection $IP -Port 515 | Out-Null
    Test-NetConnection $IP -Port 631 | Out-Null
    }
    Write-Host "`nIf printer shows online but all ports are closed, the printer IP is likely incorrect." -ForegroundColor Yellow
    Read-Host -Prompt "`nPress Enter to continue..."
    Clear-Host
}

function TestPrintCommand {
    Write-Host "`nTest Print from PowerShell to $(($printer).Name ) with the following command:`n"
    Write-Host "Get-CimInstance Win32_Printer -Filter `"name LIKE '%$(($printer).Name )%'`" |   
        Invoke-CimMethod -MethodName PrintTestPage" -ForegroundColor Yellow
    Read-Host -Prompt "`nPress Enter to continue..."
    Clear-Host
}

function SNMP {
    $SNMP = New-Object -ComObject olePrn.OleSNMP
    $SNMP.Open( $IP, "public" )
    $model = $SNMP.Get( ".1.3.6.1.2.1.25.3.2.1.3.1" )
    $display = $SNMP.Get( ".1.3.6.1.2.1.43.16.5.1.2.1.1" )
    $SNMP.Close(  )
        Write-Host "`nPrinter Model   : $model"
        Write-Host "Current Driver  : $(($printer).DriverName )"
        Write-Host "Display Readout : $display`n"
}

function GetPrinterInformation {
    $userInput = ( Read-Host -Prompt "`nEnter printer name, or 'back' to go back" )
    Clear-Host
    if ( $userInput -eq "back" ) { 
        Clear-Host
        break
    }

    $printer = ( Get-Printer |
        Where-Object Name -Like "*$userInput*" |
        Select-Object Name,PortName,DriverName |
        Select-Object -First 1 )
    
    while ($True) { 
        Clear-Variable IP,pingTest,pingResult,model,display,user
        <#Commented out status because it dramatically slows down the script.#>
        <#$status = (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").PrinterState
        switch ($status) {
            0 {$status = "Idle"}
            1 {$status = "Paused"}
            2 {$status = "Error"}
            3 {$status = "Pending Deletion"}
            4 {$status = "Paper Jam"}
            5 {$status = "Paper Out"}
            6 {$status = "Manual Feed"}
            7 {$status = "Paper Problem"}
            8 {$status = "Offline"}
            9 {$status = "I/O Active"}
            10 {$status = "Busy"}
            11 {$status = "Printing"}
            12 {$status = "Output Bin Full"}
            13 {$status = "Not Available"}
            14 {$status = "Waiting"}
            15 {$status = "Processing"}
            16 {$status = "Initialization"}
            17 {$status = "Warming Up"}
            18 {$status = "Toner Low"}
            19 {$status = "No Toner"}
            20 {$status = "Page Punt"}
            21 {$status = "User Intervention Required"}
            22 {$status = "Out of Memory"}
            23 {$status = "Door Open"}
            24 {$status = "Server_Unknown"}
            25 {$status = "Power Save"}
            Default { $status = "N/A" }
        }#>
    
        $IP = ( Get-PrinterPort -Name ($printer).Portname |
            Select-Object -ExpandProperty PrinterHostAddress )
            
        $pingTest = (Test-Connection $IP -Count 1).StatusCode
    
        if ( $pingTest -eq 0 ){ 
            $pingResult = "Online"
            $hostname = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
        }
        else { 
            $pingResult = "Offline"
        }
    
        if ( $pingResult -eq "Online" ){ 
            Write-Host -Object "
Name      : $(($printer).Name )
IP        : $IP
Ping      : $pingResult" -ForegroundColor Green
SNMP
        }
        elseif ( 
            $pingResult -eq "Offline" ) { 
            Write-Host "
Name      : $(($printer).Name )
IP        : $IP
Ping      : $pingResult" -ForegroundColor Red
        }

#Status    : $status`n`n

Write-Host "Jobs in queue   : $($( Get-PrintJob -PrinterName $($printer).Name ).Count)"
Write-Host "----------------------------------▼First & Last Jobs in Queue▼----------------------------------" -ForegroundColor DarkGray
GetFirstLastPrintJobs
Write-Host "------------------------------------------------------------------------------------------------`n" -ForegroundColor DarkGray

        if ( $pingResult -eq "Online" ){ 
            Write-Host "PowerShell>  Add-printer -ConnectionName '\\$hostname\$(($printer).Name )'" -ForegroundColor Yellow }
            Write-Host "
1 > Test Common Ports                    6 > Pause Printing
2 > Find User Print Jobs                 7 > Resume Printing
3 > Print Test Page                      8 > Query SNMP for Model/Display Readout
4 > Delete Test Pages from Queue         9 > Show PowerShell Command to Print Test Page 
5 > Delete Jobs w/ Errors from Queue    10 > Exit" -ForegroundColor DarkGray
    
    $userInput2 = ( Read-Host -Prompt "`nEnter new printer name, leave blank to test same printer again, or select an option from the menu`n" )
    
        Clear-Host
    
        switch ($userInput2) {
            1 { TestCommonPorts }
            2 { FindUserPrintJobs }
            3 { SendTestPage }
            4 { RemoveTestPages }
            5 { RemoveJobsWithErrors }
            6 { PausePrinting }
            7 { ResumePrinting }
            8 { SNMP }
            9 { TestPrintCommand }
            10 { exit }
            '' {  }
    
            Default { $printer = ( Get-Printer |
                Where-Object Name -Like "*$userInput2*" |
                Select-Object Name,PortName,DriverName |
                Select-Object -First 1 ) }
        }
    }

Clear-Host
}

<#----------------------------END FUNCTION DEFINITIONS----------------------------#>

while ($true) {
    $Action = Read-Host -Prompt "
Enter a number to select action:
        
1 - Get Printer Information
2 - Find User Print Jobs
3 - Exit
        
Selection"
    Clear-Host
    switch ($Action) {
        1 { GetPrinterInformation }
        2 { FindUserPrintJobs }
        3 { exit }
        Default { 
            Clear-Host
            Write-Host "Invalid entry" }
    }
}