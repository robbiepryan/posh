<#
.SYNOPSIS
This PowerShell script calculates and reports the average price of items listed on eBay based on input from a CSV file.

.DESCRIPTION
The script is designed to take a CSV file as input, which should contain information about various items. It uses the eBay API to fetch the current listings for each item and calculates the average price. The average price is then appended to the original data and exported to a new CSV file. 

In addition to this, the script also exports a separate CSV file containing detailed information about the current listings for each item. This includes the title, condition, total price, sale price, shipping price, buying format, creation date, end date, image URL, and link for each item.

.PARAMETER csvPath
This parameter specifies the path to the input CSV file. The CSV file should contain information about the items for which the average price needs to be calculated.

.PARAMETER AveragePriceOutput
This parameter specifies the path to the output CSV file where the enriched data with average prices will be stored. The output file will contain the original data from the input CSV file, along with the calculated average price for each item.

.PARAMETER CurrentListingOutput
This parameter specifies the path to the output CSV file where the detailed information about the current listings for each item will be stored. This file will contain detailed information about each item's current listings on eBay.

.PARAMETER eBayToken
This parameter is for the eBay API token. This token is necessary for making requests to the eBay API.

.PARAMETER OpenAIKey
This parameter is for the OpenAI API key. This key is used when the script needs to generate refined search queries using the OpenAI API.

.EXAMPLE
PS C:\> .\Get-AverageItemPrice.ps1 -csvPath "C:\input.csv" -AveragePriceOutput "C:\output.csv" -CurrentListingOutput "C:\listings.csv" -eBayToken "your-ebay-api-token" -OpenAIKey "your-openai-api-key"

This example demonstrates how to run the script with all parameters. Replace "your-ebay-api-token" and "your-openai-api-key" with your actual eBay and OpenAI API keys, respectively.
#>
function Get-AverageItemPrice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$csvPath,
        [Parameter(Mandatory = $true)]
        [string]$AveragePriceOutput,
        [Parameter(Mandatory = $true)]
        [string]$CurrentListingOutput,
        [Parameter(Mandatory = $true)]
        [string]$eBayToken,
        [Parameter(Mandatory = $true)]
        [string]$OpenAIKey
    )

# Define headers for the eBay API request
$headers = @{
    "Authorization"       = "Bearer $eBayToken"
    "Content-Type"        = "application/json"
    "X-EBAY-C-ENDUSERCTX" = "contextualLocation=country=US,zip=32119"
}

# Initialize empty arrays to collect enriched data and product details
$enrichedData = @()
$products = @()

$csvContent = Import-Csv -Path $csvPath

$itemNumber = 0

