unzip_shape <- function(url, export_dir) {
  file_destiny <- paste0(tempdir(check = TRUE), "/shape_file.zip")

  # Intentar descargar con download.file
  success <- tryCatch({
    download.file(url, destfile = file_destiny, method = "curl", mode = "wb", timeout = 3600)
    TRUE
  }, error = function(e) {
    message("Error con `download.file()`, intentando con `wget`...")
    system(paste0("wget -O ", file_destiny, " --timeout=3600 ", url))
    file.exists(file_destiny)  # Verifica si el archivo se descargó
  })

  # Si la descarga falló, detener ejecución
  if (!success || !file.exists(file_destiny) || file.info(file_destiny)$size == 0) {
    stop("Error: No se pudo descargar el archivo o el archivo está vacío.")
  }

  # Verificar que el archivo es un ZIP válido
  if (!grepl("\\.zip$", file_destiny) || !file.exists(file_destiny)) {
    stop("Error: Archivo descargado no es un ZIP válido.")
  }

  # Intentar descomprimir el archivo
  unzip_status <- tryCatch({
    unzip(zipfile = file_destiny, exdir = export_dir)
    TRUE
  }, error = function(e) {
    message("Error al descomprimir el archivo ZIP: ", e$message)
    FALSE
  })

  # Si la extracción falló, detener la ejecución
  if (!unzip_status) {
    stop("Error: No se pudo extraer el archivo ZIP.")
  }

  # Obtener información de los archivos extraídos
  folder_info <- fs::dir_ls(path = export_dir, type = "file", recurse = TRUE)
  shape_info <- unlist(stringr::str_split(folder_info, pattern = "/")) |> setdiff(export_dir)

  # Determinar el DSN del shape file
  shape_dsn <- shape_info[1]
  try_dsn <- substring(shape_dsn, regexpr("\\.([[:alnum:]]+)$", shape_dsn) + 1L)

  if (shape_dsn == try_dsn) {
    shape_info <- shape_info[-1]
  } else {
    shape_dsn <- NULL
  }

  # Extraer la capa del archivo shape
  ext <- substring(shape_info, regexpr("\\.([[:alnum:]]+)$", shape_info) + 1L)
  shape_layer <- unique(gsub(paste0(".", ext, collapse = "|"), "", shape_info)) |> setdiff("license")

  # Retornar información del shape file
  list(
    shape_file = export_dir,
    shape_dsn = shape_dsn,
    shape_layer = shape_layer
  )
}