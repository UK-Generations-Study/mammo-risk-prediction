#!/bin/bash
set -e
LIB_PATH="/renv_library"
SRC_DIR="/home/rstudio/repo/src"
ENV_DIR="/home/rstudio/env"

# Ensure permissions on the internal library
mkdir -p "$LIB_PATH"
chown -R rstudio:rstudio "$LIB_PATH" /renv_cache

# --- PERSIST RSTUDIO PREFS ---
# Symlink the internal config file to the host file in env/
CONF_DIR="/home/rstudio/.config/rstudio"
HOST_PREFS="$ENV_DIR/rstudio-prefs.json"

mkdir -p "$CONF_DIR"

# If host file doesn't exist, create a default empty JSON
if [ ! -f "$HOST_PREFS" ]; then
    echo "{}" > "$HOST_PREFS"
    chown rstudio:rstudio "$HOST_PREFS"
fi

# Force symlink: Internal -> Host
rm -f "$CONF_DIR/rstudio-prefs.json"
ln -s "$HOST_PREFS" "$CONF_DIR/rstudio-prefs.json"
chown -R rstudio:rstudio /home/rstudio/.config
# -----------------------------

# 1. First Run Initialization
if [ ! -f "$ENV_DIR/renv/activate.R" ]; then
    echo ">> [RENV SETUP] First run: Initializing (Snapshot Type: implicit)..."
    
    sudo -u rstudio RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
                 RENV_PATHS_LOCKFILE="$ENV_DIR/renv.lock" \
                 RENV_PATHS_RENV="$ENV_DIR/renv" \
                 RENV_CONFIG_SNAPSHOT_TYPE="implicit" \
                 R -e "
        renv::init(project='$ENV_DIR', settings = list(use.cache = TRUE), restart = FALSE, bare = TRUE, force = TRUE);
        renv::snapshot(project='$SRC_DIR', type='implicit', prompt=FALSE)
    "
    rm -f "$SRC_DIR/.gitignore"
    rm -f "$SRC_DIR/.Rprofile"
fi

# 2. Boot Repair
# Even though we bake packages into the image now, we keep this check 
# to handle any manual changes or updates users make later.
echo ">> [RENV SETUP] Checking library integrity..."
sudo -u rstudio RENV_PATHS_LOCKFILE="$ENV_DIR/renv.lock" \
                RENV_PATHS_RENV="$ENV_DIR/renv" \
                R -e "renv::restore(project='$ENV_DIR', prompt = FALSE)"

# echo ">> [RENV SETUP] Done."
