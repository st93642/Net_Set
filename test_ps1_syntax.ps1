# Simple PowerShell syntax check
try {
    . ".\net_set_ui.ps1" -ErrorAction Stop
    Write-Host "✓ Windows UI script syntax is valid after display fixes" -ForegroundColor Green
} catch {
    Write-Host "✗ Windows UI script has syntax errors:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
