# VeeamHealthCheck.ps1
# Script to check Veeam Backup environment health and export information to CSV
# Author: OpenHands

# Function to check if required modules are installed
function Test-VeeamModules {
    param (
        [string]$OutputPath = ".\VeeamModulesCheck.csv"
    )
    
    Write-Host "Checking for required Veeam PowerShell modules..." -ForegroundColor Cyan
    
    # List of required Veeam modules
    $requiredModules = @(
        "Veeam.Backup.PowerShell",
        "Veeam.Backup.Common.PowerShell"
    )
    
    $results = @()
    
    foreach ($module in $requiredModules) {
        $moduleInfo = Get-Module -Name $module -ListAvailable
        
        $result = [PSCustomObject]@{
            ModuleName = $module
            Installed = if ($moduleInfo) { $true } else { $false }
            Version = if ($moduleInfo) { $moduleInfo.Version.ToString() } else { "Not Installed" }
            Path = if ($moduleInfo) { $moduleInfo.Path } else { "N/A" }
        }
        
        $results += $result
        
        # Display in console
        if ($result.Installed) {
            Write-Host "Module $($result.ModuleName) is installed (Version: $($result.Version))" -ForegroundColor Green
        } else {
            Write-Host "Module $($result.ModuleName) is NOT installed" -ForegroundColor Red
        }
    }
    
    # Export results to CSV
    $results | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Module check results exported to $OutputPath" -ForegroundColor Cyan
    
    return $results
}

# Function to get Veeam license information
function Get-VeeamLicenseInfo {
    param (
        [string]$OutputPath = ".\VeeamLicenseInfo.csv"
    )
    
    Write-Host "Extracting Veeam license information..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Get license information
        $licenseInfo = Get-VBRInstalledLicense
        
        if ($licenseInfo) {
            # Create a custom object with the license details
            $licenseDetails = [PSCustomObject]@{
                LicenseStatus = $licenseInfo.Status
                LicenseType = $licenseInfo.Type
                LicenseEdition = $licenseInfo.Edition
                LicenseMode = $licenseInfo.Mode
                ExpirationDate = $licenseInfo.ExpirationDate
                DaysRemaining = if ($licenseInfo.ExpirationDate) { 
                    ($licenseInfo.ExpirationDate - (Get-Date)).Days 
                } else { 
                    "Perpetual" 
                }
                LicensedTo = $licenseInfo.LicensedTo
                SupportExpirationDate = $licenseInfo.SupportExpirationDate
                SupportID = $licenseInfo.SupportID
                AutoUpdateEnabled = $licenseInfo.AutoUpdateEnabled
                LicensedSockets = $licenseInfo.LicensedSockets
                UsedSockets = $licenseInfo.UsedSockets
                CloudConnectCapacityTB = $licenseInfo.CloudConnectCapacityTB
                CapacityTB = $licenseInfo.CapacityTB
                InstanceLicenseCount = $licenseInfo.InstanceLicenseCount
                UsedInstanceLicenseCount = $licenseInfo.UsedInstanceLicenseCount
                VULLicenseCount = $licenseInfo.VULLicenseCount
                UsedVULLicenseCount = $licenseInfo.UsedVULLicenseCount
                NASLicenseCount = $licenseInfo.NASLicenseCount
                UsedNASLicenseCount = $licenseInfo.UsedNASLicenseCount
                VeeamVersion = (Get-VBRVersion).ToString()
            }
            
            # Export to CSV
            $licenseDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "License information exported to $OutputPath" -ForegroundColor Green
            
            # Display summary in console
            Write-Host "`nVeeam License Summary:" -ForegroundColor Cyan
            Write-Host "Status: $($licenseDetails.LicenseStatus)" -ForegroundColor Yellow
            Write-Host "Type: $($licenseDetails.LicenseType)" -ForegroundColor Yellow
            Write-Host "Edition: $($licenseDetails.LicenseEdition)" -ForegroundColor Yellow
            Write-Host "Expiration Date: $($licenseDetails.ExpirationDate)" -ForegroundColor Yellow
            Write-Host "Days Remaining: $($licenseDetails.DaysRemaining)" -ForegroundColor Yellow
            Write-Host "Veeam Version: $($licenseDetails.VeeamVersion)" -ForegroundColor Yellow
            
            return $licenseDetails
        } else {
            Write-Host "No license information found." -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "Error getting license information: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamLicenseInfo"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Main execution block
function Start-VeeamHealthCheck {
    param (
        [string]$OutputFolder = ".\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    )
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory | Out-Null
        Write-Host "Created output folder: $OutputFolder" -ForegroundColor Green
    }
    
    # Check modules
    $moduleResults = Test-VeeamModules -OutputPath "$OutputFolder\VeeamModulesCheck.csv"
    
    # If required modules are installed, proceed with license check
    $requiredModulesInstalled = $moduleResults | Where-Object { $_.ModuleName -eq "Veeam.Backup.PowerShell" -and $_.Installed -eq $true }
    
    if ($requiredModulesInstalled) {
        $licenseInfo = Get-VeeamLicenseInfo -OutputPath "$OutputFolder\VeeamLicenseInfo.csv"
    } else {
        Write-Host "Required Veeam modules are not installed. Please install them before proceeding." -ForegroundColor Red
        Write-Host "You can install the modules by installing Veeam Backup & Replication or the Veeam PowerShell Toolkit." -ForegroundColor Yellow
    }
    
    Write-Host "`nVeeam Health Check completed. Results saved to $OutputFolder" -ForegroundColor Cyan
}

# Execute the health check
Start-VeeamHealthCheck