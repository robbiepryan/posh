#RUN FROM DOMAIN CONTROLLER

$csvExportPath = "~\Desktop\PC_Userlist.csv"

$computers = get-adcomputer -Filter { OperatingSystem -like "*Pro*" } |
Select-Object -ExpandProperty Name

$userList = @()

foreach ($pc in $computers) {
    Write-Host "Checking $pc" -ForegroundColor Cyan
    $username = ((query user /server:$pc)[1]).split(" ")[1]
    if ($?) {
        $userList += [pscustomobject]@{
            PC       = $pc
            Username = $username
        } 
    }
    else {
        $userList += [pscustomobject]@{
            PC       = $pc
            Username = "No user logged in"
        }
    }
}

$userList | Export-Csv -Path $csvExportPath