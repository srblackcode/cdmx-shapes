FROM --platform=linux/amd64 rocker/r-ver:4.2
RUN apt-get update && apt-get install -y ca-certificates lsb-release wget && rm -rf /var/lib/apt/lists/*
RUN wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
RUN wget https://downloads.vivaldi.com/stable/vivaldi-stable_5.5.2805.35-1_amd64.deb
RUN apt-get update && apt-get install -y ./vivaldi-stable_5.5.2805.35-1_amd64.deb && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && rm -rf /var/lib/apt/lists/*
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
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN echo  GITHUB_PAT=${GITHUB_PAT} > .Renviron
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("rgdal",upgrade="never", version = "1.6-7")'
RUN Rscript -e 'remotes::install_version("sp",upgrade="never", version = "2.0")'
RUN Rscript -e 'remotes::install_version("sf",upgrade="never", version = "1.0-13")'
RUN Rscript -e 'remotes::install_version("stringi",upgrade="never", version = "1.7.12")'
RUN Rscript -e 'remotes::install_version("stringr",upgrade="never", version = "1.5.0")'
RUN Rscript -e 'remotes::install_version("shiny",upgrade="never", version = "1.7.4")'
RUN Rscript -e 'remotes::install_version("jsonlite",upgrade="never", version = "1.8.7")'
RUN Rscript -e 'remotes::install_version("purrr",upgrade="never", version = "1.0.1")'
RUN Rscript -e 'remotes::install_version("readr",upgrade="never", version = "2.1.4")'
RUN Rscript -e 'remotes::install_version("dplyr",upgrade="never", version = "1.1.2")'
RUN Rscript -e 'remotes::install_version("tidyr",upgrade="never", version = "1.3.0")'
RUN Rscript -e 'remotes::install_version("shinyjs",upgrade="never", version = "2.1.0")'
RUN Rscript -e 'remotes::install_version("leaflet",upgrade="never", version = "2.1.2")'
RUN Rscript -e 'remotes::install_version("config",upgrade="never", version = "0.3.1")'
RUN Rscript -e 'remotes::install_version("testthat",upgrade="never", version = "3.1.8")'
RUN Rscript -e 'remotes::install_version("spelling",upgrade="never", version = "2.2")'
RUN Rscript -e 'remotes::install_version("fs")'
RUN Rscript -e 'remotes::install_version("webshot2",upgrade="never", version = "0.1.0")'
RUN Rscript -e 'remotes::install_version("shinycustomloader",upgrade="never", version = "0.9.0")'
RUN Rscript -e 'remotes::install_version("shinybusy",upgrade="never", version = "0.3.1")'
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_github("datasketch/dstools", dependencies=TRUE)'
RUN Rscript -e 'remotes::install_github("CamilaAchuri/shinypanels@eeec45b196c99a91ae8033e95b0d52363ff1abc2")'
RUN Rscript -e 'remotes::install_github("datasketch/shinyinvoer@dd8178db99cac78f0abbd236e83e07bf1f22ba18")'
RUN Rscript -e 'remotes::install_github("datasketch/parmesan@d361f2047a6bb366a0adc271f0e264b62bd1e6e8")'
RUN Rscript -e 'remotes::install_version("markdown", upgrade="never", version = "1.2")'
RUN Rscript -e 'remotes::install_github("rstudio/chromote@e1d2997932671642d12bef0b4c58611e322035c7")'
RUN Rscript -e 'remotes::install_github("dreamRs/d3.format", dependencies=TRUE)'
RUN Rscript -e 'remotes::install_github("datasketch/homodatum", dependencies=TRUE)'
RUN Rscript -e 'remotes::install_version("DT")'
RUN Rscript -e 'remotes::install_github("datasketch/dsmodules@5e9a9860ae27aad2cbecf3492be5e")'
RUN Rscript -e 'remotes::install_github("datasketch/cdmx-shapes")'


ARG CKAN_URL
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone
RUN chmod -R 755 /build_zone
RUN rm -rf /build_zone
RUN echo ckanUrl=${CKAN_URL} > .Renviron
RUN echo CHROMOTE_CHROME=/usr/bin/vivaldi >> .Renviron
USER root
EXPOSE 3838

CMD R -e "options('shiny.port'=3838,shiny.host='0.0.0.0'); cdmx.shapes:::run_app_ciudadano()"
