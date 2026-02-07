# setup.ps1 - Windows setup entry point
#
# This is the main entry point for Windows setup. It delegates to
# the platform-specific setup script.
#
# Usage:
#   .\setup.ps1                      # Full setup
#   .\setup.ps1 -DryRun              # Preview changes
#   .\setup.ps1 packages             # Install packages only
#   .\setup.ps1 packages ls          # List package status
#   .\setup.ps1 -Debloat             # Full setup with debloat
#   .\setup.ps1 debloat              # Debloat only
#   .\setup.ps1 debloat -DryRun      # Preview debloat

param(
    [string]$Profile = "windows",
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Debloat,

    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Args
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$platformScript = Join-Path $scriptDir "platforms\windows\setup.ps1"

if (-not (Test-Path $platformScript)) {
    Write-Host "[ERROR] Platform script not found: $platformScript" -ForegroundColor Red
    exit 1
}

# Build arguments
$scriptArgs = @{
    Profile = $Profile
    DryRun = $DryRun
    Force = $Force
    Debloat = $Debloat
}

# Pass positional arguments
if ($Args.Count -gt 0) {
    $scriptArgs['Command'] = $Args[0]
}
if ($Args.Count -gt 1) {
    $scriptArgs['SubCommand'] = $Args[1]
}

& $platformScript @scriptArgs
