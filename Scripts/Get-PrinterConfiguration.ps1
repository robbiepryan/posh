$ErrorActionPreference = "SilentlyContinue"

function FindUserPrintJobs {
    while ($user -ne "back") {
        $user = Read-Host -Prompt "`nEnter username to search, leave blank to get all print jobs, or enter 'back' to go back"
    Clear-Host
    Get-Printer | Get-PrintJob | Where-Object UserName -Like "*$user*" |
        Select-Object Username,PrinterName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime    
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

function GetUserPrintJobs {
    ( Get-PrintJob -PrinterName $($printer).Name |
        Select-Object UserName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime )
}

function GetPrinterInformation {
    $userInput = ( Read-Host -Prompt "`nEnter printer name, or 'back' to go back" )

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
        
Job Queue :`n"
            GetUserPrintJobs
    
        if ( $pingResult -eq "Online" ){ 
            Write-Host "
    PowerShell>  Add-printer -ConnectionName '\\$hostname\$(($printer).Name )'" -ForegroundColor Yellow }
    
            Write-Host "

1 > Find User Print Jobs             
2 > Print Test Page 
3 > Delete Test Pages         
4 > Delete Jobs w/ Errors
5 > Query SNMP for Model/Status   
6 > Restart Script
7 > Exit           

        " -ForegroundColor DarkGray
    
    $userInput2 = ( Read-Host -Prompt "Enter new printer name, leave blank to test same printer again, or select an option from the menu" )
    
        Clear-Host
    
        switch ($userInput2) {
            1 { FindUserPrintJobs }
            2 { SendTestPage }
            3 { RemoveTestPages }
            4 { RemoveJobsWithErrors }
            5 { Write-Host "`nQuerying SNMP for printer model and status. This could take a little while ..."
                $SNMP = New-Object -ComObject olePrn.OleSNMP
                $SNMP.Open( $IP, "public" )
                $model = $SNMP.Get( ".1.3.6.1.2.1.25.3.2.1.3.1" )
                $display = $SNMP.Get( ".1.3.6.1.2.1.43.16.5.1.2.1.1" )
                $SNMP.Close(  )
                    Write-Host "Completed SNMP query.`n"
                    Write-Host "    Printer Model   : $model"
                    Write-Host "    Display Readout : $display" }
            6 { continue }
            7 { exit }
            '' {  }
    
            Default { $printer = ( Get-Printer |
                Where-Object Name -Like "*$userInput2*" |
                Select-Object Name,PortName,DriverName |
                Select-Object -First 1 ) }
        }
    } until ( $userInput2 -eq 6 )

Clear-Host
}

<#END FUNCTION DEFINITIONS#>

while ($action -ne 3) {
    $Action = Read-Host -Prompt "
Enter a number to select action:
        
1 - Get Printer Information
2 - Find User Print Jobs
3 - Exit
        
Selection"

    switch ($Action) {
        1 { GetPrinterInformation }
        2 { FindUserPrintJobs }
        3 { exit }
        Default { 
            Clear-Host
            Write-Host "Invalid entry" }
    }
}