## code to prepare `data` dataset goes here
mayorsCdmx <- readLines("data-raw/layers/cdmx-mayors.topojson")
usethis::use_data(mayorsCdmx, overwrite = TRUE)
