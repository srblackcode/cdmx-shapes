#' @export
plot_shapes <- function(shape_data, opts) {
  if (is.null(shape_data))
    return()

  shape_class <- class(shape_data)[1]

  base_map <- leaflet::leaflet(
    option = leaflet::leafletOptions(
      zoomSnap = 0.25,
      zoomDelta = 0.25,
      zoomControl = TRUE,
      minZoom = 5,
      maxZoom = 15
    )
  )

  base_map <- htmlwidgets::onRender(
    base_map,
    "function(el, x) {
      var map = this;

      function loadCSS(url) {
        var link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = url;
        document.head.appendChild(link);
      }

      function loadScript(url, callback) {
        var script = document.createElement('script');
        script.src = url;
        script.onload = callback;
        document.head.appendChild(script);
      }

      loadCSS('https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css');
      loadScript('https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js', function() {
        loadScript('https://unpkg.com/@maplibre/maplibre-gl-leaflet@0.0.20/leaflet-maplibre-gl.js', function() {
          L.maplibreGL({
            style: 'https://www.mapabase.atdt.gob.mx/style.json'
          }).addTo(map);
          map.attributionControl.addAttribution(
            '&copy; <a href=\"https://www.gob.mx/atdt\" target=\"_blank\">ATDT</a> | ' +
            '<a href=\"https://www.inegi.org.mx/\" target=\"_blank\">INEGI</a> | ' +
            '<a href=\"https://www.openstreetmap.org/\" target=\"_blank\">OSM</a>'
          );
        });
      });
    }"
  )

  lf <- leaflet::addTopoJSON(
    base_map,
    topojson = mayorsGobmx,
    weight = 0,
    opacity = 0,
    fillColor = "transparent",
    color = "transparent"
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
      #stroke <- TRUE
      fill_opacity <- 0.3
      fill_color <- opts$colors[1]
      color <- "transparent"
    } else {
      pal <- leaflet::colorNumeric(
        rev(opts$colors),
        domain = as.numeric(shape_data[[opts$var_num]])
      )
      fill_color <- pal(as.numeric(shape_data@data[[opts$var_num]]))
      color <- "transparent"
    }

    lf <- leaflet::addLegend(
      leaflet::addPolygons(
        lf,
        data = shape_data,
        label = ~labels,
        stroke = FALSE,
        weight = 0,
        opacity = 0,
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
