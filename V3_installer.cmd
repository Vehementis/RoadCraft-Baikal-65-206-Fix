@echo off
Rem Make powershell read this file, skip a number of lines, and execute it.
Rem This works around .ps1 bad file association as non executables.
PowerShell -Command "Get-Content '%~dpnx0' | Select-Object -Skip 5 | Out-String | Invoke-Expression"
goto :eof
# Start of PowerShell script here
# RoadCraft V3 Dozer Mod Installer - PowerShell Version

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RoadCraft V3 Mod Installer" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorOccurred = $false

# Check if we're in the correct directory
if (-not (Test-Path "V3_config" -PathType Container)) {
    Write-Host "[ERROR] V3_config folder not found!" -ForegroundColor Red
    Write-Host "  Please make sure you've extracted the RoadCraft-Dozer-Mod files" -ForegroundColor Yellow
    Write-Host "  and placed this folder inside your RoadCraft installation directory." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$ModRoot = Get-Location
$ConfigDir = Join-Path $ModRoot "V3_config"

Write-Host "[OK] Mod Folder detected at: $ModRoot" -ForegroundColor Green
Write-Host ""

# Find RoadCraft root directory (go up one level)
$RoadCraftRoot = Split-Path $ModRoot -Parent

# Verify RoadCraft installation
$RoadCraftPakFile = Join-Path $RoadCraftRoot "root\paks\client\default\default_other.pak"

if (-not (Test-Path $RoadCraftPakFile -PathType Leaf)) {
    Write-Host "[ERROR] RoadCraft installation not found!" -ForegroundColor Red
    Write-Host "  Could not locate: root\paks\client\default\default_other.pak" -ForegroundColor Yellow
    Write-Host "  Please ensure the Mod folder is placed" -ForegroundColor Yellow
    Write-Host "  directly inside your RoadCraft installation directory." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] RoadCraft installation detected at: $RoadCraftRoot" -ForegroundColor Green
Write-Host ""

# Create working and backup directories
$BackupDir = Join-Path $RoadCraftRoot "V3_mods_backup"
$WorkDir = Join-Path $BackupDir "temp"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# Create timestamp for backup
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

#Backup the .pak.cache file if it exists and then delete it
$RoadCraftPakFileCache = Join-Path $RoadCraftRoot "root\paks\client\default\default_other.pak.cache"
if (Test-Path $RoadCraftPakFileCache -PathType Leaf) {
    try {
        Copy-Item $RoadCraftPakFileCache -Destination $BackupDir -Force
        Write-Host "[OK] default_other.pak.cache Backup successful" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] default_other.pak.cache Backup failed" -ForegroundColor Orange
    }
    try {
        Remove-Item $RoadCraftPakFileCache -Force
        Write-Host "[OK] Original default_other.pak.cache file deleted" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to delete original default_other.pak.cache file please delete it manually" -ForegroundColor Red
    }
} else {
    Write-Host "[INFO] default_other.pak.cache file already deleted" -ForegroundColor Cyan
}

# Read all JSON configuration files first to get the list of files we need
Write-Host ""
Write-Host "Scanning configuration files..." -ForegroundColor Cyan

$ConfigFiles = Get-ChildItem -Path $ConfigDir -Filter "*.json"
$FilesToProcess = @()

foreach ($ConfigFile in $ConfigFiles) {
    try {
        $JsonContent = Get-Content -Path $ConfigFile.FullName -Raw | ConvertFrom-Json
        $FilesToProcess += @{
            ConfigFile = $ConfigFile
            TruckName = $JsonContent.truckName
            TruckFile = $JsonContent.truckFile
            Actions = $JsonContent.actions
        }
        Write-Host " - $($JsonContent.truckName)" -ForegroundColor Gray
    } catch {
        Write-Host "[ERROR] Failed to parse $($ConfigFile.Name)" -ForegroundColor Red
        $ErrorOccurred = $true
    }
}

Write-Host "[OK] Found $($FilesToProcess.Count) truck configurations to process" -ForegroundColor Green

