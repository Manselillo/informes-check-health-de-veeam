# VeeamBackupJobsCheck.ps1
# Script to extract information about Veeam Backup jobs, repositories, and proxies
# Author: OpenHands

# Function to get Veeam backup jobs information
function Get-VeeamBackupJobsInfo {
    param (
        [string]$OutputPath = ".\VeeamBackupJobs.csv"
    )
    
    Write-Host "Extracting Veeam backup jobs information..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Get all backup jobs
        $backupJobs = Get-VBRJob
        
        if ($backupJobs) {
            $jobDetails = @()
            
            foreach ($job in $backupJobs) {
                # Get the last session for this job
                $lastSession = Get-VBRSession -Job $job -Last
                
                $jobDetail = [PSCustomObject]@{
                    JobName = $job.Name
                    JobType = $job.JobType
                    IsScheduleEnabled = $job.IsScheduleEnabled
                    ScheduleOptions = if ($job.ScheduleOptions) { $job.ScheduleOptions.OptionsString } else { "Not Scheduled" }
                    NextRun = if ($job.IsScheduleEnabled -and $job.ScheduleOptions) { $job.ScheduleOptions.NextRun } else { "Not Scheduled" }
                    LastRunTime = if ($lastSession) { $lastSession.CreationTime } else { "Never Run" }
                    LastResult = if ($lastSession) { $lastSession.Result } else { "Unknown" }
                    LastEndTime = if ($lastSession) { $lastSession.EndTime } else { "N/A" }
                    LastDuration = if ($lastSession) { 
                        if ($lastSession.EndTime) {
                            ($lastSession.EndTime - $lastSession.CreationTime).ToString()
                        } else {
                            "Running or Failed"
                        }
                    } else { "N/A" }
                    IsEnabled = $job.IsEnabled
                    Description = $job.Description
                    TargetRepositoryName = if ($job.TargetRepositoryId) { 
                        (Get-VBRBackupRepository | Where-Object { $_.Id -eq $job.TargetRepositoryId }).Name 
                    } else { "N/A" }
                }
                
                $jobDetails += $jobDetail
            }
            
            # Export to CSV
            $jobDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Backup jobs information exported to $OutputPath" -ForegroundColor Green
            Write-Host "Total backup jobs found: $($jobDetails.Count)" -ForegroundColor Yellow
            
            return $jobDetails
        } else {
            Write-Host "No backup jobs found." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "Error getting backup jobs information: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamBackupJobsInfo"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Function to get Veeam repositories information
function Get-VeeamRepositoriesInfo {
    param (
        [string]$OutputPath = ".\VeeamRepositories.csv"
    )
    
    Write-Host "Extracting Veeam repositories information..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Get all repositories
        $repositories = Get-VBRBackupRepository
        
        if ($repositories) {
            $repoDetails = @()
            
            foreach ($repo in $repositories) {
                $repoDetail = [PSCustomObject]@{
                    Name = $repo.Name
                    Type = $repo.Type
                    Path = $repo.Path
                    Host = $repo.Host.Name
                    FreeSpace = if ($repo.GetContainer().CachedFreeSpace -ne $null) { 
                        [math]::Round($repo.GetContainer().CachedFreeSpace / 1GB, 2) 
                    } else { 0 }
                    TotalSpace = if ($repo.GetContainer().CachedTotalSpace -ne $null) { 
                        [math]::Round($repo.GetContainer().CachedTotalSpace / 1GB, 2) 
                    } else { 0 }
                    FreePercentage = if ($repo.GetContainer().CachedTotalSpace -ne $null -and $repo.GetContainer().CachedTotalSpace -gt 0 -and $repo.GetContainer().CachedFreeSpace -ne $null) {
                        [math]::Round(($repo.GetContainer().CachedFreeSpace / $repo.GetContainer().CachedTotalSpace) * 100, 2)
                    } else { 0 }
                    IsUnavailable = $repo.IsUnavailable
                    MaxTasks = $repo.Options.MaxTaskCount
                    IsRotated = $repo.IsRotated
                    RetentionType = if ($repo.RetentionType) { $repo.RetentionType.ToString() } else { "N/A" }
                    IsDeduplicating = $repo.IsDeduplicating
                    IsEncryptionEnabled = $repo.IsEncryptionEnabled
                    Description = $repo.Description
                }
                
                $repoDetails += $repoDetail
            }
            
            # Export to CSV
            $repoDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Repositories information exported to $OutputPath" -ForegroundColor Green
            Write-Host "Total repositories found: $($repoDetails.Count)" -ForegroundColor Yellow
            
            return $repoDetails
        } else {
            Write-Host "No repositories found." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "Error getting repositories information: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamRepositoriesInfo"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Function to get Veeam proxies information
function Get-VeeamProxiesInfo {
    param (
        [string]$OutputPath = ".\VeeamProxies.csv"
    )
    
    Write-Host "Extracting Veeam proxies information..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Get all proxies
        $proxies = Get-VBRViProxy
        
        if ($proxies) {
            $proxyDetails = @()
            
            foreach ($proxy in $proxies) {
                $proxyDetail = [PSCustomObject]@{
                    Name = $proxy.Name
                    Type = $proxy.Type
                    Host = $proxy.Host.Name
                    IsDisabled = $proxy.IsDisabled
                    MaxTasks = $proxy.Options.MaxTaskCount
                    TransportMode = $proxy.Options.TransportMode
                    FailoverToNetwork = $proxy.Options.FailoverToNetworkMode
                    UseSsl = $proxy.UseSsl
                    Description = $proxy.Description
                    Status = if ($proxy.IsDisabled) { "Disabled" } else { "Enabled" }
                    Version = $proxy.Info.Version
                }
                
                $proxyDetails += $proxyDetail
            }
            
            # Export to CSV
            $proxyDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Proxies information exported to $OutputPath" -ForegroundColor Green
            Write-Host "Total proxies found: $($proxyDetails.Count)" -ForegroundColor Yellow
            
            return $proxyDetails
        } else {
            Write-Host "No proxies found." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "Error getting proxies information: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamProxiesInfo"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Main execution block
function Start-VeeamBackupComponentsCheck {
    param (
        [string]$OutputFolder = ".\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    )
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory | Out-Null
        Write-Host "Created output folder: $OutputFolder" -ForegroundColor Green
    }
    
    # Check if Veeam module is available
    if (-not (Get-Module -Name Veeam.Backup.PowerShell -ListAvailable)) {
        Write-Host "Veeam.Backup.PowerShell module is not installed. Please install Veeam Backup & Replication before proceeding." -ForegroundColor Red
        return
    }
    
    # Get backup jobs information
    $jobsInfo = Get-VeeamBackupJobsInfo -OutputPath "$OutputFolder\VeeamBackupJobs.csv"
    
    # Get repositories information
    $reposInfo = Get-VeeamRepositoriesInfo -OutputPath "$OutputFolder\VeeamRepositories.csv"
    
    # Get proxies information
    $proxiesInfo = Get-VeeamProxiesInfo -OutputPath "$OutputFolder\VeeamProxies.csv"
    
    Write-Host "`nVeeam Backup Components Check completed. Results saved to $OutputFolder" -ForegroundColor Cyan
}

# Execute the backup components check
Start-VeeamBackupComponentsCheck