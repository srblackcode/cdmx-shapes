#' @export
run_app <- function(){
    app_file <- system.file("gobmx-shapes-app/app.R", package = "gobmx.shapes")
  shiny::runApp(app_file, port = 3838)
}

# #' @export
# run_app_ciudadano <- function(){
#     app_file <- system.file("gobmx-shapes-app-high/", package = "gobmx.shapes")
#     shiny::runApp(app_file, port = 3838)
# }
