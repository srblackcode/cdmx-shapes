# gobmx.shapes — Visor de Shapefiles

Aplicación Shiny que descarga, procesa y visualiza recursos geoespaciales (Shapefiles, GeoJSON, ZIP) desde el portal CKAN de [datos.gob.mx](https://www.datos.gob.mx) a través de mapas Leaflet interactivos.

---

## Índice

1. [Requisitos](#requisitos)
2. [Variables de entorno](#variables-de-entorno)
3. [Librería local de paquetes (`site-library`)](#librería-local-de-paquetes-site-library)
4. [Correr el proyecto en desarrollo](#correr-el-proyecto-en-desarrollo)
5. [Imagen Docker para producción](#imagen-docker-para-producción)
6. [Estructura del proyecto](#estructura-del-proyecto)
7. [Notas importantes](#notas-importantes)

---

## Requisitos

| Herramienta | Versión mínima |
|---|---|
| R | 4.2 |
| Docker | cualquier versión moderna |
| Chromium / Chrome / Vivaldi | para captura de visualizaciones con `webshot2` |

---

## Variables de entorno

La app busca el archivo `.Renviron` en dos ubicaciones según el contexto:

| Prioridad | Ruta | Contexto |
|---|---|---|
| 1 | `~/.Renviron` | Desarrollo local |
| 2 | `/build_zone/.Renviron` | Producción (Docker) |

> **Nota:** A diferencia del proyecto `cdmxApp`, en este repositorio el `.Renviron` está **comentado** en el `.gitignore`, por lo que el archivo sí se rastrea en git. Contiene únicamente la URL pública de la API, sin credenciales.

Contenido actual del `.Renviron`:

```bash
ckanUrl=https://www.datos.gob.mx/api/3/action/
CHROMOTE_CHROME=/usr/bin/vivaldi
```

### Descripción de cada variable

| Variable | Descripción | Ejemplo |
|---|---|---|
| `ckanUrl` | URL base de la API CKAN del portal de datos | `https://www.datos.gob.mx/api/3/action/` |
| `CHROMOTE_CHROME` | Ruta al binario de Chrome/Chromium/Vivaldi para capturas con `webshot2` | `/usr/bin/google-chrome` |

> En el entorno de desarrollo se usó Vivaldi. En Docker la imagen instala Google Chrome y lo establece con `ENV CHROMOTE_CHROME="/usr/bin/google-chrome"`, sobrescribiendo lo del `.Renviron`.

---

## Librería local de paquetes (`site-library`)

### ¿Qué es?

El directorio `site-library/` (~496 MB) contiene **todos los paquetes de R precompilados** para Ubuntu 20.04 (Focal) + R 4.2. El Dockerfile los copia directamente a `/usr/local/lib/R/site-library` para evitar compilar desde cero.

### ¿Por qué existe?

Algunos paquetes del proyecto no están en CRAN (p. ej. `dsmodules`, `shinypanels`, `shinyinvoer` del org `datasketch`). Precompilarlos evita necesitar tokens de GitHub dentro del Dockerfile.

### En desarrollo local

En desarrollo `renv` maneja el entorno virtual en `renv/library/`. Para restaurarlo:

```r
renv::restore()
```

### `site-library/` está en `.gitignore`

No se sube al repositorio por su tamaño. Debe transferirse al servidor por medios alternativos (scp, GCS, NFS, etc.) antes de construir la imagen Docker.

```bash
# Comprimir para transferir
zip -r site-library.zip site-library/
```

---

## Correr el proyecto en desarrollo

### 1. Restaurar el entorno

```r
renv::restore()
```

### 2. Instalar el paquete

```r
devtools::install()
```

### 3. Levantar la app

```r
# Opción A — función exportada del paquete
gobmx.shapes::run_app()

# Opción B — apuntando directamente al directorio de la app
shiny::runApp(system.file('gobmx-shapes-app', package = 'gobmx.shapes'))
```

La app corre en el puerto **3838** por defecto.

> Durante la sesión, la app descarga shapefiles al directorio temporal `inst/gobmx-shapes-app/down_shapes/`. Este directorio está en `.gitignore` y se limpia en cada nueva carga de datos.

---

## Imagen Docker para producción

### Prerrequisitos

`site-library/` debe existir en la raíz del proyecto antes de construir.

### Construir la imagen

El nombre de la imagen sigue la convención del Artifact Registry de Google Cloud:

```bash
docker build . -t us-central1-docker.pkg.dev/artifact-registry-gob-mx/datos-abiertos/visualizador-shapes:master_$(date +%d%m%y%H%M%S%s)
```

El tag incluye fecha y hora para identificar cada build. Ejemplo de tag real:

```
visualizador-shapes:master_2904251441141745959274
```

### Correr el contenedor

```bash
docker run -d \
  --name gobmx-shapes \
  -p 3839:3839 \
  us-central1-docker.pkg.dev/artifact-registry-gob-mx/datos-abiertos/visualizador-shapes:master_XXXXXX
```

La app queda disponible en `http://localhost:3839`.

> **Nota de puertos:** El Dockerfile expone el puerto **3839** (distinto al `3838` del proyecto `cdmxApp`). Asegúrate de no tener conflicto si ambos contenedores corren en el mismo host.

### Diferencias clave respecto a `cdmxApp`

| Aspecto | `cdmxApp` | `cdmx-shapes` |
|---|---|---|
| Puerto | 3838 | 3839 |
| Inicio | `shiny::runApp('/build_zone', ...)` | `shiny::runApp(system.file(...))` |
| Instalación del pkg | No (ya compilado en site-library) | Sí — `R CMD INSTALL /build_zone` en el build |
| Browser para capturas | phantomjs (descargado de Bitbucket) | Google Chrome (instalado vía apt) |
| `renv` eliminado | Sí | Sí (también elimina `.Rprofile`) |

### Detalles del Dockerfile

| Aspecto | Detalle |
|---|---|
| Imagen base | `rocker/r-ver:4.2` (Ubuntu 20.04 Focal) |
| Puerto expuesto | `3839` |
| Paquetes R | Copiados desde `site-library/` |
| Paquete propio | Se instala con `R CMD INSTALL --no-multiarch` durante el build |
| Browser | Vivaldi + Google Chrome instalados; se usa Chrome (`CHROMOTE_CHROME`) |
| Apache Arrow | Instalado desde repositorio oficial de Apache |
| `renv` + `.Rprofile` | Eliminados para evitar activación del entorno virtual |
| Comando de inicio | `R -e "options('shiny.port'=3839, shiny.host='0.0.0.0'); shiny::runApp(...)"` |

---

## Estructura del proyecto

```
cdmx-shapes/
├── .Renviron                          # Variables de entorno (SÍ en git — solo URL pública)
├── Dockerfile                         # Imagen de producción
├── DESCRIPTION                        # Metadatos del paquete R (nombre: gobmx.shapes)
├── renv/                              # Entorno virtual para desarrollo
├── renv.lock                          # Versiones exactas de paquetes para dev
├── site-library/                      # Paquetes precompilados para Docker (NO en git, ~496 MB)
├── R/
│   ├── run_app.R                      # Función run_app() exportada (puerto 3838)
│   ├── 00_unzip_shapes.R              # Descarga y descomprime shapefiles desde CKAN
│   ├── 01_read_shapes.R               # Lectura de capas del shapefile (rgdal/sp)
│   ├── 02_fringe_data.R               # Procesamiento y diccionario de variables
│   ├── 03_plot_shapes.R               # Renderizado del mapa Leaflet
│   └── compat-utils.R                 # Utilidades de compatibilidad
├── inst/
│   └── gobmx-shapes-app/
│       ├── app.R                      # App Shiny completa (UI + Server)
│       ├── down_shapes/               # Directorio temporal de shapefiles (NO en git)
│       ├── markdown/template.Rmd      # Template para exportar visualizaciones
│       └── www/                       # Assets estáticos (CSS, JS, imágenes)
├── data/
│   ├── mayorsCdmx.rda                 # Alcaldías de CDMX
│   └── mayorsGobmx.rda                # Alcaldías nacionales
└── data-raw/
    ├── data.R                         # Script de preparación de datos
    └── layers/
        ├── cdmx-mayors.topojson       # TopoJSON de alcaldías CDMX
        └── mx-mayors.topojson         # TopoJSON de alcaldías México
```

---

## Notas importantes

### Directorio `down_shapes/`

Al cargar un recurso, la app descarga el shapefile/ZIP de CKAN y lo extrae en `inst/gobmx-shapes-app/down_shapes/`. Esta carpeta:

- Se limpia con `unlink("down_shapes/", recursive = TRUE)` en cada nueva carga
- Está en `.gitignore`
- En Docker reside dentro de `/build_zone/inst/gobmx-shapes-app/down_shapes/` — el contenedor necesita permisos de escritura ahí

### App de alta resolución (`gobmx-shapes-app-high`)

Existe un segundo directorio `inst/gobmx-shapes-app-high/` con una variante de la app. La función `run_app_ciudadano()` en `run_app.R` está comentada — no se usa en producción actualmente.

### Parámetro CKAN por defecto

Si no se recibe un `ckanConf` por URL, la app usa el recurso:

```
4d6f570f-f2fc-45e5-af32-08f42a46265b  # url_par default
eb20bbe2-cb43-4db2-8129-3feed446df68  # fallback en shape_info
```
