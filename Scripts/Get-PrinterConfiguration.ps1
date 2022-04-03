$ErrorActionPreference = "SilentlyContinue"

function FindUserPrintJobs {
    while ($user -ne "exit") {
        $user = Read-Host -Prompt "Enter username, leave blank to get all print jobs, or enter 'exit' to exit"
    Clear-Host
    Get-Printer | Get-PrintJob | Where-Object UserName -Like "*$user*" |
        Select-Object Username,PrinterName,DocumentName,SubmittedTime,JobStatus |
        Sort-Object SubmittedTime    
    }
}

function SendTestPage {
    Get-CimInstance Win32_Printer -Filter "name LIKE '%$(($printer).Name )%'" |
        Invoke-CimMethod -MethodName PrintTestPage    
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

Clear-Host

$userInput = ( Read-Host -Prompt "`nEnter printer name, or 'exit'" )

if ( $userInput -eq "exit" ) { exit }

$printer = ( Get-Printer |
    Where-Object Name -Like "*$userInput*" |
    Select-Object Name,PortName,DriverName |
    Select-Object -First 1 )

$confirmPrinter = Read-Host -Prompt "Printer: $(($printer).Name) `nIs that correct? (Y/N)"

switch ($confirmPrinter) {
    Y { continue }
    Default { exit }
}

do { 
    Clear-Variable IP,pingTest,pingResult,model,display,user
    $IP = ( Get-PrinterPort -Name ($printer).Portname |
        Select-Object -ExpandProperty PrinterHostAddress )
    
    Test-Connection $IP -Count 1

    if ( $? -eq $true ){ 
        $pingResult = "Online"
        $hostname = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
        
    ##QUERY SMNP FOR PRINTER MODEL
        $SNMP = New-Object -ComObject olePrn.OleSNMP
        $SNMP.Open( $IP, "public" )
        $model = $SNMP.Get( ".1.3.6.1.2.1.25.3.2.1.3.1" )
        $display = $SNMP.Get( ".1.3.6.1.2.1.43.16.5.1.2.1.1" )
        $SNMP.Close(  )

    }
    else { 
        $pingResult = "Offline"
    }

    $printJobs = ( Get-PrintJob -PrinterName $($printer).Name | Select-Object UserName,DocumentName,SubmittedTime,JobStatus )

    if ( $pingResult -eq "Online" ){ 
        Write-Host -Object "
    Name      : $(($printer).Name )
    IP        : $IP
    Ping      : $pingResult" -ForegroundColor Green 
    }
    elseif ( 
        $pingResult -eq "Offline" ) { 
        Write-Host -Object "
    Name      : $(($printer).Name )
    IP        : $IP
    Ping      : $pingResult" -ForegroundColor Red
    }

    Write-Host "
    Driver    : $(($printer).DriverName ) 
    Model     : $model 

    Display   : $display

    $printJobs "

    if ( $pingResult -eq "Online" ){ 
        Write-Host "
    PowerShell>  Add-printer -ConnectionName '\\$hostname\$(($printer).Name )'" -ForegroundColor Yellow }

        Write-Host "
    + # # # # # # # # # # # # # # # # # # # # # # +
    # 'test'      > Print a Test Page             #
    # 'clear'     > Remove Jobs with Error Status #
    # 'cleartest' > Remove All Test Pages         #
    # 'find'      > Find User's Print Jobs        #
    # 'exit'      > exit                          #
    + # # # # # # # # # # # # # # # # # # # # # # +
    " -ForegroundColor DarkGray

$userInput2 = ( Read-Host -Prompt "Enter New Printer Name, or Press Enter to Check Again" )

    Clear-Host

    switch ($userInput2) {
        test { SendTestPage }
        clear { RemoveJobsWithErrors }
        cleartest { RemoveTestPages }
        find { FindUserPrintJobs }
        exit { exit }

        Default { $printer = ( Get-Printer |
            Where-Object Name -Like "*$userInput2*" |
            Select-Object Name,PortName,DriverName |
            Select-Object -First 1 ) }
    }
}
until ( 
    $printers -eq ""
)