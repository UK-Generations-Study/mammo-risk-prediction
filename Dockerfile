FROM rocker/rstudio:4.4.1

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
ENV RENV_CONFIG_SNAPSHOT_TYPE=implicit

RUN echo "RENV_PATHS_LIBRARY=/renv_library" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_LOCKFILE=/home/rstudio/env/renv.lock" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_RENV=/home/rstudio/env/renv" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_PATHS_CACHE=/renv_cache" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_CONFIG_AUTO_SNAPSHOT=TRUE" >> /usr/local/lib/R/etc/Renviron.site && \
    echo "RENV_CONFIG_SNAPSHOT_TYPE=implicit" >> /usr/local/lib/R/etc/Renviron.site

RUN echo "if (file.exists('/home/rstudio/env/renv/activate.R')) source('/home/rstudio/env/renv/activate.R')" >> /usr/local/lib/R/etc/Rprofile.site

RUN R -e 'install.packages(c("remotes", "renv"))'

RUN mkdir -p /home/rstudio/env /home/rstudio/data /home/rstudio/repo/src /home/rstudio/repo/results
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

RUN chown -R rstudio:rstudio /home/rstudio/repo /home/rstudio/env
WORKDIR /home/rstudio/repo/src
RUN echo "session-default-working-dir=/home/rstudio/repo/src" >> /etc/rstudio/rsession.conf

# Setup S6 init script
COPY env/.startup.sh /etc/cont-init.d/03_renv_setup
RUN dos2unix /etc/cont-init.d/03_renv_setup && chmod +x /etc/cont-init.d/03_renv_setup
