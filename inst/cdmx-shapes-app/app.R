library(cdmx.shapes)
library(dsmodules)
library(leaflet)
library(shiny)
library(shinybusy)
library(shinypanels)
library(tidyr)
library(webshot2)

ui <- panelsPage(
  includeCSS("www/custom.css"),
  tags$head(tags$script(src="handlers.js")),
  shinybusy::busy_start_up(
    loader = tags$img(
      src = "img/loading_gris.gif",
      width = 100),
    mode = "auto",
    color = "#435b69",
    background = "#FFF"),
  shinypanels::modal(id = 'modal_download',
                     title = " ",
                     fullscreen = TRUE,
                     id_title = "down-title",
                     id_content = "tab-content-modal",
                     id_wrapper = "tab-modal-down",
                     div( div(class = "tab-head-modal",
                              uiOutput("menu_modal")),
                          div(class = "tab-body-modal",
                              uiOutput("down_index")))
  ),
  shinypanels::modal(id = 'modal_viz_info', title = "Descripción", uiOutput("info_plots"), id_wrapper = "des_mod"),
  shinypanels::modal(id = 'modal_dic_info', title = "Diccionario", uiOutput("infoDics"), id_wrapper = "dic_mod"),
  shinypanels::modal(id = 'modal_rec_info', title = "Recursos", uiOutput("info_recs"), id_wrapper = "rec_mod"),

  panel(title = " ",
        id = "azul",
        can_collapse = FALSE,
        width = 350,
        body =  div(
          div(class = "title-div-filters", "OPCIONES MAPA"),
          uiOutput("layers"),
          uiOutput("numeric_ui"),
          uiOutput("label_opts"),
          div(class = "title-div-filters", "AJUSTES ESTÉTICOS"),
          uiOutput("colors")
        ),
        footer =  tags$a(
          href="https://www.datasketch.co", target="blank",
          img(src= 'img/ds_logo.svg',
              align = "left", width = 130, height = 70))
  ),
  panel(title = " ",
        id = "naranja",
        can_collapse = FALSE,
        header_right = div(style = "display: flex;align-items: center;",
                           # uiOutput("viz_icons"),
                           p(class = "app-version","Versión Beta"),
                           div(class = 'inter-container', style = "margin-right: 3%; margin-left: 3%;",
                               actionButton(inputId ='fs', "Fullscreen", onclick = "gopenFullscreen();")
                           ),
                           div(class='second-container',
                               actionButton("descargas", "Descargas", icon = icon("download"), width = "150px")
                           )
        ),
        body =  div(
          # verbatimTextOutput("debug"),
          leafletOutput("map_shape", height = 620),
          div(style="display: flex;justify-content: space-between;",
              uiOutput("fuente"),
              uiOutput("logos_add")
          )
        ),
        footer =
          div(style = "display:flex;align-items: center;background: #F7F7F7;justify-content: space-between;",
              uiOutput("summaryInfo"),
              uiOutput("infoButt")
          )
  )
)


