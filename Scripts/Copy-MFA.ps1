function GetCodes {
    ((get-content $env:LOCALAPPDATA\Microsoft\Windows\Notifications\wpndatabase.db-wal |
        Select-String '<text>Your Virtech Systems verification code is:' |
        Select-Object -ExpandProperty Line) -split "<text>Your Virtech Systems verification code is: " -replace ". Reply HELP for help.</text>", "" |
    Select-String ^\d)
}

$codes = @{}

GetCodes |
ForEach-Object {
    $codes.Add("$_","")
}

While ($true) {
    Start-Sleep 1
    $UpdatedCodes = GetCodes
    foreach ($code in $UpdatedCodes) {
        if ($code -notin $codes.Keys) {
            $code | Set-Clipboard
            $codes.Add("$code","")
        }
    }
}
