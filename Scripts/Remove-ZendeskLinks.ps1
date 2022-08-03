$supportLinks = @()

Get-ChildItem -Path C:\Users\ -Name *virtech* -Recurse -Force 2>$null |
ForEach-Object {
    $supportLinks += "C:\Users\$_"
}

foreach ($link in $supportLinks) {
    if ( (Get-Content $link 2>$null) -like "*https://virtechsystems.zendesk.com*" ) {
        #Write-Host "$link is a zendesk link" -ForegroundColor Red
        Remove-Item $link -Force
    }
    else {
        #Write-Host "$link is NOT a zendesk link" -ForegroundColor Green
    }
}