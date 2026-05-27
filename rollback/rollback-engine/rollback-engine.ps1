Write-Host "======================================="
Write-Host " TechFix Rollback Protection Engine"
Write-Host "=======================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

$RollbackRoot = "X:\TechFix\rollback"
$SnapshotRoot = "$RollbackRoot\snapshots"
$LogRoot = "X:\TechFix\logs"

function Initialize-RollbackEnvironment {
    Write-Host "Initializing rollback environment..." -ForegroundColor Yellow

    foreach ($path in @($RollbackRoot, $SnapshotRoot, $LogRoot)) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    Write-Host "Rollback environment ready." -ForegroundColor Green
}

function Detect-WindowsTargets {
    Write-Host "Detecting Windows installations for rollback..." -ForegroundColor Yellow

    $targets = @()

    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $windowsPath = "$($drive.Root)Windows"

        if (Test-Path $windowsPath) {
            $targets += $windowsPath
            Write-Host "Rollback target detected: $windowsPath" -ForegroundColor Green
        }
    }

    return $targets
}

function Create-RegistrySnapshot {
    param([string]$WindowsPath)

    Write-Host "Creating registry snapshot..." -ForegroundColor Yellow

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $snapshotPath = "$SnapshotRoot\Registry-$timestamp"

    New-Item -ItemType Directory -Path $snapshotPath -Force | Out-Null

    $configPath = "$WindowsPath\System32\config"

    if (Test-Path $configPath) {
        Copy-Item "$configPath\*" $snapshotPath -Recurse -Force
        Write-Host "Registry snapshot created." -ForegroundColor Green
    }
    else {
        Write-Host "Registry path not found." -ForegroundColor Red
    }
}

function Create-BCDSnapshot {
    param([string]$WindowsPath)

    Write-Host "Creating BCD snapshot..." -ForegroundColor Yellow

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bcdBackup = "$SnapshotRoot\BCD-$timestamp.bak"

    bcdedit /export $bcdBackup

    if (Test-Path $bcdBackup) {
        Write-Host "BCD snapshot created." -ForegroundColor Green
    }
    else {
        Write-Host "BCD backup failed." -ForegroundColor Red
    }
}

function Create-DriverSnapshot {
    param([string]$WindowsPath)

    Write-Host "Creating driver snapshot..." -ForegroundColor Yellow

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $driverBackup = "$SnapshotRoot\Drivers-$timestamp"

    New-Item -ItemType Directory -Path $driverBackup -Force | Out-Null

    $driverStore = "$WindowsPath\System32\DriverStore"

    if (Test-Path $driverStore) {
        Copy-Item $driverStore $driverBackup -Recurse -Force
        Write-Host "Driver snapshot created." -ForegroundColor Green
    }
    else {
        Write-Host "Driver store not found." -ForegroundColor Red
    }
}

function Export-RollbackManifest {
    Write-Host "Generating rollback manifest..." -ForegroundColor Yellow

    $manifest = @"
TechFix Rollback Manifest
Generated: $(Get-Date)

Rollback Components:
- Registry Snapshots
- BCD Snapshots
- Driver Snapshots

Rollback Protection Status: ACTIVE
"@

    $manifest | Out-File "$LogRoot\rollback-manifest.txt" -Encoding utf8

    Write-Host "Rollback manifest exported." -ForegroundColor Green
}

Initialize-RollbackEnvironment

$targets = Detect-WindowsTargets

foreach ($target in $targets) {
    Create-RegistrySnapshot -WindowsPath $target
    Create-BCDSnapshot -WindowsPath $target
    Create-DriverSnapshot -WindowsPath $target
}

Export-RollbackManifest

Write-Host "======================================="
Write-Host " Rollback Protection Complete"
Write-Host "=======================================" -ForegroundColor Green
