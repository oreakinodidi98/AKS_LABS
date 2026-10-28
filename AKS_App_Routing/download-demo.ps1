##############################################################################
# Download the AKS App Routing Demo folder from GitHub
#
# Usage (paste into any PowerShell terminal):
#
#   irm https://raw.githubusercontent.com/oreakinodidi98/Demo_AKS_Modernization/main/AKS_App_Routing/download-demo.ps1 | iex
#
# Or manually:
#
#   .\download-demo.ps1
#   .\download-demo.ps1 -OutputDir "C:\Demos\AppRouting"
##############################################################################

param(
    [string]$OutputDir = (Join-Path $PWD "AKS_App_Routing")
)

$repo  = "oreakinodidi98/Demo_AKS_Modernization"
$branch = "main"
$folder = "AKS_App_Routing"
$baseUrl = "https://raw.githubusercontent.com/$repo/$branch/$folder"

$files = @(
    "app-deployment.yaml",
    "byo-nginx-values.yaml",
    "cleanup.ps1",
    "demo.md",
    "ingress.yaml",
    "ingressaddon.yaml",
    "notes.md",
    "setup.ps1"
)

Write-Host "Downloading AKS App Routing Demo..." -ForegroundColor Cyan
Write-Host "  Target: $OutputDir" -ForegroundColor DarkGray

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$success = 0
foreach ($file in $files) {
    $url  = "$baseUrl/$file"
    $dest = Join-Path $OutputDir $file
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Write-Host "  OK  $file" -ForegroundColor Green
        $success++
    } catch {
        Write-Host "  FAIL  $file ($($_.Exception.Message))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Downloaded $success/$($files.Count) files to $OutputDir" -ForegroundColor $(if($success -eq $files.Count){"Green"}else{"Yellow"})
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  cd '$OutputDir'"
Write-Host "  .\setup.ps1            # Run the demo (section by section)"
