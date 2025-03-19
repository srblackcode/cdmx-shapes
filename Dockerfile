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
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    lsb-release \
    wget \
    gdal-bin \
    git-core \
    imagemagick \
    libcurl4-openssl-dev \
    libgdal-dev \
    libgeos-dev \
    libgit2-dev \
    libglpk-dev \
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
    protobuf-compiler \
    libprotobuf-dev \
    libjq-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    xdg-utils \
    libtiff5-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    mv phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
    rm -rf phantomjs-2.1.1-linux-x86_64.tar.bz2 phantomjs-2.1.1-linux-x86_64


# Copiar librerias de R
COPY site-library /usr/local/lib/R/site-library

# Copiar archivos del proyecto
WORKDIR /build_zone
COPY . /build_zone

# Eliminar archivos para evitar activar el entornovirtual
RUN rm -rf /build_zone/renv /build_zone/renv.lock

# Exponer el puerto de Shiny
EXPOSE 3838

# Comando final para ejecutar la aplicación
CMD R -e "options('shiny.port'=3838, shiny.host='0.0.0.0'); shiny::runApp(system.file('gobmx-shapes-app', package = 'gobmx.shapes'))"