# Function to extract a specific file from PAK archive using 7-Zip
function Extract-FileFromPak {
    param(
        [string]$PakPath,
        [string]$FilePathInPak,
        [string]$OutputPath
    )
    
    try {
        # Create output directory if it doesn't exist
        $OutputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        }

        # Load required assemblies for ZIP handling
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Normalize path separators for 7-Zip (use forward slashes)
        $NormalizedPath = $FilePathInPak -replace '\\', '/'
        
        # Open the PAK file as a ZIP archive
        $Archive = [System.IO.Compression.ZipFile]::OpenRead($PakPath)
        
        try {
            # Find the specific file in the archive
            $Entry = $Archive.Entries | Where-Object { $_.FullName -eq $NormalizedPath }
            
            if (-not $Entry) {
                # Try with backslashes if forward slashes didn't work
                $NormalizedPath = $FilePathInPak -replace '/', '\'
                $Entry = $Archive.Entries | Where-Object { $_.FullName -eq $NormalizedPath }
            }
            
            if ($Entry) {
                # Extract the file
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $OutputPath, $true)
                
                if (Test-Path $OutputPath) {
                    return $true
                } else {
                    Write-Host "    [ERROR] File extraction completed but output file not found" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "    [ERROR] File not found in archive: $FilePathInPak" -ForegroundColor Red
                return $false
            }
        }
        finally {
            # Always dispose of the archive
            $Archive.Dispose()
        }

    } catch [System.IO.InvalidDataException] {
        Write-Host "    [ERROR] PAK file appears to be corrupted or not a valid ZIP archive" -ForegroundColor Red
        return $false
    } catch [System.UnauthorizedAccessException] {
        Write-Host "    [ERROR] Access denied. Please run as administrator or check file permissions" -ForegroundColor Red
        return $false
    } catch {
        Write-Host "    [ERROR] Exception during PAK extraction: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to update a file in PAK archive using 7-Zip
function Replace-FileInPak {
    param(
        [string]$PakPath,
        [string]$FilePathInPak,
        [string]$SourceFilePath
    )
    
    try {
        # Load required assemblies for ZIP handling
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Normalize path separators for 7-Zip (use forward slashes)
        $NormalizedPath = $FilePathInPak -replace '\\', '/'

        # Open the PAK file in Update mode
        $Archive = [System.IO.Compression.ZipFile]::Open($PakPath, [System.IO.Compression.ZipArchiveMode]::Update)
        
        try {
            # Find and remove existing entry (case-insensitive)
            $ExistingEntry = $Archive.Entries | Where-Object { $_.FullName -ieq $NormalizedPath }
            
            # Try with backslashes if forward slashes didn't work
            if (-not $ExistingEntry) {
                $BackslashPath = $FilePathInPak -replace '/', '\'
                $ExistingEntry = $Archive.Entries | Where-Object { $_.FullName -ieq $BackslashPath }
                if ($ExistingEntry) {
                    $NormalizedPath = $BackslashPath
                }
            }
            
            if ($ExistingEntry) {
                Write-Host "    [INFO] Removing existing entry: $($ExistingEntry.FullName)" -ForegroundColor Gray
                $ExistingEntry.Delete()
            }
            
            # Add the new file
            Write-Host "    [INFO] Adding new entry: $NormalizedPath" -ForegroundColor Gray
            $NewEntry = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $SourceFilePath, $NormalizedPath, [System.IO.Compression.CompressionLevel]::NoCompression)
            
            if ($NewEntry) {
                Write-Host "    [INFO] File successfully added to archive" -ForegroundColor Gray
                return $true
            } else {
                Write-Host "    [ERROR] Failed to create new entry in archive" -ForegroundColor Red
                return $false
            }
        }
        finally {
            $Archive.Dispose()
        }

    } catch [System.UnauthorizedAccessException] {
        Write-Host "    [ERROR] Access denied. Please run as administrator or check file permissions" -ForegroundColor Red
        return $false
    } catch [System.IO.IOException] {
        Write-Host "    [ERROR] IO Exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    [ERROR] The PAK file might be in use by another process" -ForegroundColor Red
        return $false
    } catch {
        Write-Host "    [ERROR] Exception during file replacement: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to apply modifications to a truck file using regex
function Apply-TruckModifications {
    param(
        [string]$ConfigPath,
        [string]$TruckFile
    )
    
    try {
        # Load the JSON configuration
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        # Read the truck file as a single string to handle multiline patterns
        $content = Get-Content $TruckFile -Raw
        $originalContent = $content
        $modificationsApplied = 0
        
        Write-Host "    [INFO] Processing $($config.modifications.Count) modifications" -ForegroundColor Gray
        
        # Process each modification
        foreach ($mod in $config.modifications) {
            try {
                # Check if modification is already applied
                if ($mod.checkPattern -and $content -match $mod.checkPattern) {
                    # Check if we have else patterns to apply instead
                    if ($mod.elseSearchPattern -and $mod.elseReplacement) {
                        Write-Host "    [INFO] Modification already applied, applying else pattern: $($mod.description)" -ForegroundColor Cyan
                        
                        # Apply the else regex replacement
                        $newContent = $content -replace $mod.elseSearchPattern, $mod.elseReplacement
                        
                        # Check if any replacement was made
                        if ($newContent -ne $content) {
                            $content = $newContent
                            $modificationsApplied++
                            Write-Host "    [INFO] Applied else modification: $($mod.description)" -ForegroundColor Gray
                        } else {
                            Write-Host "    [SKIP] Nothing changed: $($mod.description)" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "    [SKIP] Modification already applied: $($mod.description)" -ForegroundColor Yellow
                    }
                    continue
                }
                
                # Apply the normal regex replacement
                $newContent = $content -replace $mod.searchPattern, $mod.replacement
                
                # Check if any replacement was made
                if ($newContent -ne $content) {
                    $content = $newContent
                    $modificationsApplied++
                    Write-Host "    [INFO] Applied: $($mod.description)" -ForegroundColor Gray
                } else {
                    Write-Host "    [SKIP] Nothing changed: $($mod.description)" -ForegroundColor Yellow
                }
                
            } catch {
                Write-Host "    [ERROR] Failed to apply modification: $($mod.description)" -ForegroundColor Red
                Write-Host "    [ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        # Only write file if modifications were made
        if ($content -ne $originalContent) {
            # Write the modified content back to the file using UTF-8 without BOM
            [System.IO.File]::WriteAllText($TruckFile, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "    [OK] Applied $modificationsApplied modifications from $($config.truckName) config" -ForegroundColor Green
        } else {
            Write-Host "    [INFO] No modifications needed for $($config.truckName)" -ForegroundColor Cyan
        }
        
        return $true
    } catch {
        Write-Host "    [ERROR] Failed to apply modifications: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    [ERROR] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $false
    }
}


# Process each truck file
Write-Host ""
Write-Host "Processing truck files..." -ForegroundColor Cyan

foreach ($FileInfo in $FilesToProcess) {
    Write-Host ""
    Write-Host "Processing: $($FileInfo.TruckName)" -ForegroundColor Yellow
    Write-Host "    File: $($FileInfo.TruckFile)" -ForegroundColor Gray
    
    try {
        # Extract the specific truck file from PAK
        $TruckFileName = Split-Path $FileInfo.TruckFile -Leaf
        $ExtractedFilePath = Join-Path $WorkDir $TruckFileName
        
        Write-Host "    Extracting from PAK..." -ForegroundColor Gray
        $ExtractSuccess = Extract-FileFromPak -PakPath $RoadCraftPakFile -FilePathInPak $FileInfo.TruckFile -OutputPath $ExtractedFilePath
        
        if (-not $ExtractSuccess) {
            Write-Host "    [ERROR] Truck file not found in PAK: $($FileInfo.TruckFile)" -ForegroundColor Red
            $ErrorOccurred = $true
            continue
        }
        
        Write-Host "    [INFO] File extracted successfully" -ForegroundColor Gray
        
        # Create backup of original truck file
        $TruckBackupPath = Join-Path $BackupDir "$($FileInfo.TruckName).cls.backup_$Timestamp"
        if (-not (Test-Path $TruckBackupPath)) {
            Copy-Item $ExtractedFilePath -Destination $TruckBackupPath -Force
            Write-Host "    [INFO] Original file backed up" -ForegroundColor Gray
        } else {
            Write-Host "    [INFO] Backup already exists" -ForegroundColor Gray
        }

        # Apply modifications to the truck file
        $ConfigPath = $FileInfo.ConfigFile.FullName
        $ModificationResult = Apply-TruckModifications -ConfigPath $ConfigPath -TruckFile $ExtractedFilePath

        if (-not $ModificationResult) {
            $ErrorOccurred = $true
            continue
        }

        # Replace the original truck file in the PAK
        $ReplaceSuccess = Replace-FileInPak -PakPath $RoadCraftPakFile -FilePathInPak $FileInfo.TruckFile -SourceFilePath $ExtractedFilePath
        
        if ($ReplaceSuccess) {
            Write-Host "    [OK] Truck file modified and replaced in PAK" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Failed to replace truck file in PAK" -ForegroundColor Red
            $ErrorOccurred = $true
        }

    } catch {
        Write-Host "[ERROR] Failed to process $($FileInfo.TruckName)" -ForegroundColor Red
        $ErrorOccurred = $true
    }
}

# Clean up temporary files
if (Test-Path $WorkDir) {
    Remove-Item -Path $WorkDir -Recurse -Force
}

Write-Host ""
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($ErrorOccurred) {
    Write-Host "Installation completed with some errors!" -ForegroundColor Red
    Write-Host "Please check the messages above." -ForegroundColor Red
} else {
    Write-Host "Installation completed successfully!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can now start RoadCraft." -ForegroundColor Yellow
    Write-Host "Have fun!!!" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Backup files are stored in: $BackupDir" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
