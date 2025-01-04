Clear-Host

# Check if the Invoke-SqlCmd command is available
$SqlCmd = (Get-Command -ModuleName sqlserver -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Invoke-Sqlcmd" }).Name

if ($null -eq $SqlCmd) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Invoke-SqlCmd module not installed. Installing SqlServer PowerShell module..." -ForegroundColor White

    try {
        # Ensure NuGet provider is installed
        Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force -ErrorAction Stop -Verbose
        # Install SqlServer module
        Install-Module -Name SqlServer -Force -ErrorAction Stop -Verbose
        Write-Host "SqlServer PowerShell module installation completed." -ForegroundColor Green
    } catch {
        # Handle exceptions
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Re-check if Invoke-SqlCmd is available after installation
    $SqlCmd = (Get-Command -ModuleName sqlserver -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Invoke-Sqlcmd" }).Name
    if ($null -eq $SqlCmd) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Unable to find SqlServer module. Command execution terminated." -ForegroundColor Red
        return
    } else {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Invoke-SqlCmd module successfully installed." -ForegroundColor Green
        Get-Command -ModuleName sqlserver | Where-Object { $_.Name -eq "Invoke-Sqlcmd" } | Format-Table -AutoSize
    }
} else {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') | Invoke-SqlCmd module is already installed on the server." -ForegroundColor Green
    Get-Command -ModuleName sqlserver | Where-Object { $_.Name -eq "Invoke-Sqlcmd" } | Format-Table -AutoSize
}
