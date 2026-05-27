Write-Host "======================================="
Write-Host " TechFix Offline Repair Engine"
Write-Host "=======================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

$RepairRoot = "X:\TechFix\repair"
$LogRoot = "X:\TechFix\logs"
$BackupRoot = "X:\TechFix\backup"

function Initialize-RepairEnvironment {
    Write-Host "Initializing repair environment..." -ForegroundColor Yellow

    foreach ($path in @($RepairRoot, $LogRoot, $BackupRoot)) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    Write-Host "Repair environment initialized." -ForegroundColor Green
}

function Detect-WindowsTarget {
    Write-Host "Searching for Windows target..." -ForegroundColor Yellow

    $targets = @()

    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $windowsPath = "$($drive.Root)Windows"

        if (Test-Path $windowsPath) {
            $targets += $windowsPath
            Write-Host "Detected Windows installation: $windowsPath" -ForegroundColor Green
        }
    }

    return $targets
}

function Backup-RegistryHives {
    param([string]$WindowsPath)

    Write-Host "Backing up registry hives..." -ForegroundColor Yellow

    $configPath = "$WindowsPath\System32\config"

    if (!(Test-Path $configPath)) {
        Write-Host "Registry config path not found." -ForegroundColor Red
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$BackupRoot\Registry-$timestamp"

    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    Copy-Item "$configPath\*" $backupPath -Recurse -Force

    Write-Host "Registry backup completed." -ForegroundColor Green
}

function Run-OfflineDISM {
    param([string]$WindowsPath)

    Write-Host "Running offline DISM repair..." -ForegroundColor Yellow

    $repairLog = "$LogRoot\dism-repair.log"

    $command = "DISM /Image:$WindowsPath /Cleanup-Image /RestoreHealth"

    cmd.exe /c $command | Tee-Object -FilePath $repairLog

    Write-Host "Offline DISM operation completed." -ForegroundColor Green
}

function Run-OfflineSFC {
    param([string]$WindowsPath)

    Write-Host "Running offline SFC repair..." -ForegroundColor Yellow

    $repairLog = "$LogRoot\sfc-repair.log"

    $bootDrive = Split-Path $WindowsPath -Qualifier

    $command = "sfc /scannow /offbootdir=$bootDrive /offwindir=$WindowsPath"

    cmd.exe /c $command | Tee-Object -FilePath $repairLog

    Write-Host "Offline SFC operation completed." -ForegroundColor Green
}

function Repair-BCD {
    param([string]$WindowsPath)

    Write-Host "Repairing BCD and boot configuration..." -ForegroundColor Yellow

    $bootDrive = Split-Path $WindowsPath -Qualifier

    bootrec /fixmbr
    bootrec /fixboot
    bootrec /scanos
    bootrec /rebuildbcd

    bcdboot "$WindowsPath" /f ALL

    Write-Host "BCD repair completed." -ForegroundColor Green
}

function Export-RepairReport {
    Write-Host "Generating repair report..." -ForegroundColor Yellow

    $report = @"
TechFix Offline Repair Report
Generated: $(Get-Date)

Modules Executed:
- Registry Backup
- Offline DISM
- Offline SFC
- BCD Repair
"@

    $report | Out-File "$LogRoot\repair-report.txt" -Encoding utf8

    Write-Host "Repair report exported." -ForegroundColor Green
}

Initialize-RepairEnvironment

$windowsTargets = Detect-WindowsTarget

foreach ($target in $windowsTargets) {
    Backup-RegistryHives -WindowsPath $target
    Run-OfflineDISM -WindowsPath $target
    Run-OfflineSFC -WindowsPath $target
    Repair-BCD -WindowsPath $target
}

Export-RepairReport

Write-Host "======================================="
Write-Host " Offline Repair Workflow Completed"
Write-Host "=======================================" -ForegroundColor Green
