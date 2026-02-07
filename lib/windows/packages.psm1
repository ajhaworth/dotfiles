# packages.psm1 - Package management functions for Windows setup

Import-Module (Join-Path $PSScriptRoot "common.psm1") -Global -Force

# Track installation results
$script:Results = @{
    Installed = @()
    Skipped   = @()
    Failed    = @()
}

function Reset-Results {
    $script:Results = @{
        Installed = @()
        Skipped   = @()
        Failed    = @()
    }
}

function Get-Results {
    return $script:Results
}

# Check if winget is available
function Test-Winget {
    return $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
}

# Check if chocolatey is available
function Test-Chocolatey {
    return $null -ne (Get-Command choco -ErrorAction SilentlyContinue)
}

# Install Chocolatey if not present
function Install-Chocolatey {
    param(
        [switch]$DryRun
    )

    if (Test-Chocolatey) {
        Write-Skip "Chocolatey already installed"
        return $true
    }

    if ($DryRun) {
        Write-DryRun "Would install Chocolatey"
        return $true
    }

    Write-Status "Installing Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Chocolatey) {
            Write-Success "Chocolatey installed successfully"
            return $true
        } else {
            Write-Err "Chocolatey installation failed"
            return $false
        }
    } catch {
        Write-Err "Failed to install Chocolatey: $_"
        return $false
    }
}

# Check if a winget package is installed
function Test-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $result = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    return $LASTEXITCODE -eq 0 -and $result -match $PackageId
}

# Check if a chocolatey package is installed
function Test-ChocoPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    $result = choco list $PackageName --local-only --exact --limit-output 2>$null
    return $null -ne $result -and $result -ne ""
}

# Install a single winget package
function Install-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        [switch]$DryRun,
        [switch]$Force
    )

    # Check if already installed
    if (-not $Force -and (Test-WingetPackage -PackageId $PackageId)) {
        Write-Skip "$PackageId (already installed)"
        $script:Results.Skipped += $PackageId
        return $true
    }

    if ($DryRun) {
        Write-DryRun "Would install: $PackageId"
        return $true
    }

    Write-Status "Installing $PackageId..."
    try {
        $installArgs = @(
            'install',
            '--id', $PackageId,
            '--exact',
            '--silent',
            '--accept-package-agreements',
            '--accept-source-agreements'
        )
        if ($Force) {
            $installArgs += '--force'
        }

        $result = & winget @installArgs 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$PackageId installed"
            $script:Results.Installed += $PackageId
            return $true
        } else {
            Write-Err "Failed to install $PackageId"
            $script:Results.Failed += $PackageId
            return $false
        }
    } catch {
        Write-Err "Error installing ${PackageId}: $_"
        $script:Results.Failed += $PackageId
        return $false
    }
}

# Install a single chocolatey package
function Install-ChocoPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageSpec,
        [switch]$DryRun,
        [switch]$Force
    )

    # Parse package spec (may include flags like --pre)
    $parts = $PackageSpec -split '\s+'
    $packageName = $parts[0]
    $extraArgs = if ($parts.Count -gt 1) { $parts[1..($parts.Count-1)] } else { @() }

    # Check if already installed
    if (-not $Force -and (Test-ChocoPackage -PackageName $packageName)) {
        Write-Skip "$packageName (already installed)"
        $script:Results.Skipped += $packageName
        return $true
    }

    if ($DryRun) {
        Write-DryRun "Would install: $PackageSpec"
        return $true
    }

    Write-Status "Installing $packageName..."
    try {
        $installArgs = @('install', $packageName, '-y')
        if ($Force) {
            $installArgs += '--force'
        }
        $installArgs += $extraArgs

        $result = & choco @installArgs 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$packageName installed"
            $script:Results.Installed += $packageName
            return $true
        } else {
            Write-Err "Failed to install $packageName"
            $script:Results.Failed += $packageName
            return $false
        }
    } catch {
        Write-Err "Error installing ${packageName}: $_"
        $script:Results.Failed += $packageName
        return $false
    }
}

# Install multiple packages from a list
function Install-PackageBatch {
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        [Parameter(Mandatory)]
        [ValidateSet('winget', 'choco')]
        [string]$Manager,
        [switch]$DryRun,
        [switch]$Force
    )

    foreach ($package in $Packages) {
        if ($Manager -eq 'winget') {
            Install-WingetPackage -PackageId $package -DryRun:$DryRun -Force:$Force | Out-Null
        } else {
            Install-ChocoPackage -PackageSpec $package -DryRun:$DryRun -Force:$Force | Out-Null
        }
    }
}

# Display package status for a list
function Show-PackageStatus {
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        [Parameter(Mandatory)]
        [ValidateSet('winget', 'choco')]
        [string]$Manager,
        [string]$Category = ""
    )

    if ($Category) {
        Write-SubStep $Category
    }

    foreach ($package in $Packages) {
        # Handle choco package specs with args
        $packageName = ($package -split '\s+')[0]

        if ($Manager -eq 'winget') {
            $installed = Test-WingetPackage -PackageId $packageName
        } else {
            $installed = Test-ChocoPackage -PackageName $packageName
        }

        if ($installed) {
            Write-Host "    [" -NoNewline
            Write-Host "X" -ForegroundColor Green -NoNewline
            Write-Host "] $package"
        } else {
            Write-Host "    [ ] $package" -ForegroundColor DarkGray
        }
    }
}

# Write summary of installation results
function Write-ResultsSummary {
    param(
        [string]$Title = "Installation Summary"
    )

    $results = Get-Results
    $total = $results.Installed.Count + $results.Skipped.Count + $results.Failed.Count

    if ($total -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "--------------------------------------" -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor White
    Write-Host "--------------------------------------" -ForegroundColor DarkGray

    if ($results.Installed.Count -gt 0) {
        Write-Host "  Installed: " -NoNewline
        Write-Host $results.Installed.Count -ForegroundColor Green
    }

    if ($results.Skipped.Count -gt 0) {
        Write-Host "  Skipped:   " -NoNewline
        Write-Host $results.Skipped.Count -ForegroundColor DarkGray
    }

    if ($results.Failed.Count -gt 0) {
        Write-Host "  Failed:    " -NoNewline
        Write-Host $results.Failed.Count -ForegroundColor Red
        Write-Host ""
        Write-Host "  Failed packages:" -ForegroundColor Red
        foreach ($pkg in $results.Failed) {
            Write-Host "    - $pkg" -ForegroundColor Red
        }
    }

    Write-Host ""
}

Export-ModuleMember -Function @(
    'Reset-Results',
    'Get-Results',
    'Test-Winget',
    'Test-Chocolatey',
    'Install-Chocolatey',
    'Test-WingetPackage',
    'Test-ChocoPackage',
    'Install-WingetPackage',
    'Install-ChocoPackage',
    'Install-PackageBatch',
    'Show-PackageStatus',
    'Write-ResultsSummary'
)
