$file = "trivy-results.json"

if (!(Test-Path $file)) {
    Write-Host "Trivy report not found"
    exit 0
}

# Read Trivy JSON
$report = Get-Content $file -Raw | ConvertFrom-Json

$findings = @()

# Process every Trivy target
foreach ($result in $report.Results) {

    # Skip targets without vulnerabilities
    if ($null -eq $result.Vulnerabilities) {
        continue
    }
 
    # Process every vulnerability
    foreach ($vuln in $result.Vulnerabilities) {
 
        $line = ""

        # Find package location
        if ($null -ne $result.Packages) {

            foreach ($pkg in $result.Packages) {

                if ($pkg.ID -eq $vuln.PkgID) {

                    if ($null -ne $pkg.Locations) {
                        $line = $pkg.Locations[0].StartLine
                    }
                }
            }
        }

        # Store finding
        $findings += [PSCustomObject]@{
            Severity         = $vuln.Severity
            CVE              = $vuln.VulnerabilityID
            Package          = $vuln.PkgName
            InstalledVersion = $vuln.InstalledVersion
            FixedVersion     = $vuln.FixedVersion
            Target           = $result.Target
            Line             = $line
            Title            = $vuln.Title
        }
    }
}



$critical = @(
    $findings | Where-Object { $_.Severity -eq "CRITICAL" }
).Count

$high = @(
    $findings | Where-Object { $_.Severity -eq "HIGH" }
).Count

$medium = @(
    $findings | Where-Object { $_.Severity -eq "MEDIUM" }
).Count

$low = @(
    $findings | Where-Object { $_.Severity -eq "LOW" }
).Count

$unknown = @(
    $findings | Where-Object { $_.Severity -eq "UNKNOWN" }
).Count

$total = @($findings).Count




Add-Content $env:GITHUB_STEP_SUMMARY "## Trivy Security Summary"

Add-Content $env:GITHUB_STEP_SUMMARY ""

Add-Content $env:GITHUB_STEP_SUMMARY "| Severity | Count |"
Add-Content $env:GITHUB_STEP_SUMMARY "|---|---:|"
Add-Content $env:GITHUB_STEP_SUMMARY "| Critical | $critical |"
Add-Content $env:GITHUB_STEP_SUMMARY "| High | $high |"
Add-Content $env:GITHUB_STEP_SUMMARY "| Medium | $medium |"
Add-Content $env:GITHUB_STEP_SUMMARY "| Low | $low |"
Add-Content $env:GITHUB_STEP_SUMMARY "| Unknown | $unknown |"
Add-Content $env:GITHUB_STEP_SUMMARY "| **Total** | **$total** |"




Add-Content $env:GITHUB_STEP_SUMMARY ""

Add-Content $env:GITHUB_STEP_SUMMARY "## Trivy Detailed Findings"

Add-Content $env:GITHUB_STEP_SUMMARY ""

Add-Content $env:GITHUB_STEP_SUMMARY "| Severity | CVE | Package | Installed | Fixed | Target | Line | Title |"

Add-Content $env:GITHUB_STEP_SUMMARY "|---|---|---|---|---|---|---:|---|"


foreach ($item in $findings) {

    Add-Content $env:GITHUB_STEP_SUMMARY "| $($item.Severity) | $($item.CVE) | $($item.Package) | $($item.InstalledVersion) | $($item.FixedVersion) | $($item.Target) | $($item.Line) | $($item.Title) |"
}




$findings |
    ConvertTo-Json -Depth 10 |
    Set-Content trivy-findings.json




Write-Host ""
Write-Host "Trivy Security Results"
Write-Host "======================"

Write-Host "Critical : $critical"
Write-Host "High     : $high"
Write-Host "Medium   : $medium"
Write-Host "Low      : $low"
Write-Host "Unknown  : $unknown"
Write-Host "Total    : $total"

Write-Host ""
Write-Host "Detailed Findings"
Write-Host "================="

$findings | Format-Table -AutoSize
