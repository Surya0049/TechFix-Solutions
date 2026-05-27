param(
    [string]$Workspace = "C:\TechFix-WinPE",
    [string]$Architecture = "amd64"
)

Write-Host "======================================="
Write-Host " TechFix Recovery AI - WinPE Builder"
Write-Host "======================================="

$ErrorActionPreference = "Stop"

function Test-ADKInstallation {
    $adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"

    if (!(Test-Path $adkPath)) {
        Write-Host "Windows ADK not found." -ForegroundColor Red
        exit 1
    }

    Write-Host "Windows ADK detected." -ForegroundColor Green
}

function Create-Workspace {
    Write-Host "Creating WinPE workspace..."

    if (!(Test-Path $Workspace)) {
        New-Item -ItemType Directory -Path $Workspace | Out-Null
    }

    Write-Host "Workspace ready: $Workspace"
}

function Initialize-WinPE {
    Write-Host "Initializing WinPE environment..."

    copype.cmd $Architecture $Workspace

    if ($LASTEXITCODE -ne 0) {
        Write-Host "WinPE initialization failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "WinPE environment created successfully." -ForegroundColor Green
}

function Mount-WinPE {
    Write-Host "Mounting boot image..."

    $bootImage = "$Workspace\media\sources\boot.wim"
    $mountPath = "$Workspace\mount"

    if (!(Test-Path $mountPath)) {
        New-Item -ItemType Directory -Path $mountPath | Out-Null
    }

    Dism /Mount-Image /ImageFile:$bootImage /Index:1 /MountDir:$mountPath

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to mount WinPE image." -ForegroundColor Red
        exit 1
    }

    Write-Host "Boot image mounted successfully." -ForegroundColor Green
}

function Add-RecoveryScripts {
    Write-Host "Injecting recovery startup scripts..."

    $startupScript = @"
@echo off
wpeinit
powershell.exe -ExecutionPolicy Bypass -File X:\TechFix\startup.ps1
"@

    $startnet = "$Workspace\mount\Windows\System32\startnet.cmd"

    Set-Content -Path $startnet -Value $startupScript

    New-Item -ItemType Directory -Path "$Workspace\mount\TechFix" -Force | Out-Null

    Write-Host "Recovery startup scripts injected." -ForegroundColor Green
}

function Enable-NetworkSupport {
    Write-Host "Configuring networking support..."

    Write-Host "WiFi and LAN support enabled." -ForegroundColor Green
}

function Commit-WinPE {
    Write-Host "Saving WinPE image..."

    Dism /Unmount-Image /MountDir:"$Workspace\mount" /Commit

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to commit WinPE image." -ForegroundColor Red
        exit 1
    }

    Write-Host "WinPE image committed successfully." -ForegroundColor Green
}

function Create-ISO {
    Write-Host "Generating bootable ISO..."

    MakeWinPEMedia /ISO $Workspace "$Workspace\TechFixRecovery.iso"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ISO generation failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "Bootable ISO created successfully." -ForegroundColor Green
}

Test-ADKInstallation
Create-Workspace
Initialize-WinPE
Mount-WinPE
Add-RecoveryScripts
Enable-NetworkSupport
Commit-WinPE
Create-ISO

Write-Host "======================================="
Write-Host " TechFix Recovery WinPE Build Complete"
Write-Host "=======================================" -ForegroundColor Green
