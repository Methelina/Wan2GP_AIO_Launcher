[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host " ===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  ██▓        ██▓    ██▓        ██▓" -ForegroundColor Yellow
Write-Host " ▓██▒              ▓██▒" -ForegroundColor Yellow
Write-Host " ▒██░              ▒██░" -ForegroundColor Yellow
Write-Host " ▒██░              ▒██░" -ForegroundColor Yellow
Write-Host " ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓" -ForegroundColor Yellow
Write-Host " ░ ▒░▓  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▓▒" -ForegroundColor Yellow
Write-Host " ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░▒   ░▒" -ForegroundColor Yellow
Write-Host "   ░ ░    ░    ░     ░ ░    ░    ░" -ForegroundColor Yellow
Write-Host "     ░  ░  ░    ░      ░  ░  ░    ░" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Green
Write-Host "    Wan2GP Launcher & Installer (UV)" -ForegroundColor Yellow
Write-Host "    By Soror L.'.L.'." -ForegroundColor Yellow
Write-Host ""
Write-Host "    Automatic Setup for GTX/RTX GPUs" -ForegroundColor Green
Write-Host "    Python 3.10 / 3.11 Ready" -ForegroundColor Cyan
Write-Host "    Portable UV environment included" -ForegroundColor Cyan
Write-Host "    Listen & share enabled" -ForegroundColor Cyan
Write-Host ""

$ProjectName = "Wan2GP"
$RepoUrl = "https://github.com/deepbeepmeep/Wan2GP.git"
$ScriptDir = $PSScriptRoot
$InstallPath = Join-Path $ScriptDir $ProjectName
$EnvPath = Join-Path $InstallPath "env"
$PythonExe = Join-Path $EnvPath "Scripts\python.exe"
$WgpPy = Join-Path $InstallPath "wgp.py"
$ConfigFile = Join-Path $InstallPath ".wan2gp_config"

$UvBinDir = Join-Path $ScriptDir "Bin"
$UvExePath = Join-Path $UvBinDir "uv.exe"
$UvxExePath = Join-Path $UvBinDir "uvx.exe"
$UvVersion = "0.6.14"
$UvZipUrl = "https://github.com/astral-sh/uv/releases/download/$UvVersion/uv-x86_64-pc-windows-msvc.zip"

if (-not (Test-Path $UvBinDir)) { New-Item -ItemType Directory -Force -Path $UvBinDir | Out-Null }

function Write-Step {
    param($Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param($Message)
    Write-Host "  [+] $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "  [X] $Message" -ForegroundColor Red
}

function Write-Warning {
    param($Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Pause-Script {
    Read-Host "Press Enter to continue"
}

function Test-Command {
    param($Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Read-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [int]$DefaultIndex = 0
    )
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i+1). $($Options[$i])"
    }
    $choice = Read-Host "$Prompt (default $($DefaultIndex+1))"
    if ([string]::IsNullOrWhiteSpace($choice)) { return $DefaultIndex }
    $num = 0
    if ([int]::TryParse($choice, [ref]$num)) {
        if ($num -ge 1 -and $num -le $Options.Count) { return ($num - 1) }
    }
    return $DefaultIndex
}

function Ensure-Uv {
    if (Test-Path $UvExePath) {
        Write-Success "UV already installed at $UvExePath"
        $env:Path = "$UvBinDir;$env:Path"
        return $true
    }

    Write-Step "Downloading UV package manager ($UvVersion)..."
    $uvZip = Join-Path $ScriptDir "uv.zip"
    try {
        Invoke-WebRequest -Uri $UvZipUrl -OutFile $uvZip -UseBasicParsing
    } catch {
        Write-Error "Failed to download UV: $($_.Exception.Message)"
        return $false
    }

    if ((Get-Item $uvZip).Length -lt 1000) {
        Write-Error "Downloaded file too small, likely an error page."
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue
        return $false
    }

    $uvTmp = Join-Path $ScriptDir "uv_tmp"
    if (Test-Path $uvTmp) { Remove-Item $uvTmp -Recurse -Force }
    Expand-Archive -Path $uvZip -DestinationPath $uvTmp -Force
    $extractedDir = Get-ChildItem -Path $uvTmp -Directory | Select-Object -First 1
    if (-not $extractedDir) {
        $extractedDir = @{ FullName = $uvTmp }
    }
    Copy-Item (Join-Path $extractedDir.FullName "uv.exe") $UvExePath -Force
    Copy-Item (Join-Path $extractedDir.FullName "uvx.exe") $UvxExePath -Force -ErrorAction SilentlyContinue

    Remove-Item $uvTmp -Recurse -Force
    Remove-Item $uvZip -Force
    Write-Success "UV installed successfully."

    $env:Path = "$UvBinDir;$env:Path"
    return $true
}

function Invoke-UvPipInstall {
    param(
        [string[]]$Arguments
    )
    Write-Host "   > uv pip install $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $UvExePath pip install --python "$PythonExe" $Arguments
    return $LASTEXITCODE
}

function Get-FreePort {
    param([int]$StartPort = 7860)
    $port = $StartPort
    while ($true) {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if (-not $connection) {
            return $port
        }
        $port++
    }
}

Write-Step "Checking system requirements..."
if (!(Test-Command "git")) {
    Write-Error "Git not found. Please install Git and add to PATH."
    Pause-Script
    exit 1
}
Write-Success "Git found."

if (!(Ensure-Uv)) {
    Write-Error "Failed to set up UV. Please install manually."
    Pause-Script
    exit 1
}

$Action = "install"
if (Test-Path $InstallPath) {
    Write-Host ""
    Write-Host "Folder '$ProjectName' already exists." -ForegroundColor Yellow
    $choices = @("Run Wan2GP", "Reinstall (remove env and recreate)", "Update code (git pull) and reinstall", "Exit")
    $choice = Read-Choice "Select action" $choices 0
    switch ($choice) {
        0 { $Action = "launch" }
        1 { $Action = "reinstall" }
        2 { $Action = "update" }
        3 { exit 0 }
    }
    if ($Action -eq "launch" -and (Test-Path $EnvPath) -and (Test-Path $PythonExe) -and (Test-Path $WgpPy)) {
        $Action = "launch"
    } elseif ($Action -eq "launch") {
        Write-Error "Environment, python.exe, or wgp.py not found. Will perform installation."
        $Action = "install"
    }
}

if ($Action -eq "update" -or $Action -eq "reinstall") {
    if (Test-Path $EnvPath) {
        Write-Step "Removing old environment..."
        Remove-Item -Path $EnvPath -Recurse -Force
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to remove environment. Try manually."
            Pause-Script
        }
    }
    if ($Action -eq "update") {
        Write-Step "Updating code via git pull..."
        Push-Location $InstallPath
        git pull
        Pop-Location
    }
    $Action = "install"
}

if ($Action -eq "install") {
    Write-Host ""
    Write-Step "Select GPU configuration:"
    Write-Host "  1. GTX 10xx  (Python 3.10.9, PyTorch 2.7.1 + CUDA 12.8)"
    Write-Host "  2. RTX 20xx-50xx (Python 3.11.14, PyTorch 2.10.0 + CUDA 13.1)"
    $gpuChoice = Read-Host "Enter number (default 1)"

    if ($gpuChoice -eq "2") {
        $config = "RTX"
        $pythonVer = "3.11.14"
        $torchArgs = @("torch==2.10.0", "torchvision==0.25.0", "torchaudio==2.10.0", "--index-url", "https://download.pytorch.org/whl/cu130")
        $cudaVer = "13.1"
        $spargeWheel = "https://github.com/woct0rdho/SpargeAttn/releases/download/v0.1.0-windows.post4/spas_sage_attn-0.1.0%2Bcu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl"
        $flashWheel = "https://github.com/deepbeepmeep/kernels/releases/download/Flash2/flash_attn-2.8.3-cp311-cp311-win_amd64.whl"
        $ggufWheel = "https://github.com/deepbeepmeep/kernels/releases/download/GGUF_Kernels/llamacpp_gguf_cuda-1.0.2+torch210cu13py311-cp311-cp311-win_amd64.whl"
        $nunchakuWheel = "https://github.com/nunchaku-ai/nunchaku/releases/download/v1.2.1/nunchaku-1.2.1+cu13.0torch2.10-cp311-cp311-win_amd64.whl"
        Write-Host "Specify your GPU generation:"
        Write-Host "  1. RTX 20xx or 30xx"
        Write-Host "  2. RTX 40xx or 50xx"
        $subChoice = Read-Host "Enter number (default 1)"
        if ($subChoice -eq "2") {
            $tritonPkg = "triton-windows"
        } else {
            $tritonPkg = "triton-windows<3.3"
        }
        $sagePkg = "https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl"
        $bitsPkg = "bitsandbytes==0.49.2"
    } else {
        $config = "GTX"
        $pythonVer = "3.10.9"
        $torchArgs = @("torch==2.7.1", "torchvision==0.22.1", "torchaudio==2.7.1", "--index-url", "https://download.pytorch.org/whl/test/cu128")
        $cudaVer = "12.8"
        $spargeWheel = "https://github.com/woct0rdho/SpargeAttn/releases/download/v0.1.0-windows.post3/spas_sage_attn-0.1.0%2Bcu128torch2.7.1.post3-cp39-abi3-win_amd64.whl"
        $flashWheel = "https://github.com/Redtash1/Flash_Attention_2_Windows/releases/download/v2.7.0-v2.7.4/flash_attn-2.7.4.post1+cu128torch2.7.0cxx11abiFALSE-cp310-cp310-win_amd64.whl"
        $ggufWheel = "https://github.com/deepbeepmeep/kernels/releases/download/GGUF_Kernels/llamacpp_gguf_cuda-1.0.2+torch271cu128py310-cp310-cp310-win_amd64.whl"
        $nunchakuWheel = "https://github.com/deepbeepmeep/kernels/releases/download/v1.2.0_Nunchaku/nunchaku-1.2.0+torch2.7-cp310-cp310-win_amd64.whl"
        $tritonPkg = "triton-windows<3.3"
        $sagePkg = "sageattention==1.0.6"
        $bitsPkg = "bitsandbytes==0.49.2"
    }

    $configData = @{ Config = $config; Python = $pythonVer; Cuda = $cudaVer } | ConvertTo-Json

    if (!(Test-Path $InstallPath)) {
        Write-Step "Cloning repository..."
        git clone $RepoUrl $InstallPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to clone repository."
            Pause-Script
            exit 1
        }
    } else {
        Write-Step "Project folder already exists, skipping clone."
    }

    Write-Step "Creating Python virtual environment (Python $pythonVer) at $EnvPath ..."
    & $UvExePath venv $EnvPath --python $pythonVer
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create environment."
        Pause-Script
        exit 1
    }

    if (!(Test-Path $PythonExe)) {
        Write-Error "python.exe not found in environment."
        Pause-Script
        exit 1
    }

    Write-Step "Installing PyTorch with CUDA $cudaVer ..."
    $exitCode = Invoke-UvPipInstall -Arguments $torchArgs
    if ($exitCode -ne 0) {
        Write-Error "Failed to install PyTorch (code $exitCode)."
        Pause-Script
        exit 1
    }
    Write-Success "PyTorch installed."

    Write-Step "Installing dependencies from requirements.txt ..."
    $reqArgs = @(
        "-r", "$InstallPath\requirements.txt",
        "--index-strategy", "unsafe-best-match",
        "--index-url", "https://pypi.org/simple",
        "--extra-index-url", "https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/ort-cuda-13-nightly/pypi/simple/"
    )
    $exitCode = Invoke-UvPipInstall -Arguments $reqArgs
    if ($exitCode -ne 0) {
        Write-Error "Failed to install requirements.txt (code $exitCode)."
        Pause-Script
        exit 1
    }
    Write-Success "Base dependencies installed."

    Write-Host ""
    Write-Step "Installing all optional accelerators (SageAttention, FlashAttention, SpargeAttention, GGUF, Nunchaku, Bitsandbytes, Triton)..."

    Write-Step "Installing SageAttention..."
    $exitCode = Invoke-UvPipInstall -Arguments @($sagePkg)
    if ($exitCode -ne 0) { Write-Error "Failed to install SageAttention." }
    else { Write-Success "SageAttention installed." }

    Write-Step "Installing FlashAttention..."
    $exitCode = Invoke-UvPipInstall -Arguments @($flashWheel)
    if ($exitCode -ne 0) { Write-Error "Failed to install FlashAttention." }
    else { Write-Success "FlashAttention installed." }

    Write-Step "Installing SpargeAttention..."
    $exitCode = Invoke-UvPipInstall -Arguments @($spargeWheel)
    if ($exitCode -ne 0) { Write-Error "Failed to install SpargeAttention." }
    else { Write-Success "SpargeAttention installed." }

    Write-Step "Installing GGUF CUDA kernels..."
    $exitCode = Invoke-UvPipInstall -Arguments @($ggufWheel)
    if ($exitCode -ne 0) { Write-Error "Failed to install GGUF." }
    else { Write-Success "GGUF installed." }

    Write-Step "Installing Nunchaku (INT4/FP4)..."
    $exitCode = Invoke-UvPipInstall -Arguments @($nunchakuWheel)
    if ($exitCode -ne 0) { Write-Error "Failed to install Nunchaku." }
    else { Write-Success "Nunchaku installed." }

    Write-Step "Installing Bitsandbytes (NF4)..."
    $exitCode = Invoke-UvPipInstall -Arguments @($bitsPkg)
    if ($exitCode -ne 0) { Write-Error "Failed to install Bitsandbytes." }
    else { Write-Success "Bitsandbytes installed." }

    Write-Step "Installing Triton..."
    $exitCode = Invoke-UvPipInstall -Arguments @($tritonPkg)
    if ($exitCode -ne 0) { Write-Error "Failed to install Triton." }
    else { Write-Success "Triton installed." }

    $configData | Out-File -FilePath $ConfigFile -Encoding utf8
    Write-Success "Installation complete!"
    Write-Host ""
}

