#' @export
fringe_data <- function(shape_data) {
  if (is.null(shape_data)) return()
  dic <- homodatum::create_dic(shape_data)
  list(
    data = shape_data,
    dic = dic
  )
}
