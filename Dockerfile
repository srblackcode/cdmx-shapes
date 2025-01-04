FROM --platform=linux/amd64 rocker/r-ver:4.2

# Actualizar y agregar dependencias iniciales
RUN apt-get update && apt-get install -y \
    ca-certificates \
    lsb-release \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Añadir claves GPG y repositorios necesarios
RUN wget -qO- https://repo.vivaldi.com/stable/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/vivaldi-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/vivaldi-keyring.gpg] https://repo.vivaldi.com/stable/deb stable main" > /etc/apt/sources.list.d/vivaldi.list

RUN wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    && dpkg -i apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    && apt-get update

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gdal-bin \
    git-core \
    imagemagick \
    libcurl4-openssl-dev \
    libgdal-dev \
    libgeos-dev \
    libgeos++-dev \
    libgit2-dev \
    libglpk-dev \
    libgmp-dev \
    libicu-dev \
    libpng-dev \
    libproj-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pandoc \
    pandoc-citeproc \
    zlib1g-dev \
    libmagick++-dev \
    libpoppler-cpp-dev \
    libudunits2-dev \
    libarrow-dev \
    protobuf-compiler \
    libprotobuf-dev \
    libjq-dev \
    vivaldi-stable \
    && rm -rf /var/lib/apt/lists/*

# Configurar R
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/ \
    && echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site /usr/lib/R/etc/Rprofile.site

RUN echo "GITHUB_PAT=${GITHUB_PAT}" > .Renviron

# Instalar paquetes de R
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("rgdal", version = "1.6-7", upgrade = "never")'
RUN Rscript -e 'remotes::install_version("sf", version = "1.0-13", upgrade = "never")'
RUN Rscript -e 'remotes::install_github("datasketch/dstools", dependencies = TRUE)'

# Variables de entorno
ARG CKAN_URL
RUN echo "ckanUrl=${CKAN_URL}" >> .Renviron
RUN echo "CHROMOTE_CHROME=/usr/bin/vivaldi" >> .Renviron

# Exposición de puertos
EXPOSE 3838

# Comando final
CMD R -e "options('shiny.port' = 3838, shiny.host = '0.0.0.0'); cdmx.shapes:::run_app_ciudadano()"