if ($Action -ne "install" -or $?) {
    if (!(Test-Path $WgpPy)) {
        Write-Error "wgp.py not found. Please install Wan2GP before launching."
        Pause-Script
        exit 1
    }

    if (!(Test-Path $PythonExe)) {
        Write-Error "python.exe not found. Run installation first."
        Pause-Script
        exit 1
    }

    do {
        Write-Host ""
        Write-Host "============ LAUNCH MENU ============" -ForegroundColor Cyan
        Write-Host "  1. Basic (GUI, choose model from dropdown)"
        Write-Host "  2. Image-to-Video (--i2v)"
        Write-Host "  3. T2V 1.3B (faster, --t2v-1-3B)"
        Write-Host "  4. T2V 14B (larger, --t2v-14B)"
        Write-Host "  5. Exit"
        Write-Host ""

        $runChoice = Read-Host "Select mode (default 1)"
        $modeArgs = @()
        switch ($runChoice) {
            "2" { $modeArgs += "--i2v" }
            "3" { $modeArgs += "--t2v-1-3B" }
            "4" { $modeArgs += "--t2v-14B" }
            "5" { exit 0 }
            default { $modeArgs = @() }
        }

        $freePort = Get-FreePort
        Write-Success "Using port $freePort"

        $allArgs = $modeArgs + @("--listen", "--share", "--server-port", $freePort)

        Write-Step "Launching Wan2GP with arguments: $($allArgs -join ' ')"
        Push-Location $InstallPath
        & $PythonExe wgp.py $allArgs
        $exitCode = $LASTEXITCODE
        Pop-Location

        if ($exitCode -ne 0) {
            Write-Error "Launch failed with code $exitCode."
        } else {
            Write-Success "Launch finished."
        }

        Write-Host ""
        $continue = Read-Host "Run again? (y/n, default y)"
    } while ($continue -ne "n")
}

Pause-Script