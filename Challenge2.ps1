<#
.SYNOPSIS
  THIS SCRIPT CHECKS AD_USER'S EMAIL ADDRESSES AGAINST THEIR UPN. IF THEY DON'T MATCH, THE EMAIL ADDRESS IS CHANGED TO MATCH THE UPN.

  RESULTS ARE LOGGED TO 'C:\AD_UPN_Automation.log'
#>

## GET AN ARRAY OF ALL ENABLED USERS FROM 'OU=Office Users,DC=contsco,DC=com'
Get-ADUser -SearchBase 'OU=Office Users,DC=contsco,DC=com' -Filter * -Properties EmailAddress, UserPrincipalName | Where { $_.Enabled -eq $True} | ForEach-Object -Process {
    
    ## CHECK EACH USER TO SEE IF UPN AND EMAIL ADDRESS ARE EQUAL; IF UNEQUAL, SET $EMAIL TO $UPN
    if ($_.UserPrincipalName -ne $_.EmailAddress) {
         Set-ADUser $_ -EmailAddress $_.UserPrincipalName
         
         ## WRITE RESULTS TO LOG
        Write-Output "$(Get-Date -Format 'HH:mm:ss - MM/dd/yyyy') - $($_.Name): Existing Email - $($_.EmailAddress) - Adding $($_.UserPrincipalName)" | Out-File 'C:\AD_UPN_Automation.log' -Append
    }
}