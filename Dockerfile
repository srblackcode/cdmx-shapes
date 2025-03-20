# Usar la imagen base de R con la versión 4.2
FROM --platform=linux/amd64 rocker/r-ver:4.2

# Definir variables de entorno
ENV TZ=Etc/UTC \
    R_HOME=/usr/local/lib/R \
    R_VERSION=4.2.1 \
    LANG=en_US.UTF-8 \
    CRAN=https://packagemanager.rstudio.com/cran/__linux__/focal/latest

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

# Instalar otras dependencias necesarias para R y Shiny
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
    bzip2 \
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

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:rael-gc/rvm && \
    apt-get update && \
    apt-get install -y libssl1.1

# CORRECCIÓN: Instalar Google Chrome en lugar de Chromium
RUN wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable

# CORRECCIÓN: Establecer Google Chrome como navegador predeterminado
ENV CHROMOTE_CHROME="/usr/bin/google-chrome"

RUN cd /tmp && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    mv phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
    rm -rf phantomjs-2.1.1-linux-x86_64.tar.bz2 phantomjs-2.1.1-linux-x86_64

# Copiar librerías de R previamente instaladas
COPY site-library /usr/local/lib/R/site-library

# Definir directorio de trabajo
WORKDIR /build_zone
COPY . /build_zone

# Eliminar archivos de renv para evitar problemas con el entorno virtual
RUN rm -rf /build_zone/renv /build_zone/renv.lock

# Exponer el puerto de Shiny
EXPOSE 3839

# Comando final para ejecutar la aplicación
CMD R -e "options('shiny.port'=3839, shiny.host='0.0.0.0'); shiny::runApp(system.file('gobmx-shapes-app', package = 'gobmx.shapes'))"