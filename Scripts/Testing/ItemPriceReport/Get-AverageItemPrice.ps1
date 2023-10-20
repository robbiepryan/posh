function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvPath,
        [Parameter(Mandatory = $true)]
        [string]$csvOutPath,
        [Parameter(Mandatory = $true)]
        [string]$csvOutPath2,
        [Parameter(Mandatory = $true)]
        [string]$key
    )

    $enrichedData = @() # Empty array to collect enriched data
    $products = @()

    $csvContent = Import-Csv -Path $csvPath

    $itemNumber = 0

    foreach ($row in $csvContent) {
        #$searchTerm = (("$($row.scale) $($row.manufacturer) $($row.item)").Trim()).Replace("  ", " ")
        $searchTerm = (($row.item).Trim()).Replace("  ", " ")
        
        $headers = @{}
        $headers.Add("content-type", "application/json")
        $headers.Add("X-RapidAPI-Key", $key)
        $headers.Add("X-RapidAPI-Host", "ebay-average-selling-price.p.rapidapi.com")
        
        # "category_id"        = "220"

        $body = @{
            "keywords"           = $searchTerm
            "excluded_keywords"  = ""
            "max_search_results" = "5"
            "max_pages"          = "5"
            "remove_outliers"    = "true"
            "site_id"            = "0"
        } | ConvertTo-Json

        $rapidApiResponse = Invoke-RestMethod -Uri 'https://ebay-average-selling-price.p.rapidapi.com/findCompletedItems' -Method POST -Headers $headers -ContentType 'application/json' -Body $body
        $rapidApiResponse
        
        $itemNumber++

        $listings = ($rapidApiResponse | select -expand products | Select -first 5)

        foreach ($item in $listings) {
            $products += [PSCustomObject]@{
                Key    = $($itemNumber)
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

        $row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value "$($rapidApiResponse.average_price)" -Force
        $row | Add-Member -Name "MedianPrice" -MemberType NoteProperty -Value "$($rapidApiResponse.median_price)" -Force
        $row | Add-Member -Name "MinimumPrice" -MemberType NoteProperty -Value "$($rapidApiResponse.min_price)" -Force
        $row | Add-Member -Name "MaximumPrice" -MemberType NoteProperty -Value "$($rapidApiResponse.max_price)" -Force
        $row | Add-Member -Name "Key" -MemberType NoteProperty -Value $itemNumber -Force
        $enrichedData += $row

    }
    $enrichedData | Export-Csv -Path $csvOutPath -NoTypeInformation
    $products | Export-Csv -Path $csvOutPath2 -NoTypeInformation
}