FROM --platform=linux/amd64 rocker/r-ver:4.2

# Actualizar y preparar las dependencias iniciales
RUN apt-get update && apt-get install -y \
    ca-certificates \
    lsb-release \
    wget \
    gnupg && \
    rm -rf /var/lib/apt/lists/*

# Configurar el repositorio de Vivaldi y su clave GPG
RUN wget -qO- https://repo.vivaldi.com/stable/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/vivaldi-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/vivaldi-archive-keyring.gpg] https://repo.vivaldi.com/stable/deb stable main" > /etc/apt/sources.list.d/vivaldi.list

# Instalar Vivaldi
RUN apt-get update && apt-get install -y \
    vivaldi-stable && \
    rm -rf /var/lib/apt/lists/*

# Descargar e instalar Apache Arrow
RUN wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb -O /tmp/apache-arrow.deb && \
    apt-get update && \
    apt-get install -y /tmp/apache-arrow.deb && \
    rm /tmp/apache-arrow.deb && rm -rf /var/lib/apt/lists/*

# Instalar otras dependencias
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
    libjq-dev && \
    rm -rf /var/lib/apt/lists/*

# Configurar R con las opciones necesarias
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/ && \
    echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | \
    tee /usr/local/lib/R/etc/Rprofile.site /usr/lib/R/etc/Rprofile.site

# Configurar variables de entorno
ARG CKAN_URL
RUN echo "GITHUB_PAT=${GITHUB_PAT}" > .Renviron && \
    echo "ckanUrl=${CKAN_URL}" >> .Renviron && \
    echo "CHROMOTE_CHROME=/usr/bin/vivaldi" >> .Renviron

# Instalar paquetes R
RUN R -e 'install.packages("remotes")' && \
    Rscript -e 'remotes::install_version("rgdal", upgrade="never", version = "1.6-7")' && \
    Rscript -e 'remotes::install_version("sp", upgrade="never", version = "2.0")' && \
    Rscript -e 'remotes::install_version("sf", upgrade="never", version = "1.0-13")' && \
    Rscript -e 'remotes::install_version("stringi", upgrade="never", version = "1.7.12")' && \
    Rscript -e 'remotes::install_version("stringr", upgrade="never", version = "1.5.0")' && \
    Rscript -e 'remotes::install_version("shiny", upgrade="never", version = "1.7.4")' && \
    Rscript -e 'remotes::install_version("jsonlite", upgrade="never", version = "1.8.7")' && \
    Rscript -e 'remotes::install_version("purrr", upgrade="never", version = "1.0.1")' && \
    Rscript -e 'remotes::install_version("readr", upgrade="never", version = "2.1.4")' && \
    Rscript -e 'remotes::install_version("dplyr", upgrade="never", version = "1.1.2")' && \
    Rscript -e 'remotes::install_version("tidyr", upgrade="never", version = "1.3.0")' && \
    Rscript -e 'remotes::install_version("shinyjs", upgrade="never", version = "2.1.0")' && \
    Rscript -e 'remotes::install_version("leaflet", upgrade="never", version = "2.1.2")' && \
    Rscript -e 'remotes::install_version("config", upgrade="never", version = "0.3.1")' && \
    Rscript -e 'remotes::install_version("testthat", upgrade="never", version = "3.1.8")' && \
    Rscript -e 'remotes::install_version("spelling", upgrade="never", version = "2.2")' && \
    Rscript -e 'remotes::install_version("fs")' && \
    Rscript -e 'remotes::install_version("webshot2", upgrade="never", version = "0.1.0")' && \
    Rscript -e 'remotes::install_version("shinycustomloader", upgrade="never", version = "0.9.0")' && \
    Rscript -e 'remotes::install_version("shinybusy", upgrade="never", version = "0.3.1")' && \
    R -e 'install.packages("remotes")' && \
    Rscript -e 'remotes::install_github("datasketch/dstools", dependencies=TRUE)' && \
    Rscript -e 'remotes::install_github("CamilaAchuri/shinypanels@eeec45b196c99a91ae8033e95b0d52363ff1abc2")' && \
    Rscript -e 'remotes::install_github("datasketch/shinyinvoer@dd8178db99cac78f0abbd236e83e07bf1f22ba18")' && \
    Rscript -e 'remotes::install_github("datasketch/parmesan@d361f2047a6bb366a0adc271f0e264b62bd1e6e8")' && \
    Rscript -e 'remotes::install_version("markdown", upgrade="never", version = "1.2")' && \
    Rscript -e 'remotes::install_github("rstudio/chromote@e1d2997932671642d12bef0b4c58611e322035c7")' && \
    Rscript -e 'remotes::install_github("dreamRs/d3.format", dependencies=TRUE)' && \
    Rscript -e 'remotes::install_github("datasketch/homodatum", dependencies=TRUE)' && \
    Rscript -e 'remotes::install_version("DT")' && \
    Rscript -e 'remotes::install_github("datasketch/dsmodules")' && \
    Rscript -e 'remotes::install_github("srblackcode/cdmx-shapes")'

# Configurar zona de construcción
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone
RUN chmod -R 755 /build_zone
RUN rm -rf /build_zone

# Exponer el puerto de Shiny
EXPOSE 3838

# Comando final para ejecutar la aplicación
CMD R -e "options('shiny.port'=3838, shiny.host='0.0.0.0'); gobmx.shapes:::run_app()"
