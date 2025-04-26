# Visor Shapes


### Build and Run App Shiny
```
devtools::install()

shiny::runApp(system.file('gobmx-shapes-app', package = 'gobmx.shapes'))
```

### Build Image Docker
```
sudo docker build . -t us-central1-docker.pkg.dev/artifact-registry-gob-mx/datos-abiertos/visualizador-shapes:master_$(date +%d%m%y%H%M%S%s) 
```
