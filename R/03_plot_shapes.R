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

      loadCSS('maplibre-gl.css');
      loadScript('maplibre-gl.js', function() {
        loadScript('leaflet-maplibre-gl.js', function() {
          L.maplibreGL({
            style: 'https://www.mapabase.atdt.gob.mx/style_white_places.json'
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
      fillOpacity = 1,
      clusterOptions = leaflet::markerClusterOptions(
        iconCreateFunction = htmlwidgets::JS(sprintf(
          "function(cluster) {
            var childCount = cluster.getChildCount();
            var color = '%s';

            function lightenColor(hex, factor) {
              var r = parseInt(hex.slice(1, 3), 16);
              var g = parseInt(hex.slice(3, 5), 16);
              var b = parseInt(hex.slice(5, 7), 16);
              r = Math.min(255, Math.floor(r + (255 - r) * factor));
              g = Math.min(255, Math.floor(g + (255 - g) * factor));
              b = Math.min(255, Math.floor(b + (255 - b) * factor));
              return 'rgb(' + r + ',' + g + ',' + b + ')';
            }

            var borderColor = lightenColor(color, 0.4);

            return new L.DivIcon({
              html: '<div style=\"' +
                'background-color:' + color + ';' +
                'border: 5px solid ' + borderColor + ';' +
                'border-radius: 50%%;' +
                'width: 40px; height: 40px;' +
                'display: flex; align-items: center; justify-content: center;' +
                'color: white; font-weight: bold;' +
                'font-size: 12px;' +
                '\">' + childCount + '</div>',
              className: 'marker-cluster',
              iconSize: new L.Point(40, 40)
            });
          }",
          opts$colors[1]
        ))
      )
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
