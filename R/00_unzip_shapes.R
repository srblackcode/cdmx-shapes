unzip_shape <- function(url, export_dir) {
  is_csv <- grepl("\\.csv$", url, ignore.case = TRUE)
  ext <- if (is_csv) "csv" else "zip"
  file_destiny <- paste0(tempdir(check = TRUE), "/shape_file.", ext)

  # Intentar descargar con download.file
  success <- tryCatch({
    download.file(url, destfile = file_destiny, method = "curl", mode = "wb", timeout = 3600)
    TRUE
  }, error = function(e) {
    message("Error con `download.file()`, intentando con `wget`...")
    system(paste0("wget -O ", file_destiny, " --timeout=3600 ", url))
    file.exists(file_destiny)
  })

  # Si la descarga falló, detener ejecución
  if (!success || !file.exists(file_destiny) || file.info(file_destiny)$size == 0) {
    stop("Error: No se pudo descargar el archivo o el archivo está vacío.")
  }

  # Manejo de CSV
  if (is_csv) {
    dir.create(export_dir, showWarnings = FALSE, recursive = TRUE)
    csv_name <- basename(url)
    csv_dest <- file.path(export_dir, csv_name)
    file.copy(file_destiny, csv_dest, overwrite = TRUE)
    return(list(
      shape_file = csv_dest,
      shape_dsn  = "csv",
      shape_layer = tools::file_path_sans_ext(csv_name)
    ))
  }

  # Intentar descomprimir el archivo ZIP
  unzip_status <- tryCatch({
    unzip(zipfile = file_destiny, exdir = export_dir)
    TRUE
  }, error = function(e) {
    message("Error al descomprimir el archivo ZIP: ", e$message)
    FALSE
  })

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

  list(
    shape_file = export_dir,
    shape_dsn  = shape_dsn,
    shape_layer = shape_layer
  )
}