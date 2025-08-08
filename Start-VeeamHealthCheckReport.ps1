# Start-VeeamHealthCheckReport.ps1
# Main script to run all Veeam health check scripts and generate a comprehensive report
# Author: OpenHands

# Parameters for the script
param (
    [string]$OutputFolder = "C:\CheckHealthVeeam\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [switch]$NoHTMLReport,
    [int]$SessionDays = 7
)

# Import the other scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\VeeamHealthCheck.ps1"
. "$scriptPath\VeeamBackupJobsCheck.ps1"
. "$scriptPath\VeeamBackupSessionsCheck.ps1"

# Function to generate an HTML report from the CSV files
function New-VeeamHealthCheckHTMLReport {
    param (
        [string]$SourceFolder,
        [string]$OutputFile = "VeeamHealthCheckReport.html"
    )
    
    Write-Host "Generating HTML report from CSV files..." -ForegroundColor Cyan
    
    # Check if source folder exists
    if (-not (Test-Path -Path $SourceFolder)) {
        Write-Host "Source folder not found: $SourceFolder" -ForegroundColor Red
        return
    }
    
    # Get all CSV files in the source folder
    $csvFiles = Get-ChildItem -Path $SourceFolder -Filter "*.csv" | Where-Object { -not $_.Name.EndsWith("_Error.csv") }
    
    if (-not $csvFiles) {
        Write-Host "No CSV files found in $SourceFolder" -ForegroundColor Yellow
        return
    }
    
    # Create HTML header
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Veeam Health Check Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #0072CE;
            border-bottom: 2px solid #0072CE;
            padding-bottom: 10px;
        }
        h2 {
            color: #0072CE;
            margin-top: 30px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 30px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #0072CE;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .success {
            color: green;
        }
        .warning {
            color: orange;
        }
        .error {
            color: red;
        }
        .info {
            color: blue;
        }
        .summary {
            background-color: #f8f8f8;
            padding: 15px;
            border-left: 5px solid #0072CE;
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 50px;
            text-align: center;
            font-size: 0.8em;
            color: #666;
        }
    </style>
</head>
<body>
    <h1>Veeam Backup & Replication Health Check Report</h1>
    <div class="summary">
        <p><strong>Report Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Server Name:</strong> $env:COMPUTERNAME</p>
    </div>
"@
    
    # Process each CSV file
    foreach ($csvFile in $csvFiles) {
        $csvData = Import-Csv -Path $csvFile.FullName
        
        if ($csvData) {
            $sectionTitle = $csvFile.BaseName
            
            # Format section title
            switch -Wildcard ($sectionTitle) {
                "VeeamModulesCheck" { $sectionTitle = "Veeam PowerShell Modules" }
                "VeeamLicenseInfo" { $sectionTitle = "Veeam License Information" }
                "VeeamBackupJobs" { $sectionTitle = "Veeam Backup Jobs" }
                "VeeamRepositories" { $sectionTitle = "Veeam Backup Repositories" }
                "VeeamProxies" { $sectionTitle = "Veeam Backup Proxies" }
                default { $sectionTitle = $sectionTitle -replace "Veeam", "Veeam " }
            }
            
            $html += "<h2>$sectionTitle</h2>"
            
            # Create table
            $html += "<table>"
            
            # Add table header
            $html += "<tr>"
            foreach ($property in $csvData[0].PSObject.Properties.Name) {
                $html += "<th>$property</th>"
            }
            $html += "</tr>"
            
            # Add table rows
            foreach ($item in $csvData) {
                $html += "<tr>"
                foreach ($property in $item.PSObject.Properties.Name) {
                    $value = $item.$property
                    
                    # Apply conditional formatting
                    $class = ""
                    
                    # License status
                    if ($property -eq "LicenseStatus" -or $property -eq "LastResult") {
                        if ($value -eq "Valid" -or $value -eq "Success") {
                            $class = "success"
                        } elseif ($value -eq "Warning") {
                            $class = "warning"
                        } elseif ($value -eq "Failed" -or $value -eq "Invalid" -or $value -eq "Expired") {
                            $class = "error"
                        }
                    }
                    
                    # Days remaining
                    if ($property -eq "DaysRemaining" -and $value -ne "Perpetual") {
                        try {
                            $daysRemaining = [int]$value
                            if ($daysRemaining -lt 30) {
                                $class = "error"
                            } elseif ($daysRemaining -lt 60) {
                                $class = "warning"
                            }
                        } catch {}
                    }
                    
                    # Free space percentage
                    if ($property -eq "FreePercentage") {
                        try {
                            $freePercentage = [double]$value
                            if ($freePercentage -lt 10) {
                                $class = "error"
                            } elseif ($freePercentage -lt 20) {
                                $class = "warning"
                            }
                        } catch {}
                    }
                    
                    # Installed status
                    if ($property -eq "Installed") {
                        if ($value -eq "True") {
                            $class = "success"
                        } else {
                            $class = "error"
                        }
                    }
                    
                    # IsUnavailable or IsDisabled
                    if ($property -eq "IsUnavailable" -or $property -eq "IsDisabled") {
                        if ($value -eq "True") {
                            $class = "error"
                        }
                    }
                    
                    if ($class) {
                        $html += "<td class='$class'>$value</td>"
                    } else {
                        $html += "<td>$value</td>"
                    }
                }
                $html += "</tr>"
            }
            
            $html += "</table>"
        }
    }
    
    # Add footer
    $html += @"
    <div class="footer">
        <p>Report generated by Veeam Health Check Script</p>
        <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
