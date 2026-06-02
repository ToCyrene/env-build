# uninstall_uv_env.ps1
# Auto-elevation version - double-click to run
# This script reverts all changes made by setup_uv_env.ps1

# Auto-elevate: restart as administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "uv Environment Uninstall Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration variables (same as setup script)
$TARGET_DIR = "$env:USERPROFILE\.uv_env"
$TARGET_FILE = "$TARGET_DIR\Microsoft.PowerShell_profile.ps1"
$UV_CONFIG_DIR = "$env:APPDATA\uv"
$UV_CONFIG_FILE = "$UV_CONFIG_DIR\uv.toml"
$CACHE_DIR = "D:\uv_cache"

# Store backup paths for summary
$backupProfiles = @()

# Step 1: Clean uv cache data
Write-Host "Step 1: Cleaning uv cache data..." -ForegroundColor Yellow
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "  Running: uv cache clean" -ForegroundColor Gray
    uv cache clean 2>&1 | Out-Null
    Write-Host "  Cache cleaned" -ForegroundColor Green
} else {
    Write-Host "  uv not found, skipping cache clean" -ForegroundColor Gray
}

# Step 2: Remove uv python installations
Write-Host ""
Write-Host "Step 2: Removing uv python installations..." -ForegroundColor Yellow
if (Get-Command uv -ErrorAction SilentlyContinue) {
    $pythonDir = uv python dir 2>$null
    if ($pythonDir -and (Test-Path $pythonDir)) {
        Write-Host "  Python directory: $pythonDir" -ForegroundColor Gray
        Remove-Item -Path $pythonDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Python installations removed" -ForegroundColor Green
    } else {
        Write-Host "  Python directory not found, skipping" -ForegroundColor Gray
    }
} else {
    Write-Host "  uv not found, skipping" -ForegroundColor Gray
}

# Step 3: Remove uv tool installations
Write-Host ""
Write-Host "Step 3: Removing uv tool installations..." -ForegroundColor Yellow
if (Get-Command uv -ErrorAction SilentlyContinue) {
    $toolDir = uv tool dir 2>$null
    if ($toolDir -and (Test-Path $toolDir)) {
        Write-Host "  Tool directory: $toolDir" -ForegroundColor Gray
        Remove-Item -Path $toolDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Tool installations removed" -ForegroundColor Green
    } else {
        Write-Host "  Tool directory not found, skipping" -ForegroundColor Gray
    }
} else {
    Write-Host "  uv not found, skipping" -ForegroundColor Gray
}

# Step 4: Delete uv and uvx binaries
Write-Host ""
Write-Host "Step 4: Deleting uv and uvx binaries..." -ForegroundColor Yellow
$uvBinPath = "$env:USERPROFILE\.local\bin\uv.exe"
$uvxBinPath = "$env:USERPROFILE\.local\bin\uvx.exe"

if (Test-Path $uvBinPath) {
    Remove-Item -Path $uvBinPath -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed: $uvBinPath" -ForegroundColor Green
} else {
    Write-Host "  Not found: $uvBinPath" -ForegroundColor Gray
}

if (Test-Path $uvxBinPath) {
    Remove-Item -Path $uvxBinPath -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed: $uvxBinPath" -ForegroundColor Green
} else {
    Write-Host "  Not found: $uvxBinPath" -ForegroundColor Gray
}

# Also check if uv is installed in other common locations
$commonPaths = @(
    "$env:ProgramFiles\uv\bin\uv.exe",
    "$env:ProgramFiles\uv\bin\uvx.exe",
    "$env:LOCALAPPDATA\Programs\uv\uv.exe",
    "$env:LOCALAPPDATA\Programs\uv\uvx.exe"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed: $path" -ForegroundColor Green
    }
}

# Step 5: Remove uv configuration file
Write-Host ""
Write-Host "Step 5: Removing uv configuration..." -ForegroundColor Yellow
if (Test-Path $UV_CONFIG_FILE) {
    Remove-Item -Path $UV_CONFIG_FILE -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed config: $UV_CONFIG_FILE" -ForegroundColor Green
} else {
    Write-Host "  Config file not found: $UV_CONFIG_FILE" -ForegroundColor Gray
}

# Remove config directory if empty
if (Test-Path $UV_CONFIG_DIR) {
    $remainingItems = Get-ChildItem $UV_CONFIG_DIR -ErrorAction SilentlyContinue
    if (-not $remainingItems) {
        Remove-Item -Path $UV_CONFIG_DIR -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed empty config directory: $UV_CONFIG_DIR" -ForegroundColor Green
    } else {
        Write-Host "  Config directory not empty, keeping: $UV_CONFIG_DIR" -ForegroundColor Gray
    }
}

# Step 6: Remove custom cache directory
Write-Host ""
Write-Host "Step 6: Removing custom cache directory..." -ForegroundColor Yellow
if (Test-Path $CACHE_DIR) {
    Remove-Item -Path $CACHE_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed cache directory: $CACHE_DIR" -ForegroundColor Green
} else {
    Write-Host "  Cache directory not found: $CACHE_DIR" -ForegroundColor Gray
}

# Step 7: Remove virtual environments directory
Write-Host ""
Write-Host "Step 7: Removing virtual environments directory..." -ForegroundColor Yellow
if (Test-Path $TARGET_DIR) {
    Remove-Item -Path $TARGET_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed virtual env directory: $TARGET_DIR" -ForegroundColor Green
} else {
    Write-Host "  Virtual env directory not found: $TARGET_DIR" -ForegroundColor Gray
}

