#' @export
read_shape <- function(shape_dsn, shape_layer, shape_file) {

  if (!is.null(shape_dsn) && shape_dsn == "csv") {
    data <- read.csv(shape_file, stringsAsFactors = FALSE)

    lat_col <- grep("^lat(itud)?$", names(data), ignore.case = TRUE, value = TRUE)[1]
    lon_col <- grep("^lon(gitud)?$|^lng$", names(data), ignore.case = TRUE, value = TRUE)[1]

    if (is.na(lat_col) || is.na(lon_col)) {
      stop("No se encontraron columnas de latitud/longitud en el CSV.")
    }

    data[[lon_col]] <- as.numeric(data[[lon_col]])
    data[[lat_col]] <- as.numeric(data[[lat_col]])
    data <- data[!is.na(data[[lon_col]]) & !is.na(data[[lat_col]]), ]

    return(sp::SpatialPointsDataFrame(
      coords = data[, c(lon_col, lat_col)],
      data   = data,
      proj4string = sp::CRS("+proj=longlat +datum=WGS84 +no_defs")
    ))
  }

  shape_data <- rgdal::readOGR(
    dsn = paste0(shape_file, "/", shape_dsn),
    layer = shape_layer,
    verbose = FALSE
  )
  shape_data <- sp::spTransform(
    shape_data,
    sp::CRS("+proj=longlat +datum=WGS84 +no_defs")
  )
  shape_data
}
