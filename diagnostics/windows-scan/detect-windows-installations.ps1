Write-Host "======================================="
Write-Host " TechFix Recovery AI - Windows Scanner"
Write-Host "======================================="

$ErrorActionPreference = "SilentlyContinue"

$results = @()

function Get-PartitionInformation {
    Write-Host "Scanning partitions..." -ForegroundColor Cyan

    $partitions = Get-Partition

    foreach ($partition in $partitions) {
        try {
            $volume = Get-Volume -Partition $partition

            $global:results += [PSCustomObject]@{
                Type = "Partition"
                DiskNumber = $partition.DiskNumber
                PartitionNumber = $partition.PartitionNumber
                DriveLetter = $volume.DriveLetter
                FileSystem = $volume.FileSystem
                SizeGB = [math]::Round($partition.Size / 1GB, 2)
            }
        }
        catch {
        }
    }
}

function Detect-WindowsInstallations {
    Write-Host "Searching for Windows installations..." -ForegroundColor Cyan

    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $windowsPath = "$($drive.Root)Windows"

        if (Test-Path $windowsPath) {
            Write-Host "Windows installation detected on $($drive.Root)" -ForegroundColor Green

            $version = "Unknown"

            try {
                $ntdll = "$windowsPath\System32\ntdll.dll"

                if (Test-Path $ntdll) {
                    $version = (Get-Item $ntdll).VersionInfo.FileVersion
                }
            }
            catch {
            }

            $global:results += [PSCustomObject]@{
                Type = "WindowsInstallation"
                Drive = $drive.Root
                WindowsPath = $windowsPath
                Version = $version
            }
        }
    }
}

function Detect-EFIPartitions {
    Write-Host "Checking EFI partitions..." -ForegroundColor Cyan

    $efiPartitions = Get-Partition | Where-Object {
        $_.GptType -eq "{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}"
    }

    foreach ($efi in $efiPartitions) {
        $global:results += [PSCustomObject]@{
            Type = "EFI"
            DiskNumber = $efi.DiskNumber
            PartitionNumber = $efi.PartitionNumber
            SizeGB = [math]::Round($efi.Size / 1GB, 2)
        }
    }
}

function Export-Results {
    $outputPath = "X:\TechFix\logs"

    if (!(Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }

    $jsonOutput = "$outputPath\windows-scan.json"

    $results | ConvertTo-Json -Depth 5 | Out-File $jsonOutput -Encoding utf8

    Write-Host "Scan results exported." -ForegroundColor Green
}

Get-PartitionInformation
Detect-WindowsInstallations
Detect-EFIPartitions
Export-Results

Write-Host "======================================="
Write-Host " Windows Detection Scan Complete"
Write-Host "=======================================" -ForegroundColor Green
