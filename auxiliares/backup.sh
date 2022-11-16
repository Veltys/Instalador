#!/bin/bash

# Title         : backup.sh
# Description   : Realiza una copia de seguridad con duplicity en el directorio indicado
# Author        : Veltys
# Date          : 2022-11-16
# Version       : 2.0.0
# Usage         : sudo bash backup.sh | sudo ./instalador.sh | instalar en la crontab del superusuario
# Notes         : Es necesario ser superusuario para su correcto funcionamiento


if [ ! -f '/etc/backup' ]; then
	echo "ERROR: El intento de copia de seguridad de $(date +'%d de %m de %Y a las %H:%M') ha fracasado debido a que no se encuentra el archivo de configuración" >> /var/log/duplicity.log
else
	source /etc/backup

	if mountpoint -q "${montaje}/"; then
	        duplicity --no-encryption --full-if-older-than 1M --exclude /media --exclude /mnt --exclude /proc --exclude /run --exclude /sys --exclude /tmp --exclude /var/lib/lxcfs / "file://${montaje}/${ruta}" >> /var/log/duplicity.log
	else
	        echo "ERROR: El intento de copia de seguridad de $(date +'%d de %m de %Y a las %H:%M') ha fracasado debido a que el dispositivo de destino no estaba montado" >> /var/log/duplicity.log
	fi
fi
