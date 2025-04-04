read_ckan_info <- function(url, linkInfo) {
  generalUrl <- paste0(url, "resource_show?id=")
  print(generalUrl)
  linkInfo <- paste0(generalUrl, linkInfo)
  listConf <- jsonlite::fromJSON(linkInfo)
  listConf$result
}

read_ckan_dic <- function(url, idDic) {
  if (is.null(url)) return()
  if (is.null(idDic)) return()
  dicUrl <- paste0(url, "package_show?id=", idDic)
  listDic <- jsonlite::fromJSON(dicUrl)
  listAll <-
    purrr::map(seq_along(listDic), function(i) {
      if (!"resources" %in% names(listDic[[i]])) return()
      listDic[[i]]
    }) |>
    purrr::discard(is.null)
  listAll <- listAll[[1]]


  listDic <- listAll$resources

  listUrl <- listDic |> dplyr::select(name, format, url)
  url_dic <- listUrl |> dplyr::filter(name == "Diccionario de datos")
  dic <- NULL
  if (nrow(url_dic) > 0) {
    if (url_dic$format == "XLSX") {
      dic <- rio::import(url_dic$url)
    } else {
      dic <- readr::read_csv(url_dic$url)
    }
  }
  listUrl$format <- gsub("\\.", "",tolower(listUrl$format))

  listDic <- list(
    dic = dic,
    listCaptions = list(label = listAll$organization$title, id = listAll$organization$name),
    listLicense = list(id = listAll$license_id, title = listAll$license_title, url = listAll$license_url),
    listResources = listUrl
  )
  listDic
}

labels_map <- function (nms) {
  label_ftype <- nms
  names_fype <- names(nms)
  tooltip <- paste0(
    purrr::map(seq_along(label_ftype), function(i) {
      paste0(names(label_ftype[i]), ": {", label_ftype[i], "}")
    }) |> unlist(), collapse = "<br/>")
  tooltip
}


colores_shape <- function(class_shape) {

  if (class_shape %in% c("SpatialLinesDataFrame", "SpatialPointsDataFrame")) {
    cd <-   list(
      palette_c = c("#095F68"),
      palette_a = c("#262699"),
      palette_b = c("#0559D3"),
      palette_d = c("#05875E"),
      palette_e = c("#F9AE06"),
      palette_f = c("#EA1B1B")
    )
  }

  if (class_shape == "SpatialPolygonsDataFrame") {
    cd <- list(
      palette_c = c("#095F68", "#0A7F94", "#18A6AD", "#3FC4C4", "#6BD1CF", "#9BDDDA"),
      palette_a = c("#262699", "#3D3DE2", "#5454FC", "#6D6DFC", "#8D8DFC", "#A9A9FC"),
      palette_b = c("#0559D3", "#166EFA", "#438BFF", "#69A2FF", "#8AB7FF", "#B0CEFF"),
      palette_d = c("#05875E", "#16B584", "#3EC695", "#6AD3AD", "#9BE0C4", "#D1F2E1"),
      palette_e = c("#F9AE06", "#FFCE00", "#FFE966", "#FFEB99", "#FFF5CC", "#FEF7E6"),
      palette_f = c("#EA1B1B", "#FA4D56", "#FF6666", "#FFC0CC", "#FFD9E2", "#FFEBF1")
    )
  }

  cd

}


colors_print <- function(palette_colors) {
  cd <- palette_colors
  lc <- purrr::map(names(cd), function(palette) {
    colors <- cd[[palette]]
    as.character( div(
      purrr::map(colors, function(color) {
        div(style=paste0("width: 24px; height: 12px; display: inline-block; background-color:", color, ";"))
      })
    ))
  })
  names(lc) <- names(cd)
  lc
}


menu_buttons <- function(ids = NULL, labels = NULL, ...) {
  if (is.null(ids)) stop("Please enter identifiers for each question")
  if (is.null(labels)) stop("Please enter labels for each question")

  df <- data.frame(id = ids, questions = labels)
  l <- purrr::map(1:nrow(df), function(z){
    shiny::actionButton(inputId = df[z,]$id, label = df[z,]$questions, class = "needed")
  })
  l[[1]] <- gsub("needed", "needed basic_active", l[[1]])
  l[[1]] <- htmltools::HTML(paste0(paste(l[[1]], collapse = '')))

  l
}


download_viz <- function (params, file, ext, template_file) {

  file.copy("template.Rmd", template_file, overwrite = TRUE)

  if (ext == ".html") {
    rmarkdown::render(template_file, output_file = file,
                      params = params,
                      envir = new.env(parent = globalenv())
    )
  } else {
    saveFile <- paste0(tempdir(), "/report.html")
    rmarkdown::render(template_file, output_file = saveFile,
                      params = params,
                      envir = new.env(parent = globalenv())
    )
    screenFile <-  paste0(tempdir(), "/screen", ext)
    print(screenFile)
    webshot2::webshot(url = saveFile, file = screenFile, delay = 15)
    file.copy(screenFile, file)
  }

}


