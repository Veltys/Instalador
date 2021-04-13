#!/bin/bash

# Title         : reinicio.sh
# Description   : Informe especial al reinicio del sistema
# Author        : Veltys
# Date          : 2021-04-14
# Version       : 1.0.0
# Usage         : (Añadir a la crontab) | bash reinicio.sh | ./reinicio.sh
# Notes         : Requiere el programa mutt instalado y configurado


correo='correo@email.com'

mensaje="Informe especial de $(uname -n), generado el $( date ):

$(uname -n) se ha reiniciado. Si no ha sido intencional este reinicio, es posible que haya habido un corte en la red eléctrica.
"


sleep 60

echo "$mensaje" | mutt -s "$(whoami)@$(uname -n): informe diario" "${correo}"
