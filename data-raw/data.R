## code to prepare `data` dataset goes here
mayorsGobmx <- readLines("data-raw/layers/mx-mayors.topojson")
usethis::use_data(mayorsGobmx, overwrite = TRUE)
