function Get-MailProvider {
    Param(
        [Parameter(
            Mandatory = $true
        )]
        $Domain
    )

    try {
        $dnsResolution = Resolve-DnsName -Name $Domain -Type MX -ErrorAction Stop
        
        if ($null -ne $dnsResolution.NameExchange) {
            $nameExchange = ($dnsResolution |
                Select-Object -ExpandProperty NameExchange)
                    
            $result = foreach ($name in $nameExchange) {
                (($name).split(".") |
                Select-Object -last 2)[0]  
            }

            $result = $result | Select-Object -Unique

            if ($null -ne $result) {
                switch ($result) {
                    outlook { $result = "Microsoft Office"; break }
                    Default {}
                }
                #Write-Host "$result" -ForegroundColor Cyan
                $result
            }
            else {
                Write-Error "No result found. Check input."
            }
        }
        else {
            Write-Warning "No MX Records Found for $Domain"
        }
    }
    catch {
        Write-Warning "$($_.Exception.Message)"
    } 
}