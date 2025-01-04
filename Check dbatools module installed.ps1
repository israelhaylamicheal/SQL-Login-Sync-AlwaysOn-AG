Clear-Host
# Check if any DBATools commands are available
$DBAToolsCmd = (Get-Command -ModuleName dbatools -ErrorAction SilentlyContinue | Select-Object -First 1).Name

if ($null -eq $DBAToolsCmd) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | DBATools module not installed. Installing DBATools PowerShell module..." -ForegroundColor White

    try {
        # Ensure NuGet provider is installed
        Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force -ErrorAction Stop -Verbose
        # Install DBATools module
        Install-Module -Name DBATools -Force -ErrorAction Stop -Verbose
        Write-Host "DBATools PowerShell module installation completed." -ForegroundColor Green
    } catch {
        # Handle exceptions
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Re-check if DBATools commands are available after installation
    $DBAToolsCmd = (Get-Command -ModuleName dbatools -ErrorAction SilentlyContinue | Select-Object -First 1).Name
    if ($null -eq $DBAToolsCmd) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Unable to find DBATools module. Command execution terminated." -ForegroundColor Red
        return
    } else {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | DBATools module successfully installed." -ForegroundColor Green
        Get-Command -ModuleName dbatools | Format-Table -AutoSize
    }
} else {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | DBATools module is already installed on the server." -ForegroundColor Green
    Get-Command -ModuleName dbatools | SELECT-Object -First 10 | Format-Table -AutoSize
}
