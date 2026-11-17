#requires -Version 7.0
[CmdletBinding()]
param(
    [uri] $BaseUrl = 'http://localhost:5080'
)

$ErrorActionPreference = 'Stop'
$session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
$productID = $null
$productName = "Workshop-test-$([guid]::NewGuid().ToString('N').Substring(0, 10))"
$root = $BaseUrl.AbsoluteUri.TrimEnd('/')

function Request {
    param([string] $Path, [string] $Method = 'GET', [hashtable] $Body, $WebSession = $session)
    $options = @{
        Uri = "$root$Path"
        Method = $Method
        WebSession = $WebSession
        SkipHttpErrorCheck = $true
        TimeoutSec = 30
    }
    if ($Body) { $options.Body = $Body }
    Invoke-WebRequest @options
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
    Write-Output "PASS: $Message"
}

function Get-Token {
    param([string] $Path)
    $page = Request $Path
    if ($page.StatusCode -ne 200) { throw "Cannot load form at $Path (HTTP $($page.StatusCode))." }
    $match = [regex]::Match($page.Content, 'name="__RequestVerificationToken"[^>]*value="([^"]+)"')
    if (-not $match.Success) { throw "No antiforgery token found at $Path." }
    [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value)
}

function Submit-Form {
    param([string] $Path, [hashtable] $Body, [string] $TokenPath = $Path)
    $Body['__RequestVerificationToken'] = Get-Token $TokenPath
    Request -Path $Path -Method POST -Body $Body
}

try {
    foreach ($path in @('/health', '/', '/Products', '/Home/About', '/Home/Contact', '/Home/Store', '/Admin', '/Cart')) {
        $page = Request $path
        Assert-True ($page.StatusCode -eq 200) "$path responds successfully"
    }

    foreach ($asset in @('hero', 'croissant', 'sourdough', 'cake', 'cookie', 'bun', 'muffin')) {
        $photo = Request "/images/$asset.jpg"
        Assert-True ($photo.StatusCode -eq 200 -and $photo.Headers['Content-Type'] -match 'image/jpeg') "$asset photograph is served"
    }

    $blocked = Request -Path '/Admin/Create' -Method POST -Body @{ Name = 'No token' }
    Assert-True ($blocked.StatusCode -eq 400) 'POST without antiforgery token is rejected'

    $invalid = Submit-Form '/Admin/Create' @{
        Name = $productName; Price = '-1'; Image = '/images/cookie.jpg'; Description = 'Invalid test'; Category = 'Cookies'
    }
    Assert-True ($invalid.StatusCode -eq 200 -and $invalid.Content -match 'validation-summary-errors') 'Invalid product price is rejected'

    $created = Submit-Form '/Admin/Create' @{
        Name = $productName; Price = '7.25'; Image = '/images/cookie.jpg'; Description = 'Fictional smoke test bake'; Category = 'Cookies'
    }
    Assert-True ($created.StatusCode -eq 200 -and $created.Content.Contains($productName)) 'Product is created'
    $catalog = Request "/Products?search=$productName"
    $match = [regex]::Match($catalog.Content, 'href="/Products/Details/(\d+)"')
    if (-not $match.Success) { throw 'Cannot find created product ID in filtered catalog.' }
    $productID = [int] $match.Groups[1].Value
    Assert-True ($catalog.Content.Contains($productName)) 'Catalog search returns the created product'

    $edited = Submit-Form "/Admin/Edit/$productID" @{
        ID = $productID; Name = $productName; Price = '8.50'; Image = '/images/cookie.jpg'; Description = 'Updated smoke test bake'; Category = 'Cookies'
    }
    Assert-True ($edited.StatusCode -eq 200 -and $edited.Content.Contains('$8.50')) 'Product edit updates the stored price'

    $invalidQuantity = Submit-Form "/Cart/Add/$productID" @{ quantity = '100' } '/Products'
    Assert-True ($invalidQuantity.StatusCode -eq 400) 'Quantity above 99 is rejected'
    $malformedQuantity = Submit-Form "/Cart/Add/$productID" @{ quantity = 'abc' } '/Products'
    Assert-True ($malformedQuantity.StatusCode -eq 400) 'Non-numeric quantity is rejected'
    $basket = Submit-Form "/Cart/Add/$productID" @{ quantity = '2' } '/Products'
    Assert-True ($basket.StatusCode -eq 200 -and $basket.Content.Contains('$17.00')) 'Basket calculates two products at the SQL price'
    $updated = Submit-Form "/Cart/Update/$productID" @{ quantity = '3' } '/Cart'
    Assert-True ($updated.Content.Contains('$25.50')) 'Quantity updates recalculate the basket total'
    $removed = Submit-Form "/Cart/Remove/$productID" @{} '/Cart'
    Assert-True (-not $removed.Content.Contains('class="cart-line"')) 'Removing an item empties the basket'
    $basket = Submit-Form "/Cart/Add/$productID" @{ quantity = '2' } '/Products'
    Assert-True ($basket.Content.Contains('$17.00')) 'Product can be re-added before checkout'

    $invalidCheckout = Submit-Form '/Orders/Checkout' @{ CustomerName = ''; Email = 'not-email'; Notes = '' }
    Assert-True ($invalidCheckout.Content -match 'validation-summary-errors') 'Checkout validates required contact fields'
    $receipt = Submit-Form '/Orders/Checkout' @{
        CustomerName = 'Workshop Test'; Email = 'test@example.invalid'; Notes = 'Automated demo only'
    }
    Assert-True ($receipt.StatusCode -eq 200 -and $receipt.Content.Contains('Your demo order has been saved.')) 'Checkout persists an order'
    Assert-True ($receipt.Content.Contains('$17.00')) 'Order summary preserves server-calculated total'
    $empty = Request '/Cart'
    Assert-True (-not $empty.Content.Contains('class="cart-line"')) 'Checkout clears the session basket'

    $otherSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
    $privateReceipt = Request -Path '/Orders/Summary' -WebSession $otherSession
    Assert-True (-not $privateReceipt.Content.Contains('Workshop Test')) 'Another session cannot read the order summary'

    $deleted = Submit-Form "/Admin/Delete/$productID" @{} "/Admin/Delete/$productID"
    Assert-True ($deleted.StatusCode -eq 200 -and -not $deleted.Content.Contains($productName)) 'Delete removes the product'
    $missing = Request "/Products/Details/$productID"
    Assert-True ($missing.StatusCode -eq 404) 'Deleted product detail returns 404'
    $summary = Request '/Orders/Summary'
    Assert-True ($summary.Content.Contains($productName) -and $summary.Content.Contains('$17.00')) 'Product deletion preserves the order snapshot'
    $productID = $null
    Write-Output 'All Caldova Bakery smoke checks passed. One fictional order remains in SQL Server.'
}
finally {
    if ($null -ne $productID) {
        try { $null = Submit-Form "/Admin/Delete/$productID" @{} "/Admin/Delete/$productID" }
        catch { Write-Warning "Could not remove test product ID $productID. Remove it in /Admin. $($_.Exception.Message)" }
    }
}