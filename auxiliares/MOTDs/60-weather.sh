#!/bin/sh

# Title         : 60-weather.sh
# Description   : Muestra el tiempo en el MOTD
# Author        : Veltys
# Date          : 2022-12-21
# Version       : 1.0.0
# Usage         : (llamado al iniciar sesión, si está correctamente instalado
# Notes         : Es necesaria una terminal de 256 colores para apreciar el dibujo ASCII adecuadamente


export TERM=xterm-256color

curl "es.wttr.in/?0&m"

echo
