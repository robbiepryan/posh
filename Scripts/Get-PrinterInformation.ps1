$ErrorActionPreference = "SilentlyContinue"

function FindUserPrintJobs {
    while ($user -ne "back") {
        $user = Read-Host -Prompt "`nEnter username to search, leave blank to get all print jobs, or enter 'back' to go back"
    Clear-Host
    Get-Printer | Get-PrintJob | Where-Object UserName -Like "*$user*" |
        Select-Object Username,PrinterName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime |
        Format-Table -AutoSize
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

function GetPrintJobs {
    ( Get-PrintJob -PrinterName $($printer).Name |
        Select-Object UserName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime |
        Format-Table -AutoSize)
}

function PausePrinting {
    (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").pause() | Out-Null
}

function ResumePrinting {
    (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").resume() | Out-Null
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
    
    do { 
        Clear-Variable IP,pingTest,pingResult,model,display,user

        $status = (get-wmiobject win32_printer -filter "name='$(($printer).Name)'").PrinterState
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
        }
    
        $IP = ( Get-PrinterPort -Name ($printer).Portname |
            Select-Object -ExpandProperty PrinterHostAddress )
            
        Test-Connection $IP -Count 1 | Out-Null
    
        if ( $? -eq $true ){ 
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
        }
        elseif ( 
            $pingResult -eq "Offline" ) { 
            Write-Host "
Name      : $(($printer).Name )
IP        : $IP
Ping      : $pingResult" -ForegroundColor Red
        }
    
        Write-Host "
Driver    : $(($printer).DriverName )
Status    : $status`n`n"
        
Write-Host "-----------------------------Job Queue-----------------------------" -ForegroundColor DarkGray
GetPrintJobs
    
        if ( $pingResult -eq "Online" ){ 
            Write-Host "`nPowerShell>  Add-printer -ConnectionName '\\$hostname\$(($printer).Name )'" -ForegroundColor Yellow }
            Write-Host "`n
1  > Find User Print Jobs             
2  > Print Test Page 
3  > Delete Test Pages         
4  > Delete Jobs w/ Errors
5  > Pause Printing
6  > Resume Printing
7  > Query SNMP for Model/Status
8  > Show PowerShell Command to Print Test Page 
9  > Restart Script
10 > Exit           

        " -ForegroundColor DarkGray
    
    $userInput2 = ( Read-Host -Prompt "Enter new printer name, leave blank to test same printer again, or select an option from the menu`n" )
    
        Clear-Host
    
        switch ($userInput2) {
            1 { FindUserPrintJobs }
            2 { SendTestPage }
            3 { RemoveTestPages }
            4 { RemoveJobsWithErrors }
            5 { PausePrinting }
            6 { ResumePrinting }
            7 { Write-Host "`nQuerying SNMP for printer model and status. This could take a little while ..."
                $SNMP = New-Object -ComObject olePrn.OleSNMP
                $SNMP.Open( $IP, "public" )
                $model = $SNMP.Get( ".1.3.6.1.2.1.25.3.2.1.3.1" )
                $display = $SNMP.Get( ".1.3.6.1.2.1.43.16.5.1.2.1.1" )
                $SNMP.Close(  )
                    Write-Host "Completed SNMP query.`n"
                    Write-Host "    Printer Model   : $model"
                    Write-Host "    Display Readout : $display" }
            8 { Write-Host "`nTest Print from PowerShell to $(($printer).Name ) with the following command:`n"
                Write-Host "Get-CimInstance Win32_Printer -Filter `"name LIKE '%$(($printer).Name )%'`" |   
                    Invoke-CimMethod -MethodName PrintTestPage"
                Read-Host -Prompt "`nPress Enter to continue ..."
                Clear-Host}
            9 {  }
            10 { exit }
            '' {  }
    
            Default { $printer = ( Get-Printer |
                Where-Object Name -Like "*$userInput2*" |
                Select-Object Name,PortName,DriverName |
                Select-Object -First 1 ) }
        }
    } until ( $userInput2 -eq 9 )

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