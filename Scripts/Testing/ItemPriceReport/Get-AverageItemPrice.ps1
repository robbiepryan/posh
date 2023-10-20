function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvIn = "C:\csv.csv",
        [Parameter(Mandatory = $true)]
        [string]$csvOut = "C:\csvOut.csv"
    )

    $csv = Import-Csv $csvIn

    # Define your API credentials
    $appId = "YOUR_APP_ID"

    # Define your endpoint - this example uses the Finding API's 'findCompletedItems' call
    $endpointUrl = "https://svcs.ebay.com/services/search/FindingService/v1"

    foreach ($row in $csv) {
        $searchTerm = (("$($row.scale) $($row.manufacturer) $($row.item)").Trim()).Replace("  ", " ")
        # Define your request parameters
        $params = @{
            "OPERATION-NAME"       = "findCompletedItems"
            "SERVICE-VERSION"      = "1.13.0"
            "SECURITY-APPNAME"     = $appId
            "RESPONSE-DATA-FORMAT" = "XML" # or "JSON" if you prefer
            "REST-PAYLOAD"         = $true
            "keywords"             = "$searchTerm" # replace with specific items you're searching for
            # Add other parameters as necessary
        }

        # Call the API
        $response = Invoke-RestMethod -Uri $endpointUrl -Method Get -Headers $params

        # Parse and process the response
        # This step will vary based on your needs and the structure of the API response
        $items = $response.findCompletedItemsResponse.searchResult.item

        # Example: Print the title and price of each item
        $items | ForEach-Object {
            $title = $_.title
            $price = $_.sellingStatus.currentPrice."#text"
            Write-Host "Title: $title, Price: $price"
            $csv | Add-Member -Name "Title" -MemberType NoteProperty -Value $title
            $csv | Add-Member -Name "Price" -MemberType NoteProperty -Value $price
        }
    }
    $csv | Export-Csv -Path $csvOut -NoTypeInformation
}