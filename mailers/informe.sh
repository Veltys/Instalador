#!/bin/bash

# Title         : informe.sh
# Description   : Informe diario del estado del sistema
# Author        : Veltys
# Date          : 2021-04-14
# Version       : 1.0.0
# Usage         : (Añadir a la crontab) | bash informe.sh | ./informe.sh
# Notes         : Requiere el programa mutt instalado y configurado


correo='correo@email.com'

temperaturas='True'

mensaje="Informe diario de $(uname -n), correspondiente al $(date):

$(cat /var/log/health.log)
"


if [ "$temperaturas" == 'True' ]; then
	mensaje="${mensaje}

$(/usr/local/bin/grafico_temperaturas.sh /var/log/health.log)
"
fi


echo "$mensaje" | mutt -s "$(whoami)@$(uname -n): informe diario" "${correo}"

truncate -s 0 /var/log/health.log
