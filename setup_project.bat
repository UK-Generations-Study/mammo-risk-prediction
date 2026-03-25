<# :
@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join [Environment]::NewLine)"
pause
exit /b
#>

# ----------------------------------------------------------------------
# POWERSHELL LOGIC STARTS HERE
# ----------------------------------------------------------------------
$ErrorActionPreference = "Stop"
Set-Location $PWD 

# --- TOGGLE SETTING ---
$Use_All_Snapshot = $false
# ----------------------

if (Test-Path "docker-compose.yml") {
    Write-Host ">> Configuration found (docker-compose.yml)."
    Write-Host ">> Setup is already complete. Starting environment..."
    docker compose up -d
    Start-Sleep -Seconds 2
    Start-Process "http://127.0.0.1:8787"
} else {

    # 1. Configuration Inputs
    $R_Version = Read-Host -Prompt "Enter R Version (e.g., 4.4.1 or latest)"
    $Project_Name = Read-Host -Prompt "Enter Project Name"

    # ------------------------------------------------------------------
    # 2. CIFS/NETWORK VOLUME WIZARD
    # ------------------------------------------------------------------
    Write-Host "`n>> STEP 1: NETWORK VOLUME CONFIGURATION" -ForegroundColor Cyan
    $externalVolumes = @()
    $volumeMappings = @()
    $volumePathMap = @{} # Dictionary to remember where each volume is mounted

    while ($true) {
        $addVol = Read-Host "Would you like to add a CIFS/Network volume? (y/n, default: n)"
        if ($addVol -ne "y") { break }

        $volName = Read-Host "Enter a name for this volume (e.g., rds_data_vol)"
        
        $volumeExists = docker volume ls -q --filter name="^${volName}$"
        if (!$volumeExists) {
            Write-Host ">> Volume '${volName}' not found. Creating securely..." -ForegroundColor Yellow
            $device   = Read-Host "Enter the network path (e.g., //rds.domain.uk/Data/Project)"
            $domain   = Read-Host "Enter your network domain"
            $username = Read-Host "Enter your network username"
            $SecurePassword = Read-Host -Prompt "Enter your network password" -AsSecureString
            $Cred = [System.Net.NetworkCredential]::new("", $SecurePassword).Password

            docker volume create --driver local --opt type=cifs --opt device="$device" `
               --opt o="username=$username,domain=$domain,password=$Cred,file_mode=0777,dir_mode=0777" `
               $volName | Out-Null
            $Cred = "" 
        }

        $mountPath = Read-Host "Where should this appear inside RStudio? (default: /home/rstudio/${volName})"
        if ([string]::IsNullOrWhiteSpace($mountPath)) { $mountPath = "/home/rstudio/${volName}" }

        # Store configuration
        $volumePathMap[$volName] = $mountPath
        $externalVolumes += "  ${volName}:`n    external: true"
        $volumeMappings  += "      - ${volName}:${mountPath}"
        Write-Host "---"
    }

    # ------------------------------------------------------------------
    # 3. SOURCE DIRECTORY CONFIGURATION
    # ------------------------------------------------------------------
    Write-Host "`n>> STEP 2: SOURCE DIRECTORY SETUP" -ForegroundColor Cyan
    if ($volumePathMap.Count -gt 0) {
        Write-Host "Available Volumes: $($volumePathMap.Keys -join ', ')"
    }
    Write-Host "Enter the source for your R code (one of the volumes above, or a Windows path like ./src)"
    
    $Src_Input = Read-Host "Source selection (default: ./src)"
    if ([string]::IsNullOrWhiteSpace($Src_Input)) { $Src_Input = "./src" }

    # Logic: If it's a volume, use its predefined internal path. If it's a path, use /home/rstudio/src.
    if ($volumePathMap.ContainsKey($Src_Input)) {
        $Internal_Src_Path = $volumePathMap[$Src_Input]
        # Remove this mapping from the "Extra" list to avoid YAML duplicates
        $volumeMappings = $volumeMappings | Where-Object { $_ -notmatch " - ${Src_Input}:" }
        $Src_Mapping = "      - ${Src_Input}:${Internal_Src_Path}"
    } else {
        $Internal_Src_Path = "/home/rstudio/src"
        $Src_Mapping = "      - ${Src_Input}:${Internal_Src_Path}"
        # Create local folder only if using relative path
        if ($Src_Input -eq "./src" -and !(Test-Path "src")) { New-Item -ItemType Directory -Force -Path "src" | Out-Null }
    }

    # ------------------------------------------------------------------
    # 4. DIRECTORY & STARTUP SETUP (Using Dynamic Path)
    # ------------------------------------------------------------------
    Write-Host "`n>> STEP 3: FINALIZING FILES..." -ForegroundColor Cyan
    
    if (!(Test-Path "env")) { New-Item -ItemType Directory -Force -Path "env" | Out-Null }
    if (!(Test-Path "env/renv/cache")) { New-Item -ItemType Directory -Force -Path "env/renv/cache" | Out-Null }
    if (!(Test-Path "env/renv.lock")) { "{}" | Out-File -FilePath "env/renv.lock" -Encoding ASCII -NoNewline }

    $snapshotType = if ($Use_All_Snapshot) { "all" } else { "implicit" }
    
    # Generate Startup Script using the dynamic internal path
    $startupScript = @"
#!/bin/bash
set -e
LIB_PATH="/renv_library"
SRC_DIR="$Internal_Src_Path"
ENV_DIR="/home/rstudio/env"

mkdir -p "`$LIB_PATH"
chown -R rstudio:rstudio "`$LIB_PATH" /renv_cache

# RStudio Prefs
CONF_DIR="/home/rstudio/.config/rstudio"
HOST_PREFS="`$ENV_DIR/rstudio-prefs.json"
mkdir -p "`$CONF_DIR"
if [ ! -f "`$HOST_PREFS" ]; then echo "{}" > "`$HOST_PREFS"; chown rstudio:rstudio "`$HOST_PREFS"; fi
rm -f "`$CONF_DIR/rstudio-prefs.json"
ln -s "`$HOST_PREFS" "`$CONF_DIR/rstudio-prefs.json"
chown -R rstudio:rstudio /home/rstudio/.config

# renv Logic
if [ ! -f "`$ENV_DIR/renv/activate.R" ]; then
    echo ">> [RENV] Initializing in `$SRC_DIR..."
    sudo -u rstudio RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
                 RENV_PATHS_LOCKFILE="`$ENV_DIR/renv.lock" \
                 RENV_PATHS_RENV="`$ENV_DIR/renv" \
                 R -e "renv::init(project='`$ENV_DIR', settings = list(use.cache = TRUE), restart = FALSE, bare = TRUE, force = TRUE); renv::snapshot(project='`$SRC_DIR', type='$snapshotType', prompt=FALSE)"
    rm -f "`$SRC_DIR/.gitignore" "`$SRC_DIR/.Rprofile"
fi

sudo -u rstudio RENV_PATHS_LOCKFILE="`$ENV_DIR/renv.lock" RENV_PATHS_RENV="`$ENV_DIR/renv" R -e "renv::restore(project='`$ENV_DIR', prompt = FALSE)"
"@
    $startupScript | Out-File -FilePath "env/.startup.sh" -Encoding ASCII

    # Generate Dockerfile using dynamic internal path
    $dockerfileContent = @"
FROM rocker/rstudio:$R_Version
RUN apt-get update && apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev git dos2unix curl ca-certificates && rm -rf /var/lib/apt/lists/*
ENV RENV_PATHS_LIBRARY=/renv_library
ENV RENV_PATHS_LOCKFILE=/home/rstudio/env/renv.lock
ENV RENV_PATHS_RENV=/home/rstudio/env/renv
ENV RENV_PATHS_CACHE=/renv_cache
RUN echo "if (file.exists('/home/rstudio/env/renv/activate.R')) source('/home/rstudio/env/renv/activate.R')" >> /usr/local/lib/R/etc/Rprofile.site
RUN R -e 'install.packages(c("remotes", "renv"))'
RUN mkdir -p /home/rstudio/env $Internal_Src_Path /renv_library /renv_cache && chown rstudio:rstudio /renv_library /renv_cache
WORKDIR $Internal_Src_Path
RUN echo "session-default-working-dir=$Internal_Src_Path" >> /etc/rstudio/rsession.conf
COPY env/.startup.sh /etc/cont-init.d/03_renv_setup
RUN dos2unix /etc/cont-init.d/03_renv_setup && chmod +x /etc/cont-init.d/03_renv_setup
"@
    $dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding ASCII

    # ------------------------------------------------------------------
    # 5. GENERATE DOCKER-COMPOSE.YML
    # ------------------------------------------------------------------
    $mappingString = if ($volumeMappings.Count -gt 0) { $volumeMappings -join "`n" } else { "" }
    $volumeDefString = if ($externalVolumes.Count -gt 0) { "`nvolumes:`n" + ($externalVolumes -join "`n") } else { "" }

    $composeContent = @"
services:
  rstudio:
    build: .
    container_name: $Project_Name
    ports:
      - "127.0.0.1:8787:8787"
    environment:
      - DISABLE_AUTH=true
    volumes:
$Src_Mapping
      - ./env:/home/rstudio/env
      - ./env/renv/cache:/renv_cache
$mappingString
$volumeDefString
"@
    $composeContent | Out-File -FilePath "docker-compose.yml" -Encoding ASCII

    # 6. Launch
    Write-Host ">> Launching..."
    docker compose down
    docker compose up -d --build
    Start-Sleep -Seconds 5
    Start-Process "http://127.0.0.1:8787"
}