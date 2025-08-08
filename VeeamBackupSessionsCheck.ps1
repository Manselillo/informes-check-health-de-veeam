# VeeamBackupSessionsCheck.ps1
# Script to extract information about Veeam Backup sessions and their status
# Author: OpenHands

# Parameters for the script
param (
    [string]$OutputFolder = ".\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [int]$Days = 7
)

# Function to get Veeam backup sessions information
function Get-VeeamBackupSessionsInfo {
    param (
        [string]$OutputPath = ".\VeeamBackupSessions.csv",
        [int]$Days = 7
    )
    
    Write-Host "Extracting Veeam backup sessions information for the last $Days days..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Calculate the start date
        $startDate = (Get-Date).AddDays(-$Days)
        
        # Get all backup sessions for the specified period
        $sessions = Get-VBRBackupSession | Where-Object { $_.CreationTime -ge $startDate }
        
        if ($sessions) {
            $sessionDetails = @()
            
            foreach ($session in $sessions) {
                # Get job name
                $jobName = if ($session.JobName) { $session.JobName } else { "N/A" }
                
                # Calculate duration
                $duration = if ($session.EndTime) {
                    ($session.EndTime - $session.CreationTime).ToString()
                } else {
                    "Running or Failed"
                }
                
                # Calculate processed size in GB
                $processedGB = if ($session.Progress.ProcessedSize -gt 0) {
                    [math]::Round($session.Progress.ProcessedSize / 1GB, 2)
                } else {
                    0
                }
                
                # Calculate backup size in GB
                $backupSizeGB = if ($session.BackupStats.BackupSize -gt 0) {
                    [math]::Round($session.BackupStats.BackupSize / 1GB, 2)
                } else {
                    0
                }
                
                # Calculate data read in GB
                $dataReadGB = if ($session.Progress.ReadSize -gt 0) {
                    [math]::Round($session.Progress.ReadSize / 1GB, 2)
                } else {
                    0
                }
                
                # Calculate data transferred in GB
                $dataTransferredGB = if ($session.Progress.TransferedSize -gt 0) {
                    [math]::Round($session.Progress.TransferedSize / 1GB, 2)
                } else {
                    0
                }
                
                # Calculate dedupe ratio
                $dedupeRatio = if ($session.BackupStats.DedupRatio -gt 0) {
                    [math]::Round($session.BackupStats.DedupRatio, 2)
                } else {
                    0
                }
                
                # Calculate compression ratio
                $compressionRatio = if ($session.BackupStats.CompressRatio -gt 0) {
                    [math]::Round($session.BackupStats.CompressRatio, 2)
                } else {
                    0
                }
                
                $sessionDetail = [PSCustomObject]@{
                    JobName = $jobName
                    JobType = $session.JobType
                    CreationTime = $session.CreationTime
                    EndTime = if ($session.EndTime) { $session.EndTime } else { "Running or Failed" }
                    Duration = $duration
                    Result = $session.Result
                    State = $session.State
                    ProcessedObjects = $session.Progress.ProcessedObjects
                    TotalObjects = $session.Progress.TotalObjects
                    ProcessedSizeGB = $processedGB
                    BackupSizeGB = $backupSizeGB
                    DataReadGB = $dataReadGB
                    DataTransferredGB = $dataTransferredGB
                    DedupeRatio = $dedupeRatio
                    CompressionRatio = $compressionRatio
                    BottleneckCPU = $session.Progress.BottleneckCpu
                    BottleneckNetwork = $session.Progress.BottleneckNetwork
                    BottleneckSource = $session.Progress.BottleneckSource
                    BottleneckTarget = $session.Progress.BottleneckTarget
                    BottleneckProxy = $session.Progress.BottleneckProxy
                    IsRetry = $session.IsRetryMode
                    IsWorking = $session.IsWorking
                }
                
                $sessionDetails += $sessionDetail
            }
            
            # Export to CSV
            $sessionDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Backup sessions information exported to $OutputPath" -ForegroundColor Green
            Write-Host "Total backup sessions found: $($sessionDetails.Count)" -ForegroundColor Yellow
            
            # Generate summary statistics
            $successCount = ($sessionDetails | Where-Object { $_.Result -eq "Success" }).Count
            $warningCount = ($sessionDetails | Where-Object { $_.Result -eq "Warning" }).Count
            $failedCount = ($sessionDetails | Where-Object { $_.Result -eq "Failed" }).Count
            $runningCount = ($sessionDetails | Where-Object { $_.State -eq "Working" }).Count
            
            Write-Host "`nSummary for the last $Days days:" -ForegroundColor Cyan
            Write-Host "Success: $successCount" -ForegroundColor Green
            Write-Host "Warning: $warningCount" -ForegroundColor Yellow
            Write-Host "Failed: $failedCount" -ForegroundColor Red
            Write-Host "Running: $runningCount" -ForegroundColor Blue
            
            # Export summary to CSV
            $summary = [PSCustomObject]@{
                Period = "Last $Days days"
                TotalSessions = $sessionDetails.Count
                SuccessCount = $successCount
                WarningCount = $warningCount
                FailedCount = $failedCount
                RunningCount = $runningCount
                SuccessRate = if ($sessionDetails.Count -gt 0) {
                    [math]::Round(($successCount / $sessionDetails.Count) * 100, 2)
                } else { 0 }
            }
            
            $summary | Export-Csv -Path "$($OutputPath.Replace('.csv', '_Summary.csv'))" -NoTypeInformation
            Write-Host "Summary information exported to $($OutputPath.Replace('.csv', '_Summary.csv'))" -ForegroundColor Green
            
            return $sessionDetails
        } else {
            Write-Host "No backup sessions found for the last $Days days." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "Error getting backup sessions information: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamBackupSessionsInfo"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Function to get detailed information about failed sessions
function Get-VeeamFailedSessionsDetails {
    param (
        [string]$OutputPath = ".\VeeamFailedSessions.csv",
        [int]$Days = 7
    )
    
    Write-Host "Extracting detailed information about failed Veeam backup sessions for the last $Days days..." -ForegroundColor Cyan
    
    try {
        # Check if Veeam module is loaded
        if (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Try to import the module
            Import-Module Veeam.Backup.PowerShell -ErrorAction Stop
        }
        
        # Calculate the start date
        $startDate = (Get-Date).AddDays(-$Days)
        
        # Get all failed backup sessions for the specified period
        $failedSessions = Get-VBRBackupSession | Where-Object { 
            $_.CreationTime -ge $startDate -and 
            ($_.Result -eq "Failed" -or $_.Result -eq "Warning")
        }
        
        if ($failedSessions) {
            $failedSessionDetails = @()
            
            foreach ($session in $failedSessions) {
                # Get job name
                $jobName = if ($session.JobName) { $session.JobName } else { "N/A" }
                
                # Get task sessions
                $taskSessions = Get-VBRTaskSession -Session $session
                
                if ($taskSessions) {
                    foreach ($task in $taskSessions | Where-Object { $_.Status -eq "Failed" -or $_.Status -eq "Warning" }) {
                        $failedSessionDetail = [PSCustomObject]@{
                            JobName = $jobName
                            JobType = $session.JobType
                            SessionCreationTime = $session.CreationTime
                            SessionEndTime = if ($session.EndTime) { $session.EndTime } else { "Running or Failed" }
                            SessionResult = $session.Result
                            TaskName = $task.Name
                            TaskStatus = $task.Status
                            TaskStartTime = $task.Progress.StartTimeUTC
                            TaskStopTime = $task.Progress.StopTimeUTC
                            ErrorMessage = if ($task.Logger.GetLog().Error) { $task.Logger.GetLog().Error } else { "No specific error message" }
                            WarningMessage = if ($task.Logger.GetLog().Warning) { $task.Logger.GetLog().Warning } else { "No specific warning message" }
                        }
                        
                        $failedSessionDetails += $failedSessionDetail
                    }
                } else {
                    # If no task sessions are found, add the session level information
                    $failedSessionDetail = [PSCustomObject]@{
                        JobName = $jobName
                        JobType = $session.JobType
                        SessionCreationTime = $session.CreationTime
                        SessionEndTime = if ($session.EndTime) { $session.EndTime } else { "Running or Failed" }
                        SessionResult = $session.Result
                        TaskName = "N/A"
                        TaskStatus = "N/A"
                        TaskStartTime = "N/A"
                        TaskStopTime = "N/A"
                        ErrorMessage = "No specific error message at task level"
                        WarningMessage = "No specific warning message at task level"
                    }
                    
                    $failedSessionDetails += $failedSessionDetail
                }
            }
            
            # Export to CSV
            $failedSessionDetails | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Failed backup sessions details exported to $OutputPath" -ForegroundColor Green
            Write-Host "Total failed tasks found: $($failedSessionDetails.Count)" -ForegroundColor Yellow
            
            return $failedSessionDetails
        } else {
            Write-Host "No failed backup sessions found for the last $Days days." -ForegroundColor Green
            return $null
        }
    }
    catch {
        Write-Host "Error getting failed backup sessions details: $_" -ForegroundColor Red
        
        # Create an error report
        $errorInfo = [PSCustomObject]@{
            Error = $_.Exception.Message
            ScriptSection = "Get-VeeamFailedSessionsDetails"
            Recommendation = "Ensure Veeam Backup & Replication is installed and you have appropriate permissions."
        }
        
        $errorInfo | Export-Csv -Path "$($OutputPath)_Error.csv" -NoTypeInformation
        Write-Host "Error details exported to $($OutputPath)_Error.csv" -ForegroundColor Yellow
        
        return $null
    }
}

# Main execution block
function Start-VeeamBackupSessionsCheck {
    param (
        [string]$OutputFolder = ".\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
        [int]$Days = 7
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
    
    # Get backup sessions information
    $sessionsInfo = Get-VeeamBackupSessionsInfo -OutputPath "$OutputFolder\VeeamBackupSessions.csv" -Days $Days
    
    # Get failed sessions details
    $failedSessionsDetails = Get-VeeamFailedSessionsDetails -OutputPath "$OutputFolder\VeeamFailedSessions.csv" -Days $Days
    
    Write-Host "`nVeeam Backup Sessions Check completed. Results saved to $OutputFolder" -ForegroundColor Cyan
}

# Execute the backup sessions check if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    Start-VeeamBackupSessionsCheck -OutputFolder $OutputFolder -Days $Days
}