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

function Start-vtsPingReport {
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
                $failedTimes += "$(Get-Date) - $failCount"
            }
            Clear-Host
            Write-Host "Start Time : $startTime"
            Write-Host "`nPinging: $Domain"
            Write-Host "`nPress Ctrl-C to exit" -ForegroundColor Yellow
            Write-Host "`nSuccessful Ping Count: $successCount" -ForegroundColor Green
            Write-Host "Last Successful Ping : $lastSuccess" -ForegroundColor Green
            Write-Host "`nFailed Ping Count    : $failCount" -ForegroundColor DarkRed
            
            if ($failCount -gt 0) {
                Write-Host "`n--Last 30 Failed Pings--" -ForegroundColor DarkRed
                $failedTimes | Select-Object -last 30 | Sort-Object -Descending
                Write-Host "------------------------" -ForegroundColor DarkRed
            }
    
            Start-Sleep 1    
        }
    }
    finally {
        Write-Output "Start Time : $startTime" | Out-File $output
        Write-Output "Pinging: $Domain" | Out-File $output -Append
        Write-Output "Successful Ping Count: $successCount" | Out-File $output -Append
        Write-Output "Last Successful Ping : $lastSuccess" | Out-File $output -Append
        Write-Output "`nFailed Ping Count    : $failCount" | Out-File $output -Append
        if ($failCount -gt 0) {
            Write-Output "`n----Pings Failed at:----" | Out-File $output -Append
            $failedTimes | Out-File $output -Append
            Write-Output "------------------------" | Out-File $output -Append
        }
        Write-Host "logfile saved to $output"
    }
}

function New-vtsRandomPassword {
    $numbers = 0..9
    $symbols = '!', '@', '#', '$', '%', '*', '?', '+', '='
    $string = ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) |
            Get-Random -Count 12  |
            ForEach-Object { [char]$_ }))
    $number = $numbers | Get-Random
    $symbol = $symbols | Get-Random
    $NewPW = $string + $number + $symbol

    $NewPW | Set-Clipboard

    Write-Output "Random Password Copied to Clipboard"
}

