# # # # # # #
# Variables #
# # # # # # # 

$user = ''
$result = ''
$correctUser = ''
$upn = ''


# # # # # # #
# Get Input #
# # # # # # #

$user = Read-Host -Prompt "Enter username`n"


# # # # # # #
# Find User #
# # # # # # #

$result = (Get-aduser -Filter * |
Where-Object {($_.SamAccountName -like "*$user*") -or ($_.Name -like "*$user*")} |
Select-Object -First 1
)


# # # # # # # #
# Verify User #
# # # # # # # #

Write-Host "`n$($result.Name) is the selected user."

$correctUser = Read-Host -Prompt "`nIs this correct? (Y/N)`n"


# # # # # #
# Action! #
# # # # # #

switch ($correctUser) {

    "Y" {
        Write-Host "Deactivating User AD Account..."

        $upn = ($result).UserPrincipalName

        Disable-ADAccount -Identity $result.DistinguishedName

        Write-Host "Connecting to MsolService..."

        Connect-MsolService

        Write-Host "Removing Licenses..."
        
        (get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId |
        ForEach-Object{
            Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_
        }
        
        Write-Host "Complete!"
    } 

    Default {
        Write-Host "`nNo changes were made. Exiting...`n"
        exit
    }
}