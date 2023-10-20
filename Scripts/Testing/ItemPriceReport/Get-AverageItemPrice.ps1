function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvPath,
        [Parameter(Mandatory = $true)]
        [string]$csvOutPath,
        [Parameter(Mandatory = $true)]
        [string]$key
    )

    $global:enrichedData = @() # Empty array to collect enriched data
    $global:products = @()

    $global:csvContent = Import-Csv -Path $csvPath

    $itemNumber = 0

    foreach ($global:row in $global:csvContent) {
        #$global:searchTerm = (("$global:($global:row.scale) $global:($global:row.manufacturer) $global:($global:row.item)").Trim()).Replace("  ", " ")
        $global:searchTerm = (($global:row.item).Trim()).Replace("  ", " ")
        
        #"category_id": "220",
        # Make a request to the RapidAPI endpoint for Ebay Average Selling Price
        $global:headers = @{}
        $global:headers.Add("content-type", "application/json")
        $global:headers.Add("X-RapidAPI-Key", $global:key)
        $global:headers.Add("X-RapidAPI-Host", "ebay-average-selling-price.p.rapidapi.com")

        $body = @{
            "keywords"           = $searchTerm
            "excluded_keywords"  = ""
            "max_search_results" = "5"
            "max_pages"          = "5"
            "category_id"        = "220"
            "remove_outliers"    = "true"
            "site_id"            = "0"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri 'https://ebay-average-selling-price.p.rapidapi.com/findCompletedItems' -Method POST -Headers $headers -ContentType 'application/json' -Body $body
        $response

        $itemNumber++
        $global:listings = ($rapidApiResponse | select -expand products | Select -first 5)
        foreach ($global:item in $listings) {
            $global:products += [PSCustomObject]@{
                ItemNumber    = $($itemNumber)
                Title         = $($item.title)
                SalePrice     = $($item.sale_price)
                Condition     = $($item.condition)
                BuyingFormat  = $($item.buying_format)
                DateSold      = $($item.date_sold)
                ImageUrl      = $($item.image_url)
                ShippingPrice = $($item.shipping_price)
                Link          = $($item.link)
                ItemID        = $($item.item_id)
            }
        }

        # $global:enrichedData += [PSCustomObject]@{
        #     ItemNumber   = "$itemNumber"
        #     AveragePrice = "$($global:rapidApiResponse.average_price)"
        #     MedianPrice  = "$($global:rapidApiResponse.median_price)"
        #     MinimumPrice = "$($global:rapidApiResponse.min_price)"
        #     MaximumPrice = "$($global:rapidApiResponse.max_price)"
        # }

        $global:row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value $global:rapidApiResponse.average_price -Force
        $global:row | Add-Member -Name "MedianPrice" -MemberType NoteProperty -Value $global:rapidApiResponse.median_price -Force
        $global:row | Add-Member -Name "MinimumPrice" -MemberType NoteProperty -Value $global:rapidApiResponse.min_price -Force
        $global:row | Add-Member -Name "MaximumPrice" -MemberType NoteProperty -Value $global:rapidApiResponse.max_price -Force
        $global:row | Add-Member -Name "Key" -MemberType NoteProperty -Value $itemNumber -Force
        $global:enrichedData += $global:row

    }
    $global:enrichedData | Export-Csv -Path $csvOutPath -NoTypeInformation
    $products | Export-Csv -Path "C:\temp\csv-OUT2.csv" -NoTypeInformation
}

