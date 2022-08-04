$filter = @(
    "*wi-fi*"
    "*wlan*"
    "*driver*"
    "*network*"
)

$log = @()

$params = @{
    Logname   = "System"
    EntryType = @("Error", "Warning")
    Newest    = 500
}

foreach ($item in $filter) {
    $events = Get-EventLog @params |
    Where-Object { $_.Message -like $item } |
    Select-Object TimeGenerated, Message

    foreach ($event in $events) {
        $log += [PSCustomObject]@{
            TimeGenerated = $event.TimeGenerated
            Message       = $event.Message
        }
    }
}

$log |
Sort-Object TimeGenerated |
Format-List