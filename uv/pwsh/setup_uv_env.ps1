# setup_uv_env.ps1
# Auto-elevation version - double-click to run

# Auto-elevate: restart as administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "uv Environment Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$TARGET_DIR = "$env:USERPROFILE\.uv_env"
$TARGET_FILE = "$TARGET_DIR\Microsoft.PowerShell_profile.ps1"
$UV_CONFIG_DIR = "$env:APPDATA\uv"
$UV_CONFIG_FILE = "$UV_CONFIG_DIR\uv.toml"

# Install uv if not already installed
if (!(Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "Installing uv..." -ForegroundColor Yellow
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
    $localBin = "$env:USERPROFILE\.local\bin"
    if (Test-Path $localBin) {
        $env:Path = "$localBin;$env:Path"
    }
    Write-Host "uv installed successfully" -ForegroundColor Green
} else {
    Write-Host "uv already installed: $(uv --version)" -ForegroundColor Green
}

# Configure uv with Aliyun mirror and custom cache directory
New-Item -ItemType Directory -Force -Path $UV_CONFIG_DIR | Out-Null
@"
[[index]]
url = "http://mirrors.aliyun.com/pypi/simple/"
default = true

cache-dir = "D:\\uv_cache"
"@ | Out-File -FilePath $UV_CONFIG_FILE -Encoding utf8

Write-Host "uv config created at: $UV_CONFIG_FILE" -ForegroundColor Green

# Create cache directory
New-Item -ItemType Directory -Force -Path "D:\uv_cache" | Out-Null
Write-Host "Cache directory created: D:\uv_cache" -ForegroundColor Green

# Create target directory
New-Item -ItemType Directory -Force -Path $TARGET_DIR | Out-Null

# Write function definitions
@'
# PowerShell functions and aliases

# Set uv cache directory
$env:UV_CACHE_DIR = "D:\uv_cache"

function vc {
    param(
        [Parameter(Mandatory=$true)]
        [string]$env_name,
        [string]$py_version = "3.12"
    )
    
    $current_dir = Get-Location
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.uv_env" | Out-Null
    Set-Location "$env:USERPROFILE\.uv_env"
    uv venv $env_name --python $py_version
    Set-Location $current_dir
}

function vl {
    if (Test-Path "$env:USERPROFILE\.uv_env") {
        Get-ChildItem -Path "$env:USERPROFILE\.uv_env" -Directory | Select-Object -ExpandProperty Name
    } else {
        Write-Host "Error: ~/.uv_env directory does not exist" -ForegroundColor Red
    }
}

function va {
    param([string]$env_name = "Torch")
    
    $activate_script = "$env:USERPROFILE\.uv_env\$env_name\Scripts\Activate.ps1"
    if (Test-Path $activate_script) {
        & $activate_script
    } else {
        Write-Host "Error: Environment $env:USERPROFILE\.uv_env\$env_name not found" -ForegroundColor Red
    }
}

function vd {
    if ($env:VIRTUAL_ENV) {
        deactivate
    } else {
        Write-Host "No virtual environment is active" -ForegroundColor Yellow
    }
}

function pip {
    param(
        [Parameter(Position=0)]
        [string]$command,
        [Parameter(ValueFromRemainingArguments=$true)]
        $remainingArgs
    )
    
    if ($command -eq "install" -and !$env:VIRTUAL_ENV) {
        Write-Host "Error: You are NOT in a virtual environment. 'pip install' is blocked!" -ForegroundColor Red
        Write-Host "Please activate an environment first using 'va [name]' or create one via 'vc'." -ForegroundColor Yellow
        return
    }
    
    uv pip @($command) @remainingArgs
}

function pip3 {
    pip @args
}

'@ | Out-File -FilePath $TARGET_FILE -Encoding utf8

Write-Host "Function file created at: $TARGET_FILE" -ForegroundColor Green

# ========== Create PowerShell profile if it doesn't exist ==========
Write-Host ""
Write-Host "Setting up PowerShell profile..." -ForegroundColor Yellow

# Get the correct profile path for current PowerShell version
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path $profilePath -Parent

# Ensure profile directory exists
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    Write-Host "Created profile directory: $profileDir" -ForegroundColor Green
}

