param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$AccountName,
    [switch]$Unmasked,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Mask-Key {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    if ($Value.Length -le 8) {
        return ("*" * $Value.Length)
    }

    return ("{0}{1}" -f ("*" * ($Value.Length - 4)), $Value.Substring($Value.Length - 4))
}

function Require-AzCli {
    $azCmd = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azCmd) {
        throw "Azure CLI (az) is required but was not found in PATH."
    }
}

function Invoke-AzJson {
    param([string[]]$Arguments)

    $output = & az @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        $joined = ($Arguments -join " ")
        throw "Azure CLI command failed: az $joined"
    }

    if ([string]::IsNullOrWhiteSpace($output)) {
        return $null
    }

    return ($output | ConvertFrom-Json)
}

Require-AzCli

if ($SubscriptionId) {
    & az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set subscription: $SubscriptionId"
    }
}

$target = $null

if ($AccountName -and $ResourceGroupName) {
    $target = [PSCustomObject]@{
        name          = $AccountName
        resourceGroup = $ResourceGroupName
        kind          = "(provided)"
        location      = "(provided)"
    }
} else {
    $accounts = Invoke-AzJson -Arguments @("cognitiveservices", "account", "list", "-o", "json")

    if (-not $accounts -or $accounts.Count -eq 0) {
        throw "No Azure Cognitive/AI accounts were found in the active subscription."
    }

    $rows = @()
    for ($i = 0; $i -lt $accounts.Count; $i++) {
        $a = $accounts[$i]
        $rows += [PSCustomObject]@{
            index         = $i
            name          = $a.name
            resourceGroup = $a.resourceGroup
            kind          = $a.kind
            location      = $a.location
        }
    }

    Write-Host ""
    Write-Host "Available AI/Cognitive accounts:" -ForegroundColor Cyan
    $rows | Format-Table -AutoSize
    Write-Host ""

    $selection = Read-Host "Enter account index (or press Enter to cancel)"
    if ([string]::IsNullOrWhiteSpace($selection)) {
        Write-Host "Cancelled."
        exit 0
    }

    if (-not [int]::TryParse($selection, [ref]$null)) {
        throw "Selection must be a valid numeric index."
    }

    $selectedIndex = [int]$selection
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $rows.Count) {
        throw "Selection out of range."
    }

    $target = $rows[$selectedIndex]
}

$keys = Invoke-AzJson -Arguments @(
    "cognitiveservices", "account", "keys", "list",
    "--resource-group", $target.resourceGroup,
    "--name", $target.name,
    "-o", "json"
)

if (-not $keys) {
    throw "No keys were returned for account '$($target.name)'."
}

$showRaw = $Unmasked.IsPresent

$result = [PSCustomObject]@{
    subscriptionId = (& az account show --query id -o tsv)
    accountName    = $target.name
    resourceGroup  = $target.resourceGroup
    key1           = $(if ($showRaw) { $keys.key1 } else { Mask-Key $keys.key1 })
    key2           = $(if ($showRaw) { $keys.key2 } else { Mask-Key $keys.key2 })
    note           = $(if ($showRaw) { "Unmasked output enabled." } else { "Use -Unmasked to print full keys." })
}

Write-Host ""
Write-Host "API keys:" -ForegroundColor Green

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    $result | Format-List
}
