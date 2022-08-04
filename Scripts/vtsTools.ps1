function Search-vtsEventLog {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory,
            ParameterSetName = 'SearchTerm')]
        [string]$SearchTerm
    )
    [array]$Logname = @(
        "System"
        "Application"
    )
        
    $result = @()

    foreach ($log in $Logname) {
        Get-EventLog -LogName $log -EntryType Error, Warning -Newest 500 2>$null |
        Where-Object Message -like "*$SearchTerm*" |
        Select-Object TimeGenerated, Message |
        ForEach-Object {
            $result += [PSCustomObject]@{
                TimeGenerated = $_.TimeGenerated
                Message       = $_.Message
                Log           = $log
            }
        }
    }
    
    foreach ($log in $Logname) {
        if ($null -eq ($result | Where-Object Log -like "$log")) {
            Write-Host "$($log) Log - No Matches Found" -ForegroundColor Yellow
        }
    }

    $result | Format-List
}

function Get-vtsMappedDrive {
    # This is required for Verbose to work correctly.
    # If you don't want the Verbose message, remove "-Verbose" from the Parameters field.
    [CmdletBinding()]
    param ()

    # On most OSes, HKEY_USERS only contains users that are logged on.
    # There are ways to load the other profiles, but it can be problematic.
    $Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*" 2>$null

    # See if any drives were found
    if ( $Drives ) {

        ForEach ( $Drive in $Drives ) {

            # PSParentPath looks like this: Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-21-##########-##########-##########-####\Network
            $SID = ($Drive.PSParentPath -split '\\')[2]

            [PSCustomObject]@{
                # Use .NET to look up the username from the SID
                Username            = ([System.Security.Principal.SecurityIdentifier]"$SID").Translate([System.Security.Principal.NTAccount])
                DriveLetter         = $Drive.PSChildName
                RemotePath          = $Drive.RemotePath

                # The username specified when you use "Connect using different credentials".
                # For some reason, this is frequently "0" when you don't use this option. I remove the "0" to keep the results consistent.
                ConnectWithUsername = $Drive.UserName -replace '^0$', $null
                SID                 = $SID
            }

        }

    }
    else {

        Write-Verbose "No mapped drives were found"

    }
}

function Block-vtsWindows11Upgrade {
    $buildNumber = [System.Environment]::OSVersion.Version.Build

    switch ($buildNumber) {
        19044 {
            cmd /c 'reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseversion /t REG_DWORD /d 1'
            cmd /c 'reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseversionInfo /t REG_SZ /d 21H2'
            if ($?) {
                Write-Host 'Success - Current Version (21H2)' -ForegroundColor Green
            }
            else {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
        19043 {
            cmd /c 'reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseversion /t REG_DWORD /d 1'
            cmd /c 'reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseversionInfo /t REG_SZ /d 21H1'
            if ($?) {
                Write-Host 'Success - Current Version (21H1)' -ForegroundColor Green
            }
            else {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
        Default { Write-Host "Script only works for Windows 10 versions 21H1 and 21H2" }
    }
}

function rping {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        $Domain
    )
    
    try {
        $output = "~\Desktop\PingResults.log"
        $startTime = (Get-Date)
        $lastSuccess = $null
        $failedTimes = @()
    
        $successCount = 0
        $failCount = 0
    
        while ($true) {
            Test-Connection $Domain -Count 1 2>$null | Out-Null
            if ($?) {
                $successCount++
                $lastSuccess = (Get-Date)
            }
            else {
                $failCount++
                $failedTimes += (Get-Date)
            }
            Clear-Host
            Write-Host "Pinging: $Domain - Start Time : $startTime"
            Write-Host "`nPress Ctrl-C to exit" -ForegroundColor Yellow
            Write-Host "`nSuccessful Ping Count: $successCount" -ForegroundColor Green
            Write-Host "Last Successful Ping : $lastSuccess" -ForegroundColor Green
            Write-Host "`nFailed Ping Count    : $failCount" -ForegroundColor DarkRed
            
            if ($failCount -gt 0) {
                Write-Host "`n-------Last 30 Failed Pings-------" -ForegroundColor DarkRed
                $failedTimes | Select-Object -last 30
                Write-Host "----------------------------------" -ForegroundColor DarkRed
            }
    
            Start-Sleep 1    
        }
    }
    finally {
        Write-Output "Pinging: $Domain - Start Time : $startTime`n" | Out-File $output
        Write-Output "Successful Ping Count: $successCount" | Out-File $output -Append
        Write-Output "Last Successful Ping : $lastSuccess" | Out-File $output -Append
        Write-Output "`nFailed Ping Count    : $failCount" | Out-File $output -Append
        if ($failCount -gt 0) {
            Write-Output "`n---------Pings Failed at:---------" | Out-File $output -Append
            $failedTimes | Out-File $output -Append
            Write-Output "----------------------------------" | Out-File $output -Append
        }
        Write-Host "logfile saved to $output"
    }
}