</body>
</html>
"@
    
    # Save HTML to file
    $html | Out-File -FilePath "$SourceFolder\$OutputFile" -Encoding UTF8
    Write-Host "HTML report generated: $SourceFolder\$OutputFile" -ForegroundColor Green
    
    return "$SourceFolder\$OutputFile"
}

# Main function to run all health checks
function Start-VeeamCompleteHealthCheck {
    param (
        [string]$OutputFolder = ".\VeeamHealthCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
        [switch]$GenerateHTMLReport = $true,
        [int]$SessionDays = 7
    )
    
    Write-Host "Starting Veeam Complete Health Check..." -ForegroundColor Cyan
    Write-Host "Results will be saved to: $OutputFolder" -ForegroundColor Cyan
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created output folder: $OutputFolder" -ForegroundColor Green
    }
    
    # Run the basic health check (modules and license)
    Write-Host "`n[1/4] Running basic Veeam health check..." -ForegroundColor Cyan
    Start-VeeamHealthCheck -OutputFolder $OutputFolder
    
    # Run the backup components check (jobs, repositories, proxies)
    Write-Host "`n[2/4] Running Veeam backup components check..." -ForegroundColor Cyan
    Start-VeeamBackupComponentsCheck -OutputFolder $OutputFolder
    
    # Run the backup sessions check
    Write-Host "`n[3/4] Running Veeam backup sessions check (last $SessionDays days)..." -ForegroundColor Cyan
    Start-VeeamBackupSessionsCheck -OutputFolder $OutputFolder -Days $SessionDays
    
    # Generate HTML report if requested
    if ($GenerateHTMLReport) {
        Write-Host "`n[4/4] Generating HTML report..." -ForegroundColor Cyan
        $reportPath = New-VeeamHealthCheckHTMLReport -SourceFolder $OutputFolder -OutputFile "VeeamHealthCheckReport.html"
        
        if ($reportPath) {
            Write-Host "`nHTML report generated successfully: $reportPath" -ForegroundColor Green
        }
    }
    
    Write-Host "`nVeeam Complete Health Check finished. All results saved to $OutputFolder" -ForegroundColor Green
    
    return $OutputFolder
}

# If script is run directly (not dot-sourced), execute the health check
if ($MyInvocation.InvocationName -ne ".") {
    # Run the complete health check
    Start-VeeamCompleteHealthCheck -OutputFolder $OutputFolder -GenerateHTMLReport:(-not $NoHTMLReport) -SessionDays $SessionDays
}