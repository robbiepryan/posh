$user = Read-Host -Prompt "Enter username`n"

$result = (Get-aduser -Filter * |
Where-Object {($_.SamAccountName -like "*$user*") -or ($_.Name -like "*$user*")}
)

Write-Host "`n$($result.Name) is the selected user."

$correctUser = Read-Host -Prompt "`nIs this correct? (Y/N)`n"

if ($correctUser -eq "Y") {
    $upn = ($result).UserPrincipalName

    Disable-ADAccount -Identity $result.DistinguishedName

    Connect-MsolService

    (get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId |
        ForEach-Object{
            Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_
}

if ($? -eq $true) {
    Write-Host "Command Complete Successfully"
} else {
    Write-Host "An error occurred. Double check settings."
}

} else {
    Write-Host "`nNo changes were made. Exiting...`n"
    exit
}