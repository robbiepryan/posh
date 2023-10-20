function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvPath,
        [Parameter(Mandatory = $true)]
        [string]$csvOutPath,
        [Parameter(Mandatory = $true)]
        [string]$appId
    )

    # Define your endpoint - this example uses the Finding API's 'findCompletedItems' call
    $endpointUrl = "https://svcs.ebay.com/services/search/FindingService/v1"

    $enrichedData = @() # Empty array to collect enriched data

    $csvContent = Import-Csv -Path $csvPath

    foreach ($row in $csvContent) {
        $searchTerm = (("$($row.scale) $($row.manufacturer) $($row.item)").Trim()).Replace("  ", " ")
    
        # Define your request parameters
        $params = @{
            "OPERATION-NAME"       = "findCompletedItems"
            "SERVICE-VERSION"      = "1.13.0"
            "SECURITY-APPNAME"     = $appId
            "RESPONSE-DATA-FORMAT" = "XML"
            "REST-PAYLOAD"         = $true
            "keywords"             = "$searchTerm"
        }
    
        try {
            # Call the API
            $response = Invoke-RestMethod -Uri $endpointUrl -Method Get -Headers $params
    
            # Parse and process the response
            $items = $response.findCompletedItemsResponse.searchResult.item
    
            # Collect prices and compute the average
            $totalPrice = 0
            $itemCount = 0
    
            $items | ForEach-Object {
                $price = [double]$_.sellingStatus.currentPrice."#text"
                $totalPrice += $price
                $itemCount++
            }
    
            $averagePrice = $totalPrice / $itemCount
    
            # Store the average price with the current row data
            $row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value $averagePrice
            $enrichedData += $row
    
        }
        catch {
            Write-Host "Error fetching data for searchTerm: $searchTerm. Error: $_"
        }
    }
    
    $enrichedData | Export-Csv -Path $csvOutPath -NoTypeInformation
}

