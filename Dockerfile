FROM --platform=linux/amd64 rocker/r-ver:4.2

# Exponer el puerto de Shiny
EXPOSE 3838

# Comando final para ejecutar la aplicación
CMD R -e "options('shiny.port'=3838, shiny.host='0.0.0.0'); cdmx.shapes:::run_app()"