#FROM https://www.powershellgallery.com/packages/Out-PhoneticAlphabet/0.2.0/Content/Out-PhoneticAlphabet.ps1
function Out-PhoneticAlphabet
{
    [CmdletBinding(SupportsShouldProcess=$true,
                  ConfirmImpact='Low')]
    [Alias('Out-NATOAlphabet')]
    [OutputType([String])]
    Param
    (
        # Input string to convert
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$false,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[0-9a-zA-Z\.\-]+$")]
        [string[]]
        $InputObject
    )
    Begin
    {
        Write-Verbose -Message 'Listing Parameters utilized:'
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose -Message "$($PSItem)" }

        $nato = @{
            '0'=[PSCustomObject]@{PSOutputString='(ZERO)';Pronunciation='ZEE-RO';}
            '1'=[PSCustomObject]@{PSOutputString='(ONE)';Pronunciation='WUN';}
            '2'=[PSCustomObject]@{PSOutputString='(TWO)';Pronunciation='TOO';}
            '3'=[PSCustomObject]@{PSOutputString='(THREE)';Pronunciation='TREE';}
            '4'=[PSCustomObject]@{PSOutputString='(FOUR)';Pronunciation='FOW-ER';}
            '5'=[PSCustomObject]@{PSOutputString='(FIVE)';Pronunciation='FIFE';}
            '6'=[PSCustomObject]@{PSOutputString='(SIX)';Pronunciation='SIX';}
            '7'=[PSCustomObject]@{PSOutputString='(SEVEN)';Pronunciation='SEV-EN';}
            '8'=[PSCustomObject]@{PSOutputString='(EIGHT)';Pronunciation='AIT';}
            '9'=[PSCustomObject]@{PSOutputString='(NINE)';Pronunciation='NIN-ER';}
            'a'=[PSCustomObject]@{PSOutputString='alfa';Pronunciation='AL-FAH';}
            'b'=[PSCustomObject]@{PSOutputString='bravo';Pronunciation='BRAH-VOH';}
            'c'=[PSCustomObject]@{PSOutputString='charlie';Pronunciation='CHAR-LEE';}
            'd'=[PSCustomObject]@{PSOutputString='delta';Pronunciation='DELL-TAH';}
            'e'=[PSCustomObject]@{PSOutputString='echo';Pronunciation='ECK-OH';}
            'f'=[PSCustomObject]@{PSOutputString='foxtrot';Pronunciation='FOKS-TROT';}
            'g'=[PSCustomObject]@{PSOutputString='golf';Pronunciation='GOLF';}
            'h'=[PSCustomObject]@{PSOutputString='hotel';Pronunciation='HOH-TEL';}
            'i'=[PSCustomObject]@{PSOutputString='india';Pronunciation='IN-DEE-AH';}
            'j'=[PSCustomObject]@{PSOutputString='juliett';Pronunciation='JEW-LEE-ETT';}
            'k'=[PSCustomObject]@{PSOutputString='kilo';Pronunciation='KEY-LOH';}
            'l'=[PSCustomObject]@{PSOutputString='lima';Pronunciation='LEE-MAH';}
            'm'=[PSCustomObject]@{PSOutputString='mike';Pronunciation='MIKE';}
            'n'=[PSCustomObject]@{PSOutputString='november';Pronunciation='NO-VEM-BER';}
            'o'=[PSCustomObject]@{PSOutputString='oscar';Pronunciation='OSS-CAH';}
            'p'=[PSCustomObject]@{PSOutputString='papa';Pronunciation='PAH-PAH';}
            'q'=[PSCustomObject]@{PSOutputString='quebec';Pronunciation='KEH-BECK';}
            'r'=[PSCustomObject]@{PSOutputString='romeo';Pronunciation='ROH-ME-OH';}
            's'=[PSCustomObject]@{PSOutputString='sierra';Pronunciation='SEE-AIR-RAH';}
            't'=[PSCustomObject]@{PSOutputString='tango';Pronunciation='TANG-GO';}
            'u'=[PSCustomObject]@{PSOutputString='uniform';Pronunciation='YOU-NEE-FORM';}
            'v'=[PSCustomObject]@{PSOutputString='victor';Pronunciation='VIK-TAH';}
            'w'=[PSCustomObject]@{PSOutputString='whiskey';Pronunciation='WISS-KEY';}
            'x'=[PSCustomObject]@{PSOutputString='xray';Pronunciation='ECKS-RAY';}
            'y'=[PSCustomObject]@{PSOutputString='yankee';Pronunciation='YANG-KEY';}
            'z'=[PSCustomObject]@{PSOutputString='zulu';Pronunciation='ZOO-LOO';}
            '.'=[PSCustomObject]@{PSOutputString='(POINT)';Pronunciation='POINT';}
            '-'=[PSCustomObject]@{PSOutputString='(DASH)';Pronunciation='DASH';}
        }
    } # END: BEGIN
    Process
    {
        if ($pscmdlet.ShouldProcess("Target", "Operation"))
        {
            foreach ($string in $InputObject)
            {
                Write-Verbose -Message "InputObject: '$string'"
                $sb = New-Object -TypeName 'System.Text.StringBuilder'
                $characters = $string.ToCharArray()
                $count = $($characters.Count)
                for ($i = 0; $i -lt $count; $i++)
                {
                    $character = $characters[$i]
                    switch -Regex -CaseSensitive ($character)
                    {
                        '\d'
                        {
                            $sb.Append($nato.Get_Item("$character").PSOutputString) | Out-Null
                            break
                        }
                        '[a-z]'
                        {
                            $sb.Append($nato.Get_Item("$character").PSOutputString.ToLower()) | Out-Null
                            break
                        }
                        '[A-Z]'
                        {
                            
                            $sb.Append($nato.Get_Item("$character").PSOutputString.ToUpper()) | Out-Null
                            break
                        }
                        '\.'
                        {
                            $sb.Append($nato.Get_Item("$character").PSOutputString) | Out-Null
                            break
                        }
                        '\-'
                        {
                            $sb.Append($nato.Get_Item("$character").PSOutputString) | Out-Null
                            break
                        }
                        Default {<# Nothing. #>}
                    }
                    # The string contains additional characters, append a whitespace ' ' to make the output text easier to read.
                    if ($i -ne $($count-1))
                    {
                        $sb.Append(' ') | Out-Null
                    }
                }
                Write-Output -InputObject $($sb.ToString())
                Remove-Variable -Name sb,characters,count
            }
        }
    } # END: PROCESS
    End
    {
    } # END: END
}