#!/bin/bash

# Title         : clean_old_backups.sh
# Description   : Elimina copias de seguridad de duplicity anteriores a un tiempo dado
# Author        : Veltys
# Date          : 2022-11-16
# Version       : 2.0.0
# Usage         : sudo bash clean_old_backups.sh | sudo ./clean_old_backups.sh | instalar en la crontab del superusuario
# Notes         : Es necesario ser superusuario para su correcto funcionamiento


if [ ! -f '/etc/backup' ]; then
	echo "ERROR: El intento de limpieza de las copias de seguridad de $(date +'%d de %m de %Y a las %H:%M') ha fracasado debido a que no se encuentra el archivo de configuración" >> /var/log/duplicity.log
else
	source /etc/backup

	if mountpoint -q "${montaje}/"; then
	        duplicity remove-older-than "${antiguedad}" --force "file://${montaje}/${ruta}" >> /var/log/duplicity.log
	fi
fi