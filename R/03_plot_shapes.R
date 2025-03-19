#' @export
plot_shapes <- function(shape_data, opts) {
  if (is.null(shape_data))
    return()

  shape_class <- class(shape_data)[1]

  lf <- leaflet::addTopoJSON(
    leaflet::addTiles(
      leaflet::leaflet(
        option = leaflet::leafletOptions(
          zoomSnap = 0.25,
          zoomDelta = 0.25,
          zoomControl = TRUE,
          minZoom = 5,    # Puedes ajustar si deseas permitir acercamientos específicos
          maxZoom = 15
        )
      ),
      urlTemplate = "https://maps.geoapify.com/v1/tile/positron/{z}/{x}/{y}.png?&apiKey=f39345000acd4188aae1f2f4eed3ff14",
      attribution = "positron"
    ),
    topojson = mayorsCdmx,
    weight = 0.5,
    opacity = 0.8,
    fillColor = "transparent",
    color = "#000000"
  )

  if (shape_class == "SpatialLinesDataFrame") {
    lf <- leaflet::addPolylines(
      lf,
      data = shape_data,
      label = ~labels,
      color = opts$colors,
      fillOpacity = 1,
      weight = 3
    )
  }

  if (shape_class == "SpatialPointsDataFrame") {
    lf <- leaflet::addCircleMarkers(
      lf,
      data = shape_data,
      label = ~labels,
      color = opts$colors,
      radius = 3,
      fillOpacity = 1
    )
  }

  if (shape_class == "SpatialPolygonsDataFrame") {
    fill_opacity <- 0.5
    stroke <- FALSE

    if (is.null(opts$data)) {
      stroke <- TRUE
      fill_opacity <- 0.3
      fill_color <- opts$colors[1]
      color <- fill_color
    } else {
      pal <- leaflet::colorNumeric(
        rev(opts$colors),
        domain = as.numeric(shape_data[[opts$var_num]])
      )
      fill_color <- pal(as.numeric(shape_data@data[[opts$var_num]]))
      color <- opts$colors[1]
    }

    lf <- leaflet::addLegend(
      leaflet::addPolygons(
        lf,
        data = shape_data,
        label = ~labels,
        stroke = TRUE,
        weight = 0.3,
        opacity = 1,
        fillOpacity = fill_opacity,
        smoothFactor = 0,
        color = color,
        fillColor = fill_color
      ),
      pal = pal,
      values = as.numeric(shape_data@data[[opts$var_num]]),
      opacity = 0.7,
      title = NULL,
      position = "topright"
    )
  }

  # Ajusta los valores de lat, lng y zoom para centrar en México
  lf <- leaflet::setView(lf, lng = -102, lat = 23, zoom = 5)

  lf
}
