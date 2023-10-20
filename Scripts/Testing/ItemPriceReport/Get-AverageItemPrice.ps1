function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvPath,
        [Parameter(Mandatory = $true)]
        [string]$csvOutPath,
        [Parameter(Mandatory = $true)]
        [string]$key
    )

    $enrichedData = @() # Empty array to collect enriched data

    $csvContent = Import-Csv -Path $csvPath

    foreach ($row in $csvContent) {
        #$searchTerm = (("$($row.scale) $($row.manufacturer) $($row.item)").Trim()).Replace("  ", " ")
        $searchTerm = (($row.item).Trim()).Replace("  ", " ")

        # Make a request to the RapidAPI endpoint for Ebay Average Selling Price
        $headers = @{}
        $headers.Add("content-type", "application/json")
        $headers.Add("X-RapidAPI-Key", $key)
        $headers.Add("X-RapidAPI-Host", "ebay-average-selling-price.p.rapidapi.com")
        $body = @"
        {
            "keywords": "$searchTerm",
            "excluded_keywords": "",
            "max_search_results": "60",
            "max_pages": "5",
            "category_id": "220",
            "remove_outliers": "true",
            "site_id": "0"
        }
"@
        $rapidApiResponse = Invoke-RestMethod -Uri 'https://ebay-average-selling-price.p.rapidapi.com/findCompletedItems' -Method POST -Headers $headers -ContentType 'application/json' -Body $body
        $rapidApiResponse

        try {
            # Store the average price with the current row data
            $row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value $rapidApiResponse.average_price
            $row | Add-Member -Name "MedianPrice" -MemberType NoteProperty -Value $rapidApiResponse.median_price
            $row | Add-Member -Name "MinimumPrice" -MemberType NoteProperty -Value $rapidApiResponse.min_price
            $row | Add-Member -Name "MaximumPrice" -MemberType NoteProperty -Value $rapidApiResponse.max_price
            $enrichedData += $row
        }
        catch {
            Write-Host "Error fetching data for searchTerm: $searchTerm. Error: $_"
        }
    }
    $enrichedData | Export-Csv -Path $csvOutPath -NoTypeInformation
}