server <- function(input, output, session) {


  # global info -------------------------------------------------------------

  readRenviron(".Renviron")
  url_info <- Sys.getenv("ckanUrl")

  par <- list(ckanConf = NULL)

  url_par <- reactive({
    shinyinvoer::url_params(par, session)
  })


  # read ckan info ----------------------------------------------------------

  info_url <- reactive({
    print(url_info)
    linkInfo <- url_par()$inputs$ckanConf
    if (is.null(linkInfo)) linkInfo <-"0d0a2598-4f0e-4bcd-a667-85be655a93a6"#"6e541083-1399-4c14-a210-0493167c7b16"#"0d0a2598-4f0e-4bcd-a667-85be655a93a6"#"7c6ea52c-8395-4ec9-82a9-96099a6fe6bc"#"eb20bbe2-cb43-4db2-8129-3feed446df68"#"611136b5-5891-4764-a4cd-c12a5109770f"#"ce383321-92de-4a13-8234-7756b520ee4e"
    cdmx.shapes:::read_ckan_info(url = url_info, linkInfo = linkInfo)
  })


  dic_ckan <- reactive({
    req(info_url())
    cdmx.shapes:::read_ckan_dic(url = url_info, info_url()$package_id)
  })

  # read url from ckan ------------------------------------------------------

  shape_info <- reactive({
    req(info_url())
    url_shape <- info_url()$url
    unlink("down_shapes/", recursive = TRUE)
    #url_shape <- "https://datos-prueba.cdmx.gob.mx/dataset/05d66891-33f9-405c-b6a3-f29aff791c1c/resource/ce383321-92de-4a13-8234-7756b520ee4e/download/ingreso_promedio_trimestral.zip"
    unzip_shape(url = url_shape, export_dir = "down_shapes")
  })


  # show layers to plot -----------------------------------------------------

  output$layers <- renderUI({
    req(shape_info)
    radioButtons("layer_id",
                 "Capa a visualizar",
                 shape_info()$shape_layer,
                 selected = shape_info()$shape_layer[1])
  })


  dic_to_labels <- reactive({
    req(dic_ckan())
    dic_ckan()$dic
  })

  # read shape --------------------------------------------------------------

  shape_load <- reactive({
    req(shape_info())
    shape_layer <- input$layer_id
    if (is.null(shape_layer)) shape_layer <- shape_info()$shape_layer[1]
    suppressWarnings(
      shape <- read_shape(shape_dsn = shape_info()$shape_dsn,
                          shape_layer = shape_layer,
                          shape_file = shape_info()$shape_file)
    )
    shape
  })



  # read data from shape ----------------------------------------------------

  shape_fringe <- reactive({
    req(shape_load())
    cdmx.shapes::fringe_data(shape_load()@data)
  })

  var_num <- reactive({
    req(info_url())
    if (is.null(info_url()$resource_viz)) return()
    var <- strsplit(info_url()$resource_viz, split = ",") |>
      unlist()
    var <- setdiff(var, c(NA, ""))
    if (identical(var, character()) | identical(var, logical())) var <- NULL

    var
  })

  # variables numericas a graficar
  numeric_var <- reactive({
    req(shape_fringe())
    if (nrow(shape_fringe()$data) < 2) return()
    if (class(shape_load())[1] == "SpatialPointsDataFrame") return()
    var_num <- var_num()
    if (is.null(var_num)) {
      dic <- shape_fringe()$dic
      if (nrow(dic) == 0) return()
      dic$hdType[grepl("ano", dic$id)] <- "Yea"
      dic$hdType[grepl("id", dic$id)] <- "Uid"
      dic$hdType[grepl("cve_ent|c_ingrtrim", dic$id)] <- "___"

      dic <- dic |>
        dplyr::filter(hdType == "Num")
      if (nrow(dic) == 0) return()
      var_num <- dic$label
    }

    if (!is.null(dic_to_labels())) {
      dic <- dic_to_labels()
      dic <- dic |> dplyr::filter(Nombre %in% var_num)
      var_num <- setNames(dic$Nombre, dic$Etiqueta)
    }


    var_num
  })


  output$numeric_ui <- renderUI({
    req(numeric_var())
    selectizeInput("numeric_id", "Variable numerica", numeric_var())
  })


  var_to_label <- reactive({
    req(info_url())
    if (is.null(info_url()$resource_tooltip)) return()
    dic <- dic_to_labels()
    if (is.null(dic)) {
      dic <-  shape_fringe()$dic
      dic$id <- dic$label
    }
    names(dic)[1:2] <- c("id", "label")
    var <- strsplit(info_url()$resource_tooltip, split = ",") |>
      unlist()
    var <- setdiff(var, c(NA, ""))
    if (identical(var, character()) | identical(var, logical())) var <- NULL
    if (!is.null(var)) {
      var_dic <- grep(paste0(var, collapse = "|"), dic$id)
      if (identical(var_dic, integer())) var <- NULL
    }
    var
  })

  output$label_opts <- renderUI({
    req(shape_fringe())
    if (!is.null(var_to_label())) return()
    dic <- dic_to_labels()
    if (is.null(dic)) {
    dic <-  shape_fringe()$dic
    dic$id <- dic$label
    }
    names(dic)[1:2] <- c("id", "label")
    if (nrow(dic) == 0) return()
    checkboxGroupInput("label_id",
                       "Informacion del tooltip",
                       choices = setNames(dic$id, dic$label),
                       selected = dic$id)
  })

  palette_colors <- reactive({
    req(shape_load())
    pc <- cdmx.shapes:::colores_shape(class_shape = class(shape_load())[1])
    pc
  })


  output$colors <- renderUI({
    req(palette_colors())
    colores <- cdmx.shapes:::colors_print(palette_colors())
    shinyinvoer::radioButtonsInput("colors_id", label = "Colores", colores)
  })


  shape_to_plot <- reactive({
    req(shape_load())
    shape <- shape_load()
    label_id <- var_to_label()
    if (is.null(label_id)) label_id <- input$label_id
    if (!is.null(label_id)) {
      label_id <- intersect(label_id, names(shape@data))


      if (!identical(label_id, character())) {
        if (!is.null(dic_to_labels())) {
          dic_labs <- dic_to_labels() |> dplyr::filter(Nombre %in% label_id)
          if (nrow(dic_labs) > 0) {
            label_id <- setNames(dic_labs$Nombre, dic_labs$Etiqueta)
          }
        } else {
          label_id <- setNames(label_id, label_id)
        }

        shape@data <- shape@data |>
          dplyr::mutate(labels = glue::glue(
            cdmx.shapes:::labels_map(nms = label_id)) %>%
              lapply(htmltools::HTML)
          )
      }
    } else {
      shape@data$labels <- NA
    }
    shape
  })




  output$fuente <- renderUI({
    req(dic_ckan())
    url <- gsub("/api/3/action/", "",url_info)
    tags$a(href= paste0(url,"/organization/", dic_ckan()$listCaptions$id),
           paste0("Fuente: ", dic_ckan()$listCaptions$label), target="_blank")
  })

  output$logos_add <- renderUI({
    req(dic_ckan())
    if (is.null(dic_ckan()$listLicense$url)) {
      tx <- HTML(paste0("<span style='color:#3998A5;'>Licencia: </span>", dic_ckan()$listLicense$title))
    } else {
      tx <- HTML(paste0("<span style='color:#3998A5;'>Licencia: </span>", tags$a(
        href= dic_ckan()$listLicense$url, target="blank", dic_ckan()$listLicense$title)))
    }
    tx
  })

  map_down <- reactive({
    req(shape_to_plot())
    req(palette_colors())
    req(input$colors_id)
    data <- NULL
    if (!is.null(input$numeric_id)) data <- "si"
    opts <- list(
      data = data,
      colors = palette_colors()[[input$colors_id]],
      var_num = input$numeric_id
    )
    plot_shapes(shape_to_plot(), opts = opts)
  })

  output$map_shape <- renderLeaflet({
    req(map_down())
    map_down()
  })




  # downloads ---------------------------------------------------------------

  observeEvent(input$descargas, {
    shinypanels::showModal("modal_download")
  })

  output$menu_modal <- renderUI({
    cdmx.shapes:::menu_buttons(ids = c("datos_dw", "viz_dw", "api_dw"),
                               labels = c("Base de datos", "Gráfica", "API"))
  })


  params_markdown <- reactive({
    req(map_down())
    req(info_url())
    url <- gsub("/api/3/action/", "",url_info)
    list(viz = reactive(map_down()),
         title = gsub("\\*", "\\\\*",info_url()$name),
         subtitle = info_url()$resource_subtitle,
         fuentes =   paste0("<span style='font-weight:700;'>Fuente: </span>", dic_ckan()$listCaptions$label, "<br/>",
                            tags$a(href= paste0(url,"/dataset/", info_url()$package_id, "/resource/", info_url()$id),
                                   paste0(url,"/dataset/", info_url()$package_id), target="_blank"
                            )
         )
    )
  })

  list_api <- reactive({
    api <- data.frame(id = c("punto", "consulta", "js", "py", "r"),
                      label = c("Punto de acceso API &raquo;",
                                "Consultando &raquo;",
                                "Ejemplo: Javascript &raquo;",
                                "Ejemplo: Python &raquo;",
                                "Ejemplo: R &raquo;")
    )
    l <- purrr::map(1:nrow(api), function(z){
      actionButton(inputId = api[z,]$id, label = HTML(api[z,]$label), class = "apiClick")
    })
    l
  })

  observe({
    if (is.null(list_api)) return()
    l <- list_api()
    last_btn <- input$last_apiClick
    link_api <- url_par()$inputs$ckanConf
    if (!is.null(last_btn)) {
      button_id <- which(c("punto", "consulta", "js", "py", "r") %in% last_btn)
      df <- list(
        div(class='api-info',
            div(style='padding:10px 0px;margin-top: 20px;',
                "El API de Datos es accesible a través de las siguientes acciones de la API de acción de CKAN."
            ),
            HTML("
          <table id='table-punto-api'>
          <tr>
          <th>Consulta</th>
          <td><a id='link-modal' href='",url_info,"datastore_search' target='blank'>",url_info,"datastore_search</a></td>
          </tr>
          <tr>
          <th>Consulta (via SQL)</th>
          <td><a id='link-modal' href='",url_info,"datastore_search_sql' target='blank'>",url_info, "datastore_search_sql</a></td>
          </tr>
          </table>
          </div>"

            )),

        div(class='api-info',
            div(style='padding:10px 0px;margin-top: 20px;font-weight: 500;',
                "Ejemplo de consulta (primeros cinco resultados)"),
            HTML(paste0(
              "<a id='link-modal' href='",url_info,"datastore_search?resource_id=",
              link_api,"&limit=5' target='blank'>",url_info,"datastore_search?resource_id=",
              link_api,"&limit=5</a>"
            )),
            div(style='padding:10px 0px;margin-top: 10px;font-weight: 500;',
                "Ejemplo de consulta (resultados que contienen 'jones')"),
            HTML(paste0(
              "<a id='link-modal' href='",url_info,"datastore_search?resource_id=",
              link_api,"&q=jones' target='blank'>",url_info, "datastore_search?resource_id=",
              link_api,"&q=jones'</a>"
            )),
            div(style='padding:10px 0px;margin-top: 10px;font-weight: 500;',
                "Consulta ejemplo (vía SQL)"),
            HTML(paste0(
              "<a id='link-modal' href='",url_info,"datastore_search_sql?sql=SELECT * from ",
              link_api,"WHERE title LIKE 'jones'' target='blank'>",url_info,"datastore_search_sql?sql=SELECT * from ",
              link_api,"WHERE title LIKE 'jones'l</a>"
            ))
        ),

        div(class='api-info',
            div(style='padding:10px 0px;margin-top: 20px;', "Una consulta simple ajax (JSONP) a la data API usando jQuery."),
            div(
              HTML(paste0("
<pre> <code>
var data = {
resource_id: '", link_api,"' // the resource id
limit: 5, // get 5 results
q: 'jones' // query for 'jones'
};
$.ajax({
url: 'https://datos-ckandev.cdmx.gob.mx/api/3/action/datastore_search',
data: data,
dataType: 'jsonp',
success: function(data) {
alert('Total results found: ' + data.result.total)
}
});
</code></pre>
"
              ))
            )),
        div(class='api-info',
            div(
              HTML(paste0("
<pre><code>
import requests

url = '",url_info,"'

params = {
    'resource_id': '", link_api,"',
    'limit': 5,
    'q': 'jones'
    }

recurso = requests.get(url + 'datastore_search', params)
  </code>
</pre>"
              ))
            )),
        div(class='api-info',
            div(
              HTML(paste0('
<pre><code>
library(httr)
library(jsonlite)
library(tidyverse)

url <- "',url_info,'"
id <- "', link_api,'"

consulta <- paste0(url, "datastore_search?", "resource_id=", id, "&limit=5", "&q=jones")

request <- GET(consulta)
content <- rawToChar(request$content) %>%
      fromJSON()
datos <- content$result$records
  </code>
</pre>'
              ))
            ))
      )
      l[[button_id]] <- gsub("apiClick", "apiClick api_active", l[[button_id]])
      l[[button_id]] <- HTML(paste0(paste(l[[button_id]], collapse = '')))
      l[[button_id]] <- div(l[[button_id]],
                            df[[button_id]]
      )
      l
    }
    output$basicos <- renderUI({
      l
    })
  })

  last_click <- reactive({
    lc <- input$last_click
    if (is.null(lc)) lc <- "datos_dw"
    lc
  })

  output$down_index <- renderUI({
    req(last_click())
    if (last_click() == "datos_dw") {
      div(class = "tab-data-down",
          div(class = "data-opts",
              shinyinvoer::radioButtonsInput("dataDownId", p(class = "label-modal-rd", "Datos"), choices =  c("Base completa"))
          ),
          div(class = "data-format",
              shinyinvoer::radioButtonsInput("dataDownFormat", p(class = "label-modal-rd", "Formato"), choices =  c("CSV", "Json", "Excel", "SHP"))
          ),
          div(class = "donwData-button",
              downloadButton("dataToDownId", "Descargar", class = "data-dw-button")
          )
      )
    } else if (last_click() == "viz_dw") {
      div(class = "tab-data-down",
          div(class = "viz-format",
              shinyinvoer::radioButtonsInput("vizDownFormat", p(class = "label-modal-rd", "Formato"), choices =  c("PNG", "PDF", "HTML"))
          ),
          div(class = "donwViz-button",
              downloadButton("vizToDownId", "Descargar", class = "viz-dw-button")
          )
      )
    } else if (last_click() == "api_dw") {

      req(list_api())

      div(
        HTML(
          '<div class="text-api">Acceso al recurso de datos mediante una API web con servicio de consulta completo.
            Más información en <a id="link-modal" href="https://docs.ckan.org/en/2.9/api/index.html" target="blank">la documentación del API de Datos principal</a>
          y del <a id="link-modal" href="https://docs.ckan.org/en/2.9/maintaining/datastore.html?highlight=datastore#the-datastore-api" target="blank">DataStore de CKAN</a>.</div>'
        ),
        div(
          uiOutput("basicos")
        )
      )
    } else {
      return()
    }
  })


  output$dataToDownId <- downloadHandler(
    filename = function() {
      req(input$dataDownFormat)
      ext <- ".csv"
      if (input$dataDownFormat == "1") ext <- ".json"
      if (input$dataDownFormat == "2") ext <- ".xlsx"
      if (input$dataDownFormat == "3") ext <- ".zip"
      paste0("data-", Sys.Date(), ext)
    },
    content = function(file) {
      shiny::withProgress(
        message = "En proceso",
        value = 0,
        {
          req(input$dataDownId)
          data <- shape_fringe()$data

          if (grepl("csv", file)) {
            readr::write_csv(data, file)
          } else if (grepl("json", file)) {
            jsonlite::write_json(data, file)
          } else if (grepl("xlsx", file)){
            rio::export(data, file)
          } else {
            download.file(url = url_shape <- info_url()$url,
                          destfile = file)
          }
        })
    }
  )

  output$vizToDownId <- downloadHandler(
    filename = function() {
      req(input$vizDownFormat)
      ext <- ".png"
      #if (input$vizDownFormat == "1") ext <- ".jpg"
      if (input$vizDownFormat == "1") ext <- ".pdf"
      if (input$vizDownFormat == "2") ext <- ".html"
      paste0("viz-", Sys.Date(), ext)
    },
    content = function(file) {

      req(input$vizDownFormat)
      req(params_markdown())
      print("in fileeee")
      shiny::withProgress(
        message = "En proceso",
        value = 0,
        {
          shiny::incProgress(1/10)
          Sys.sleep(1)
          shiny::incProgress(5/10)
          ext <- ".png"
          #if (input$vizDownFormat == "1") ext <- ".jpg"
          if (input$vizDownFormat == "1") ext <- ".pdf"
          if (input$vizDownFormat == "2") ext <- ".html"

          cdmx.shapes:::download_viz(params = params_markdown(),
                                     file = file,
                                     ext = ext,
                                     template_file = "markdown/template.Rmd")
        })

    }
  )


  # info footer -------------------------------------------------------------

  summary_info <- reactive({
    tryCatch({
      req(shape_fringe())

      nrowIni <- nrow(shape_fringe()$data)

      pctgView <- 100
      nDig <- 2
      if (pctgView == 100) nDig <- 0
      HTML(paste0(
        "<div class = 'dataSummary'>",
        "<div class = 'infoAll'>",format(nrowIni, big.mark = ","), "<span class = 'infoAdd'>Total</span></div>",
        "<div class = 'infoAll footer-center-line'>",format( nrowIni, big.mark = ","), "<span class = 'infoAdd'>Visualizados</span></div>",
        "<div class = 'infoAll footer-center-line'>",format(pctgView, big.mark = ",", digits = 2, nsmall = nDig), "%<span class = 'infoAdd'> del total</span></div>",
        # "<div class = 'infoAll' style = 'border-left: 1px solid;margin-left:3%;padding: 0% 3%;'>",format(sum(Nmv$Total, na.rm = TRUE), big.mark = ","), "<span class = 'infoAdd'>No identificados</span></div>
        "</div>"
      ))
    },
    error = function(cond) {
      return()
    })
  })

  output$summaryInfo <- renderUI({
    req(summary_info())
    summary_info()
  })

  output$infoButt <- renderUI({
    div(style = "display: flex;gap:20px; margin: 1px 20px 1px 0px;",
        actionButton("descripcion_modal", "Descripción"),
        actionButton("dicc_modal", "Diccionario"),
        actionButton("recursos_modal", "Recursos")
    )
  })

  observeEvent(input$descripcion_modal, {
    shinypanels::showModal("modal_viz_info")
  })

  output$info_plots <- renderUI({
    tx <- info_url()$name
    if (is.null(info_url()$name)) tx <- ""
    tx <- markdown::markdownToHTML(text = tx, fragment.only = TRUE)
    ds <- info_url()$description
    if (is.null(info_url()$description))  ds <- ""
    ds <- markdown::markdownToHTML(text = ds, fragment.only = TRUE)
    HTML(
      paste0("<b>",tx, "</b><br/><br/>", ds)
    )
  })


  observeEvent(input$dicc_modal, {
    shinypanels::showModal("modal_dic_info")
  })

  output$tableDic <- DT::renderDataTable({
    df <- dic_to_labels()
    if (is.null(dic_to_labels())) {
      df <- shape_fringe()$dic
      names(df) <- c("Nombre", "Etiqueta", "Tipo")
      df <- dplyr::as_tibble(df)
      df$Tipo <- as.character(df$Tipo)
    }


    print(class(df$Tipo))
    #names(df) <- c("Nombre", "Etiqueta", "Descripción", "Tipo")
    dtable <- DT::datatable(df,
                            rownames = F,
                            escape = FALSE,
                            selection = 'none',
                            options = list(
                              lengthChange = F,
                              pageLength = nrow(df),
                              scrollX = T,
                              scrollY = T,
                              dom = 't')
    ) %>%
      DT::formatStyle( 0 , target= 'row',color = '#0A446B', fontSize ='13px', lineHeight='15px')


    dtable
  })


  output$infoDics <- renderUI({
    div(
      dsmodules::downloadTableUI("dropdown_dic", dropdownLabel = "Descargar", formats = c("csv", "xlsx", "json"), display = "dropdown"),
      DT::dataTableOutput("tableDic")
    )
  })


  dic_down <- reactive({
    dic_down <- NULL
    if (!is.null(dic_to_labels())) {
      dic_down <- dic_to_labels()
    } else {
      dic_down <- shape_fringe()$dic
    }
    dic_down
  })

  observe({
    dsmodules::downloadTableServer("dropdown_dic", element = reactive(dic_down()), formats = c("csv", "xlsx", "json"))
  })



  observeEvent(input$recursos_modal, {
    shinypanels::showModal("modal_rec_info")
  })


  observe({
    # infoResources <- listDic$listResources$format
    infoResources <- dic_ckan()$listResources
    if (is.null(infoResources)) return()
    purrr::map(1:nrow(infoResources), function(i) {
      output[[paste0("infoResources", i)]] <- downloadHandler(
        filename = paste0(infoResources$name[i], ".", infoResources$format[i]),
        content = function(file) {
          print(infoResources$format[i])
          saveFile <- paste0(tempdir(), "/pdf", i, ".", infoResources$format[i])
          print(saveFile)
          download.file(url = infoResources$url[i],
                        destfile = saveFile)
          file.copy(saveFile, file)
        }
      )
    })
  })



  output$info_recs <- renderUI({
    infoResources <- dic_ckan()$listResources
    if (is.null(infoResources)) return()

    div(style="display: inline-grid;gap: 21px;",
        purrr::map(1:nrow(infoResources), function(i) {
          print("format")
          print(infoResources$format[i])
          format <- infoResources$format[i]
          color <- "#B6C9C9"
            if (format == "csv") color <- "#CCC41C"
            if (format == "xlsx") color <- "#71B365"
            if (format == "pdf") color <- "#E0051E"
            if (format == "shp") color <- "#C9BF9C"
            if (format == "zip") color <- "#696DA9"
            if (format == "geojson") color <- "#8B3D08"
            if (format == "json") color <- "#CE5858"
            if (format == "json") color <- "#CE5858"
            if (format %in% c("doc", "docx")) color <- "#3E9FCC"

          div (class = "down-resources",
               HTML(paste0('<span class="text-center rounded font-weight-bold flex-shrink-0 mr-2 px-2 py-1 text-sm text-white" property="dc:format" data-format="csv" style="width: 60px;background-color:',color,'";">',
                           img(src= 'img/descarga-icon-w.svg', class = "img-down"),
                           '<span class="ml-1">',format,'</span>
                        </span>')),
               downloadLink(paste0("infoResources", i), span(style="font-size: 13px;color: #435b69;",infoResources$name[i]))
          )

        })
    )
  })

}

shinyApp(ui, server)



