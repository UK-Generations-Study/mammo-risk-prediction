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
# Set to $true to capture ALL installed packages immediately.
# Set to $false to only capture packages used in your code.
$Use_All_Snapshot = $false
# ----------------------

if (Test-Path "docker-compose.yml") {
    Write-Host ">> Configuration found (docker-compose.yml)."
    Write-Host ">> Setup is already complete."
    Write-Host ">> To start the environment, run the following in your terminal:"
    Write-Host "   docker compose up -d"
} else {

    # 1. Configuration Inputs
    $R_Version = Read-Host -Prompt "Enter R Version (e.g., 4.4.1 or latest)"
    $Project_Name = Read-Host -Prompt "Enter Project Name"

    # 2. Directory Setup
    Write-Host ">> Setting up folder structure..."
    if (!(Test-Path "src")) { New-Item -ItemType Directory -Force -Path "src" | Out-Null }
    if (!(Test-Path "env")) { New-Item -ItemType Directory -Force -Path "env" | Out-Null }
    if (!(Test-Path "env/renv")) { New-Item -ItemType Directory -Force -Path "env/renv" | Out-Null }
    
    # Cache is nested deep inside env/renv/cache
    if (!(Test-Path "env/renv/cache")) { New-Item -ItemType Directory -Force -Path "env/renv/cache" | Out-Null }
    
    if (!(Test-Path "env/renv.lock")) { "{}" | Out-File -FilePath "env/renv.lock" -Encoding ASCII -NoNewline }

    # 3. Create .gitignore
    @"
env/renv/library/
env/renv/python/
env/renv/staging/
env/renv/cache/
.DS_Store
.Rproj.user
.Rhistory
.RData
!env/.startup.sh
"@ | Out-File -FilePath ".gitignore" -Encoding ASCII

    # 4. Create the Startup Script
    # This runs automatically via S6 on every container start.
    $snapshotType = if ($Use_All_Snapshot) { "all" } else { "implicit" }

    $startupScript = @"
#!/bin/bash
set -e
LIB_PATH="/renv_library"
SRC_DIR="/home/rstudio/src"
ENV_DIR="/home/rstudio/env"

# Ensure permissions on the internal library
mkdir -p "`$LIB_PATH"
chown -R rstudio:rstudio "`$LIB_PATH" /renv_cache

# --- PERSIST RSTUDIO PREFS ---
# Symlink the internal config file to the host file in env/
CONF_DIR="/home/rstudio/.config/rstudio"
HOST_PREFS="`$ENV_DIR/rstudio-prefs.json"

mkdir -p "`$CONF_DIR"

# If host file doesn't exist, create a default empty JSON
if [ ! -f "`$HOST_PREFS" ]; then
    echo "{}" > "`$HOST_PREFS"
    chown rstudio:rstudio "`$HOST_PREFS"
fi

# Force symlink: Internal -> Host
rm -f "`$CONF_DIR/rstudio-prefs.json"
ln -s "`$HOST_PREFS" "`$CONF_DIR/rstudio-prefs.json"
chown -R rstudio:rstudio /home/rstudio/.config
# -----------------------------

# 1. First Run Initialization
if [ ! -f "`$ENV_DIR/renv/activate.R" ]; then
    echo ">> [RENV SETUP] First run: Initializing (Snapshot Type: $snapshotType)..."
    
    sudo -u rstudio RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
                 RENV_PATHS_LOCKFILE="`$ENV_DIR/renv.lock" \
                 RENV_PATHS_RENV="`$ENV_DIR/renv" \
                 RENV_CONFIG_SNAPSHOT_TYPE="$snapshotType" \
                 R -e "
        renv::init(project='`$ENV_DIR', settings = list(use.cache = TRUE), restart = FALSE, bare = TRUE, force = TRUE);
        renv::snapshot(project='`$SRC_DIR', type='$snapshotType', prompt=FALSE)
    "
    rm -f "`$SRC_DIR/.gitignore"
    rm -f "`$SRC_DIR/.Rprofile"
fi

# 2. Boot Repair
# Even though we bake packages into the image now, we keep this check 
# to handle any manual changes or updates users make later.
echo ">> [RENV SETUP] Checking library integrity..."
sudo -u rstudio RENV_PATHS_LOCKFILE="`$ENV_DIR/renv.lock" \
                RENV_PATHS_RENV="`$ENV_DIR/renv" \
                R -e "renv::restore(project='`$ENV_DIR', prompt = FALSE)"

# echo ">> [RENV SETUP] Done."
"@
    $startupScript | Out-File -FilePath "env/.startup.sh" -Encoding ASCII

    # 5. Create Dockerfile
    $dockerfileContent = @"
FROM rocker/rstudio:$R_Version

RUN apt-get update && apt-get install -y \
    libxml2-dev libssl-dev libcurl4-openssl-dev \
    git dos2unix curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# GLOBAL CONFIGURATION
ENV RENV_PATHS_LIBRARY=/renv_library
ENV RENV_PATHS_LOCKFILE=/home/rstudio/env/renv.lock
ENV RENV_PATHS_RENV=/home/rstudio/env/renv
ENV RENV_PATHS_CACHE=/renv_cache
ENV RENV_CONFIG_AUTO_SNAPSHOT=TRUE
ENV RENV_CONFIG_SNAPSHOT_TYPE=$snapshotType

RUN echo "RENV_PATHS_LIBRARY=/renv_library" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_LOCKFILE=/home/rstudio/env/renv.lock" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_RENV=/home/rstudio/env/renv" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_CACHE=/renv_cache" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_CONFIG_AUTO_SNAPSHOT=TRUE" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_CONFIG_SNAPSHOT_TYPE=$snapshotType" >> /usr/local/lib/R/etc/Renviron.site

RUN echo "if (file.exists('/home/rstudio/env/renv/activate.R')) source('/home/rstudio/env/renv/activate.R')" >> /usr/local/lib/R/etc/Rprofile.site

RUN R -e 'install.packages(c("remotes", "renv"))'

RUN mkdir -p /home/rstudio/env /home/rstudio/src
COPY env/renv.lock /home/rstudio/env/renv.lock
COPY env/renv/ /home/rstudio/env/renv/
# Create cache dir inside image
RUN mkdir -p /renv_library /renv_cache && chown rstudio:rstudio /renv_library /renv_cache

WORKDIR /home/rstudio/env

# BUILD CACHE: Persist downloads internally during builds
# KEY FIX: RENV_CONFIG_CACHE_SYMLINKS=FALSE
# This forces renv to copy files (physical install) instead of using symlinks.
# This prevents broken links when the container runs on a new machine.
RUN --mount=type=cache,target=/renv_cache \
    RENV_CONFIG_CACHE_SYMLINKS=FALSE \
    R -e "if (file.exists('renv/activate.R')) { source('renv/activate.R'); renv::restore(prompt = FALSE) }"

RUN chown -R rstudio:rstudio /home/rstudio/src /home/rstudio/env
WORKDIR /home/rstudio/src
RUN echo "session-default-working-dir=/home/rstudio/src" >> /etc/rstudio/rsession.conf

# Setup S6 init script
COPY env/.startup.sh /etc/cont-init.d/03_renv_setup
RUN dos2unix /etc/cont-init.d/03_renv_setup && chmod +x /etc/cont-init.d/03_renv_setup
"@
    $dockerfileContent | Out-File -FilePath "Dockerfile" -Encoding ASCII

    # 6. Create docker-compose.yml
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
      - ./src:/home/rstudio/src
      - ./env:/home/rstudio/env
      # Map host env/renv/cache to internal /renv_cache
      - ./env/renv/cache:/renv_cache
"@
    $composeContent | Out-File -FilePath "docker-compose.yml" -Encoding ASCII

    # 7. Launch (ONLY ON FIRST RUN)
    Write-Host ">> Initializing project for the first time..."
    docker compose down
    docker compose up -d --build
    Start-Sleep -Seconds 5
    Start-Process "http://127.0.0.1:8787"
}