# Step 8: Remove uv loading from PowerShell profiles (PowerShell 7 and 5.1)
Write-Host ""
Write-Host "Step 8: Cleaning up PowerShell profiles..." -ForegroundColor Yellow

# Function to clean a profile
function Clean-Profile {
    param(
        [string]$profilePath,
        [string]$targetFile
    )
    
    if (Test-Path $profilePath) {
        # Create backup
        $backupPath = "$profilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $profilePath -Destination $backupPath -Force
        $script:backupProfiles += $backupPath
        Write-Host "  Backup created: $backupPath" -ForegroundColor Gray
        
        # Read current content
        $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        
        if ($content -and $content -match "Load uv environment management") {
            # Escape special regex characters in the target file path
            $escapedTargetFile = [regex]::Escape($targetFile)
            
            # Remove the uv section - handle different line endings
            $pattern = "(?s)\r?\n?# Load uv environment management.*?if \(Test-Path `"$escapedTargetFile`"\) {.*?\r?\n?}"
            $newContent = $content -replace $pattern, ""
            
            # Clean up extra blank lines
            $newContent = $newContent -replace "\r?\n\r?\n\r?\n", "`r`n`r`n"
            $newContent = $newContent -replace "^\s*\r?\n", "" -replace "\r?\n\s*$", ""
            
            # Write back if changed
            if ($newContent -ne $content) {
                if ($newContent.Trim()) {
                    Set-Content -Path $profilePath -Value $newContent -NoNewline
                } else {
                    # If profile is empty, remove it
                    Remove-Item -Path $profilePath -Force -ErrorAction SilentlyContinue
                    Write-Host "  Removed empty profile: $profilePath" -ForegroundColor Green
                    return
                }
                Write-Host "  Removed uv configuration from: $profilePath" -ForegroundColor Green
            } else {
                Write-Host "  uv configuration not found in: $profilePath" -ForegroundColor Gray
            }
        } else {
            Write-Host "  uv configuration not found in: $profilePath" -ForegroundColor Gray
        }
    }
}

# Clean PowerShell 7 profile
$ps7Profile = $PROFILE.CurrentUserCurrentHost
if ($ps7Profile) {
    Write-Host "  Checking PowerShell 7 profile..." -ForegroundColor Gray
    Clean-Profile -profilePath $ps7Profile -targetFile $TARGET_FILE
}

# Clean Windows PowerShell 5.1 profile
$ps5Profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $ps5Profile) {
    Write-Host "  Checking Windows PowerShell 5.1 profile..." -ForegroundColor Gray
    Clean-Profile -profilePath $ps5Profile -targetFile $TARGET_FILE
}

# Step 9: Remove environment variable (if any was set)
Write-Host ""
Write-Host "Step 9: Removing UV_CACHE_DIR environment variable..." -ForegroundColor Yellow
$existingVar = [Environment]::GetEnvironmentVariable("UV_CACHE_DIR", "User")
if ($existingVar) {
    [Environment]::SetEnvironmentVariable("UV_CACHE_DIR", $null, "User")
    Write-Host "  Removed UV_CACHE_DIR environment variable" -ForegroundColor Green
} else {
    Write-Host "  UV_CACHE_DIR environment variable not found" -ForegroundColor Gray
}

# Step 10: Remove uv from PATH (if installer added it) - FIXED VERSION
Write-Host ""
Write-Host "Step 10: Checking PATH for uv entries..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$localBinPath = "$env:USERPROFILE\.local\bin"

if ($userPath) {
    # Split PATH by semicolon and remove the .local/bin entry
    $paths = $userPath -split ';'
    $originalCount = $paths.Count
    $newPaths = $paths | Where-Object { $_ -ne $localBinPath }
    
    if ($newPaths.Count -lt $originalCount) {
        $newPath = $newPaths -join ';'
        
        # Clean up any double semicolons
        $newPath = $newPath -replace ';;', ';'
        # Remove leading/trailing semicolon
        $newPath = $newPath -replace '^;', '' -replace ';$', ''
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "  Removed $localBinPath from PATH" -ForegroundColor Green
        
        # Also update current session's PATH
        $env:Path = $newPath + ';' + $env:Path
    } else {
        Write-Host "  $localBinPath not found in PATH" -ForegroundColor Gray
    }
} else {
    Write-Host "  User PATH is empty, nothing to remove" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Uninstall completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The following items have been removed:" -ForegroundColor Green
Write-Host "  - uv cache data" -ForegroundColor White
Write-Host "  - uv python installations" -ForegroundColor White
Write-Host "  - uv tool installations" -ForegroundColor White
Write-Host "  - uv and uvx binaries" -ForegroundColor White
Write-Host "  - uv configuration file" -ForegroundColor White
Write-Host "  - Cache directory (D:\uv_cache)" -ForegroundColor White
Write-Host "  - Virtual environments directory (~\.uv_env)" -ForegroundColor White
Write-Host "  - PowerShell profile uv entries" -ForegroundColor White
Write-Host "  - UV_CACHE_DIR environment variable" -ForegroundColor White
Write-Host "  - $localBinPath from PATH" -ForegroundColor White
Write-Host ""

if ($backupProfiles.Count -gt 0) {
    Write-Host "Profile backups saved as:" -ForegroundColor Yellow
    foreach ($backup in $backupProfiles) {
        Write-Host "  - $backup" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "Please restart your PowerShell to complete the uninstall process." -ForegroundColor Yellow
Write-Host ""

# Wait for key press before exiting
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")