# Process each row in the CSV file
foreach ($row in $csvContent) {
    $itemNumber++

    Write-Host -foregroundcolor yellow "Processing row $itemNumber..."
    $searchTerm = ((("$($row.Scale) $($row.Manufacturer) $($row.item)").Trim() -replace '[/\\#]', '').Replace("  ", " "))
    Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
    $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=5&offset=0" -Method Get -Headers $headers
        
    if ($null -eq $response.itemSummaries) {
        $searchTerm = ((("$($row.Manufacturer) $($row.item)").Trim() -replace '[/\\#]', '').Replace("  ", " "))
        Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
        $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=5&offset=0" -Method Get -Headers $headers
    }

    if ($null -eq $response.itemSummaries) {
        $searchTerm = ((("$($row.item)").Trim() -replace '[/\\#]', '').Replace("  ", " "))
        Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
        $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=5&offset=0" -Method Get -Headers $headers
    }

    if ($null -eq $response.itemSummaries) {
        $searchTerm = ((("$($row.Scale) $($row.Manufacturer) $($row.item)").Trim() -replace '[/\\#]', '').Replace("  ", " "))
        $OpenAIHeaders = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $OpenAIKey"
        }
        $Body = @{
            "model"             = "gpt-3.5-turbo-16k-0613"
            "messages"          = @( @{
                    "role"    = "system"
                    # "content" = "You are an eBay API assistant. Your task is to generate 30 refined search queries based on the initial input. Expand all abbreviations. The first query should contain all keywords from the initial input. Each subsequent query should have the least important word removed from the previous query. The output should be the new search queries only, separated by commas."
                    "content" = "You are an eBay API assistant. Your task is to generate 30 refined search queries based on the initial input. Expand all abbreviations. The first query should contain all keywords from the initial input as well as the most likely product description. Each subsequent query should have the least important word removed from the previous query. The output should be the new search queries only, separated by commas."
                },
                @{
                    "role"    = "user"
                    "content" = "$searchTerm"
                },
                @{
                    "role"    = "assistant"
                    "content" = ""
                })
            "temperature"       = 0
            'top_p'             = 1.0
            'frequency_penalty' = 0.0
            'presence_penalty'  = 0.0
            'stop'              = @('"""')
        } | ConvertTo-Json
            
        try {
            $OpenAICall = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Body $Body -Headers $OpenAIHeaders
            $searchTerms = ($OpenAICall.choices.message.content -replace '\d+\.' -split "[,`n]" | Where-Object { $_.Trim() -ne "" }).Trim() | Select-Object -last 30
        }
        catch {
            Write-Error "$($_.Exception.Message)"
        }
        
        foreach ($searchTerm in $searchTerms) {
            if ($null -eq $response.itemSummaries) {
                "AI Generated: $searchTerm"
                Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
                $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=5&offset=0" -Method Get -Headers $headers
            }
        }
    }


    # Calculate the average price of the item
    $averagePrice = [decimal]($response.itemSummaries.price.value | Measure-Object -Average).Average + [decimal]($response.itemSummaries.shippingOptions.shippingCost.value | Measure-Object -Average).Average
    Write-Host -foregroundcolor yellow "Average price calculated: $averagePrice"

    # Get the current listings for the item
    $listings = ($response | Select-Object -expand itemSummaries)

    # Process each listing and add it to the products array
    foreach ($item in $listings) {
        Write-Host -foregroundcolor yellow "Processing listing: $($item.title)..."
        $products += [PSCustomObject]@{
            Key           = $($itemNumber)
            Title         = $($item.title)
            Condition     = $($item.condition)
            TotalPrice    = [decimal]$($item.price.value) + [decimal]$($item.shippingOptions.shippingCost.value)
            SalePrice     = $($item.price.value)
            ShippingPrice = $($item.shippingOptions.shippingCost.value)
            BuyingFormat  = $($item.buyingOptions) -join ", "
            CreationDate  = $($item.itemCreationDate)
            EndDate       = $($item.itemEndDate)
            ImageUrl      = $($item.thumbnailImages.imageUrl)
            Link          = $($item.itemWebUrl)
            SearchTerm    = $searchTerm
        }
    }

    # Add the average price to the original data
    $row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value "$averagePrice" -Force
    $row | Add-Member -Name "Key" -MemberType NoteProperty -Value $itemNumber -Force
    $enrichedData += $row
    Write-Host -foregroundcolor yellow "Row $itemNumber processed."
}

# Export the enriched data and the product details to CSV files
Write-Host -foregroundcolor yellow "Exporting enriched data to CSV..."
$enrichedData | Export-Csv -Path $AveragePriceOutput -NoTypeInformation
Write-Host -foregroundcolor yellow "Exporting products to CSV..."
$products | Export-Csv -Path $CurrentListingOutput -NoTypeInformation
Write-Host -foregroundcolor yellow "Processing completed."

# Return the enriched data and the product details
$enrichedData
$products
}


<# Downloading Images from their URLs in Excel #######################################################################

Set Cell size first!

In Excel, you can use VBA (Visual Basic for Applications) to achieve this. Here's a simple example of how you can do it:

1. Press Alt + F11 to open the VBA editor.
2. Click Insert -> Module to create a new module.
3. Copy and paste the following code into the module:

```vba
Sub InsertImages()
    Dim rng As Range
    Dim cell As Range
    Set rng = ThisWorkbook.Sheets("CurrentListings").Range("J2:J1723") ' Change to your range

    For Each cell In rng
        If cell.Value Like "http*" Then
            Dim pic As Picture
            Set pic = cell.Parent.Pictures.Insert(cell.Value)
            
            ' Maintain aspect ratio
            pic.ShapeRange.LockAspectRatio = msoTrue
            
            ' Set height to match the cell, width will adjust automatically
            pic.Height = cell.Height
            
            ' Position the picture in the cell
            pic.Top = cell.Top
            pic.Left = cell.Left
            
            ' Clear the cell content
            cell.ClearContents
        End If
    Next cell
End Sub
```
4. Press Ctrl + S to save, and then close the VBA editor.
5. Press Alt + F8, select InsertImages, and click Run.

#>

<# Convert text to hyperlinks in Excel #######################################################################

Sub ConvertToHyperlinks()
    Dim rng As Range
    Dim cell As Range
    Set rng = ThisWorkbook.Sheets("CurrentListings").Range("K2:K1723") ' Change to your range

    For Each cell In rng
        If InStr(cell.Value, "http") > 0 Then
            ActiveSheet.Hyperlinks.Add Anchor:=cell, Address:=cell.Value
        End If
    Next cell
End Sub

#>