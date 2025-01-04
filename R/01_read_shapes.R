#' @export
read_shape <- function(shape_dsn, shape_layer, shape_file) {
  shape_data <- rgdal::readOGR(
    dsn = paste0(shape_file, "/", shape_dsn),
    layer = shape_layer,
    verbose=FALSE
  )
  shape_data <- sp::spTransform(shape_data, sp:::CRS("+init=epsg:4326"))
  shape_data
}
