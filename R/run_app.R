#' @export
run_app <- function(){
    app_file <- system.file("cdmx-shapes-app/app.R", package = "cdmx.shapes")
  shiny::runApp(app_file, port = 3838)
}

#' @export
run_app_ciudadano <- function(){
    app_file <- system.file("cdmx-shapes-app-high/", package = "cdmx.shapes")
    shiny::runApp(app_file, port = 3838)
}
