<#
.SYNOPSIS
This script calculates the average price of items listed on eBay.

.DESCRIPTION
The script takes a CSV file as input, which contains information about various items. It then uses the eBay API to fetch the current listings for each item and calculates the average price. The average price is then added to the original data and exported to a new CSV file. Additionally, the script also exports a CSV file containing detailed information about the current listings for each item.

.PARAMETER csvPath
Path to the input CSV file.

.PARAMETER AveragePriceOutput
Path to the output CSV file where the enriched data will be stored.

.PARAMETER CurrentListingOutput
Path to the output CSV file where the current listings will be stored.

.PARAMETER token
eBay API token.

.EXAMPLE
PS C:\> .\Get-AverageItemPrice.ps1 -csvPath "C:\input.csv" -AveragePriceOutput "C:\output.csv" -CurrentListingOutput "C:\listings.csv" -token "your-ebay-api-token"

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
        [string]$token
    )

    # Define headers for the eBay API request
    $headers = @{
        "Authorization"       = "Bearer $token"
        "Content-Type"        = "application/json"
        "X-EBAY-C-ENDUSERCTX" = "contextualLocation=country=US,zip=32119"
    }

    # Initialize empty arrays to collect enriched data and product details
    $enrichedData = @()
    $products = @()

    # Import the CSV file and select the first 3 rows after skipping 26 rows
    $csvContent = Import-Csv -Path $csvPath | Select-Object -First 3 -Skip 26

    $itemNumber = 0

    # Process each row in the CSV file
    foreach ($row in $csvContent) {
        Write-Host -foregroundcolor yellow "Processing row $itemNumber..."
        if ($row.Signed) {
            $searchTerm = (("Autographed " + $row.item).Trim() -replace '[/\\#]', '').Replace("  ", " ")
        }
        else {
            $searchTerm = (($row.item).Trim() -replace '[/\\#]', '').Replace("  ", " ")
        }
        
        $itemNumber++

        Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
        $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=5&offset=0" -Method Get -Headers $headers
        
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
    Set rng = ThisWorkbook.Sheets("Top5-CurrentListings").Range("H2:H1423") ' Change to your range

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
    Set rng = ThisWorkbook.Sheets("Top5-CurrentListings").Range("J2:J1423") ' Change to your range

    For Each cell In rng
        If InStr(cell.Value, "http") > 0 Then
            ActiveSheet.Hyperlinks.Add Anchor:=cell, Address:=cell.Value
        End If
    Next cell
End Sub

#>