# Loading code to add
$loadingCode = @"

# Load uv environment management
if (Test-Path "$TARGET_FILE") {
    . "$TARGET_FILE"
}
"@

# Create or update profile
if (Test-Path $profilePath) {
    $currentContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($currentContent -notmatch "Load uv environment management") {
        Add-Content -Path $profilePath -Value $loadingCode
        Write-Host "Added uv loading to existing profile: $profilePath" -ForegroundColor Green
    } else {
        Write-Host "uv loading already present in profile: $profilePath" -ForegroundColor Gray
    }
} else {
    # Profile doesn't exist - create it
    $loadingCode | Out-File -FilePath $profilePath -Encoding utf8 -Force
    Write-Host "Created new PowerShell profile with uv loading: $profilePath" -ForegroundColor Green
}

# Also create the other PowerShell edition's profile for compatibility
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # Running in PowerShell 7 - also add to Windows PowerShell 5.1 profile
    $ps5ProfilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $ps5ProfileDir = Split-Path $ps5ProfilePath -Parent
    
    if (-not (Test-Path $ps5ProfileDir)) {
        New-Item -ItemType Directory -Force -Path $ps5ProfileDir | Out-Null
    }
    
    if (Test-Path $ps5ProfilePath) {
        $ps5Content = Get-Content $ps5ProfilePath -Raw -ErrorAction SilentlyContinue
        if ($ps5Content -notmatch "Load uv environment management") {
            Add-Content -Path $ps5ProfilePath -Value $loadingCode
            Write-Host "Also added to Windows PowerShell 5.1 profile: $ps5ProfilePath" -ForegroundColor Green
        }
    } else {
        $loadingCode | Out-File -FilePath $ps5ProfilePath -Encoding utf8 -Force
        Write-Host "Created Windows PowerShell 5.1 profile: $ps5ProfilePath" -ForegroundColor Green
    }
} else {
    # Running in Windows PowerShell 5.1 - also add to PowerShell 7 profile
    $ps7ProfilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $ps7ProfileDir = Split-Path $ps7ProfilePath -Parent
    
    if (-not (Test-Path $ps7ProfileDir)) {
        New-Item -ItemType Directory -Force -Path $ps7ProfileDir | Out-Null
    }
    
    if (Test-Path $ps7ProfilePath) {
        $ps7Content = Get-Content $ps7ProfilePath -Raw -ErrorAction SilentlyContinue
        if ($ps7Content -notmatch "Load uv environment management") {
            Add-Content -Path $ps7ProfilePath -Value $loadingCode
            Write-Host "Also added to PowerShell 7 profile: $ps7ProfilePath" -ForegroundColor Green
        }
    } else {
        $loadingCode | Out-File -FilePath $ps7ProfilePath -Encoding utf8 -Force
        Write-Host "Created PowerShell 7 profile: $ps7ProfilePath" -ForegroundColor Green
    }
}

# Load functions for current session
. $TARGET_FILE

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "uv installed and configured" -ForegroundColor Green
Write-Host "Config file: $UV_CONFIG_FILE" -ForegroundColor Green
Write-Host "Cache directory: D:\uv_cache" -ForegroundColor Green
Write-Host "Virtual env directory: $env:USERPROFILE\.uv_env" -ForegroundColor Green
Write-Host "PowerShell profile: $profilePath" -ForegroundColor Green
Write-Host ""
Write-Host "Commands available NOW in this session:" -ForegroundColor Cyan
Write-Host "   vc <name> [version]  - Create new virtual environment" -ForegroundColor White
Write-Host "   vl                    - List all environments" -ForegroundColor White
Write-Host "   va [name]             - Activate environment (default: Torch)" -ForegroundColor White
Write-Host "   vd                    - Deactivate current environment" -ForegroundColor White
Write-Host ""
Write-Host "Functions will also be available in NEW PowerShell sessions." -ForegroundColor Green
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")