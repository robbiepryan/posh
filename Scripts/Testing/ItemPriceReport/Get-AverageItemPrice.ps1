<# TO DO
Include shipping price when calculating average price
Return more results
Include "autographed in the search term where applicable"
#>

#<delete> ################################################################################################################
Write-Host -foregroundcolor yellow "Setting up paths and token..."
$csvPath = "C:\csv.csv"
$csvOutPath = "C:\temp\Items.csv"
$csvOutPath2 = "C:\temp\CurrentListings.csv"
$token = "v^1.1#i^1#I^3#f^0#r^0#p^1#t^H4sIAAAAAAAAAOV*************************lzyPpqyGt4eLx5JVB1+tHn31pVW4t/wbFdBJz/REAAA=="
#</delete> ################################################################################################################

# function Get-AverageItemPrice {
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$csvPath,
#         [Parameter(Mandatory = $true)]
#         [string]$csvOutPath,
#         [Parameter(Mandatory = $true)]
#         [string]$csvOutPath2,
#         [Parameter(Mandatory = $true)]
#         [string]$token
#     )

$headers = @{
    "Authorization"       = "Bearer $token"
    "Content-Type"        = "application/json"
    "X-EBAY-C-ENDUSERCTX" = "contextualLocation=country=US,zip=32119"
}

$enrichedData = @() # Empty array to collect enriched data
$products = @()

$csvContent = Import-Csv -Path $csvPath

$itemNumber = 0

foreach ($row in $csvContent) {
    Write-Host -foregroundcolor yellow "Processing row $itemNumber..."
    $searchTerm = (($row.item).Trim() -replace '[/\\#]', '').Replace("  ", " ")
        
    $itemNumber++

    Write-Host -foregroundcolor yellow "Invoking REST method with search term: $searchTerm..."
    $response = Invoke-RestMethod -Uri "https://api.ebay.com/buy/browse/v1/item_summary/search?category_ids=220&q=$searchTerm&limit=2&offset=0" -Method Get -Headers $headers
        
    $averagePrice = ($response.itemSummaries.price.value | Measure-Object -Average).Average
    Write-Host -foregroundcolor yellow "Average price calculated: $averagePrice"

    $listings = ($response | Select-Object -expand itemSummaries)

    foreach ($item in $listings) {
        Write-Host -foregroundcolor yellow "Processing listing: $($item.title)..."
        $products += [PSCustomObject]@{
            Key           = $($itemNumber)
            Title         = $($item.title)
            SalePrice     = $($item.price.value)
            Condition     = $($item.condition)
            BuyingFormat  = $($item.buyingOptions) -join ", "
            CreationDate  = $($item.itemCreationDate)
            EndDate       = $($item.itemEndDate)
            ImageUrl      = $($item.thumbnailImages.imageUrl)
            ShippingPrice = $($item.shippingOptions.shippingCost.value)
            Link          = $($item.itemWebUrl)
        }
    }

    $row | Add-Member -Name "AveragePrice" -MemberType NoteProperty -Value "$averagePrice" -Force
    $row | Add-Member -Name "Key" -MemberType NoteProperty -Value $itemNumber -Force
    $enrichedData += $row
    Write-Host -foregroundcolor yellow "Row $itemNumber processed."
}
Write-Host -foregroundcolor yellow "Exporting enriched data to CSV..."
$enrichedData | Export-Csv -Path $csvOutPath -NoTypeInformation
Write-Host -foregroundcolor yellow "Exporting products to CSV..."
$products | Export-Csv -Path $csvOutPath2 -NoTypeInformation
Write-Host -foregroundcolor yellow "Processing completed."
$enrichedData
$products
#} ###################################################################### COMMENTED OUT FOR TESTING ################################################################


<# Downloading Images from their URLs in Excel #######################################################################

In Excel, you can use VBA (Visual Basic for Applications) to achieve this. Here's a simple example of how you can do it:

1. Press Alt + F11 to open the VBA editor.
2. Click Insert -> Module to create a new module.
3. Copy and paste the following code into the module:

```vba
Sub InsertImages()
    Dim rng As Range
    Dim cell As Range
    Set rng = ThisWorkbook.Sheets("Sheet1").Range("H2:H3") ' Change to your range

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
    Set rng = ThisWorkbook.Sheets("Sheet1").Range("A1:A10") ' Change to your range

    For Each cell In rng
        If InStr(cell.Value, "http") > 0 Then
            ActiveSheet.Hyperlinks.Add Anchor:=cell, Address:=cell.Value
        End If
    Next cell
End Sub

#>