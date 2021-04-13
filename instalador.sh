#!/bin/bash

# Title         : instalador.sh
# Description   : Instala los programas necesarios para la correcta puesta en marcha de un servidor basado en el glorioso Debian GNU/Linux
# Author        : Veltys
# Date          : 2021-04-13
# Version       : 3.4.0
# Usage         : sudo bash instalador.sh | ./instalador.sh
# Notes         : No es necesario ser superusuario para su correcto funcionamiento, pero sí poder hacer uso del comando "sudo"


## Variables
if [ -f 'config.sh' ]; then
	source config.sh
fi

if [ -z "$gestor_paquetes" ]; then
	gestor_paquetes='apt-get'
fi

if [ -z "$sistema_operativo" ]; then
	sistema_operativo=$(lsb_release -si)
fi


## Funciones 1: configurador_general
function configurador_general {
	if [ -z "$general_sistema" ]; then
		echo -n '¿Qué sistema se va a instalar? [(R)aspberry Pi|(V)PS|(O)tro]: '
		read general_sistema

		general_sistema=${general_sistema:0:1}
		general_sistema=${general_sistema,,}
	fi

	echo -n 'Ok. Instalaremos '

	case ${general_sistema} in
		'r') general_sistema=0
			 echo 'una Raspberry Pi'

			 programas=('cifs-utils' 'elinks' 'gparted' 'mutt' 'ntp' 'pptp-linux' 'speedtest-cli' 'sshfs');;

		'v') general_sistema=1
			 echo 'un servidor VPS'

			 programas=('cifs-utils' 'elinks'           'mutt' 'ntp' 'pptp-linux' 'speedtest-cli' 'sshfs');;

		*  ) general_sistema=2
			 echo 'otro tipo de sistema'

			 programas=('cifs-utils' 'elinks' 'gparted' 'mutt' 'ntp' 'pptp-linux' 'speedtest-cli' 'sshfs');;
	esac

	if [ -z "$general_nombre_sistema" ]; then
		echo -n 'Nombre propio (no DNS) del sistema: '
		read general_nombre_sistema
	fi
}


## Funciones 2: cambiador_de_contrasenyas
function cambiador_contrasenyas {
	if [ ${general_sistema} != 0 ] && [ ${general_sistema} != 1 ]; then
		if [ -z "$contrasenyas_contrasenya" ]; then
			echo -n '¿Es necesario cambiar las contraseñas? [S/n]: '
			read contrasenyas_contrasenya

			contrasenyas_contrasenya=${contrasenyas_contrasenya:0:1}
			contrasenyas_contrasenya=${contrasenyas_contrasenya,,}
		fi
	fi

	if [ ${general_sistema} = 0 ] || [ ${general_sistema} = 1 ] || [ ${contrasenyas_contrasenya} != 'n' ]; then
		contrasenyas_quiensoy=$(whoami)

		echo "Cambiando la contraseña del usuario ${contrasenyas_quiensoy}"

		sudo passwd ${contrasenyas_quiensoy}

		if [ "${contrasenyas_quiensoy}" != 'root' ]; then
			echo 'Cambiando la contraseña del usuario root'

			sudo passwd
		fi
	fi
}


## Funciones 3: actualizador_sistema
function actualizador_sistema {
	echo 'Actualizando sistema...'

	sudo ${gestor_paquetes} update
	sudo ${gestor_paquetes} upgrade -y
}


## Funciones 4: instalador_paquetes
function instalador_paquetes {
	echo 'Instalando paquetes...'

	programas_a_instalar='ca-certificates curl dnsutils lsb-release htop nano'

	for (( i = 0; i<${#programas[@]}; i++ )); do
		echo -n "¿Instalar el paquete \"${programas[$i]}\"? [S/n]: "
		read instalar

		instalar=${instalar:0:1}
		instalar=${instalar,,}

		if [ ${instalar} != 'n' ]; then
			programas_a_instalar="${programas_a_instalar} ${programas[$i]}"
		fi
	done

	sudo ${gestor_paquetes} install ${programas_a_instalar} -y
}


## Funciones 5: configurador_motd
function configurador_motd {
	echo 'Configurando el MOTD....'

	sudo ${gestor_paquetes} install figlet -y

	sudo bash -c "cat <<EOS > /etc/update-motd.d/00-header
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

[ -r /etc/os-release ] && . /etc/os-release

if [ ! -z \"\\\$PRETTY_NAME\" ]; then
        DISTRIB_DESCRIPTION=\"\\\$PRETTY_NAME\"
elif [ -z \"\\\$DISTRIB_DESCRIPTION\" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=\\\$(lsb_release -s -d)
fi

figlet \\\$(hostname)
printf \"\\\n\"

printf \"Welcome to %s (%s).\\\n\" \"\\\$DISTRIB_DESCRIPTION\" \"\\\$(uname -r)\"
printf \"\\\n\"
EOS
"

	sudo bash -c "cat <<EOS > /etc/update-motd.d/60-weather
#!/bin/sh

export TERM=xterm-256color

curl \"es.wttr.in/?0&m\"
echo
EOS
"

	if [ ${sistema_operativo} = 'Ubuntu' ]; then
		sudo ${gestor_paquetes} install landscape-common update-notifier-common -y

		sudo /usr/lib/update-notifier/update-motd-updates-available --force
	fi

	if [ ${sistema_operativo} = 'Debian' ] || [ ${sistema_operativo} = 'Raspbian' ]; then
		# FIXME: Caché para el control de actualizaciones
		sudo bash -c "cat <<EOS > /etc/update-motd.d/80-updates-available
#!/bin/sh

# echo \"Hay \\\$(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\\\w,\\\-,\\\d,\\\.,~,:,\\\+]+)\\\s\[[\\\w,\\\-,\\\d,\\\.,~,:,\\\+]+\\\]\\\s\\\([\\\w,\\\-,\\\d,\\\.,~,:,\\\+]+\\\)? /i) {print \"\\\$1\\\n\"}' | wc -l) paquetes no actualizados\"

echo \"El comprobador de actualizaciones ha sido temporalmente deshabilitado, debido a su alto consumo de recursos\"
echo
EOS
"

		sudo bash -c "cat <<EOS > /etc/update-motd.d/90-footer
#!/bin/sh
#
#    90-footer - write the admin's footer to the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 
[ -f /etc/motd.tail ] && cat /etc/motd.tail || true
EOS
"
	fi

	if [ ${sistema_operativo} = 'Debian' ]; then
		sudo bash -c "cat <<EOS > /etc/update-motd.d/10-sysinfo
#!/bin/bash
#
#    10-sysinfo - generate the system information
#    Copyright (c) 2013 Nick Charlton
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

date=\\\`date\\\`
load=\\\`cat /proc/loadavg | awk '{print \\\$1}'\\\`
root_usage=\\\`df -h / | awk '/\\\// {print \\\$(NF-1)}'\\\`
memory_usage=\\\`free -m | awk '/Mem:/ { total=\\\$2 } /buffers\/cache/ { used=\\\$3 } END { printf(\"%3.1f%%\", used/total*100)}'\\\`
swap_usage=\\\`free -m | awk '/Swap/ { printf(\"%3.1f%%\", \"exit !$2;$3/$2*100\") }'\\\`
users=\\\`users | wc -w\\\`
time=\\\`uptime | grep -ohe 'up .*' | sed 's/,/\\\ hours/g' | awk '{ printf \\\$2\" \"\\\$3 }'\\\`
processes=\\\`ps aux | wc -l\\\`
ip=\\\`ip a | grep glo | awk '{print \\\$2}' | head -1 | cut -f1 -d/\\\`

echo \"System information as of: \\\$date\"
echo
printf \"System load:\t%s\tIP Address:\t%s\n\" \\\$load \\\$ip
printf \"Memory usage:\t%s\tSystem uptime:\t%s\n\" \\\$memory_usage \"\\\$time\"
printf \"Usage on /:\t%s\tSwap usage:\t%s\n\" \\\$root_usage \\\$swap_usage
printf \"Local Users:\t%s\tProcesses:\t%s\n\" \\\$users \\\$processes
echo
EOS
"

		sudo rm /etc/update-motd.d/10-uname
	elif [ ${sistema_operativo} = 'Raspbian' ]; then
		sudo bash -c "cat <<EOS > /etc/update-motd.d/50-custom-motd
#!/bin/bash

export TERM=xterm-256color

let upSeconds=\"\\\$(/usr/bin/cut -d. -f1 /proc/uptime)\"
let secs=\\\$((\\\${upSeconds}%60))
let mins=\\\$((\\\${upSeconds}/60%60))
let hours=\\\$((\\\${upSeconds}/3600%24))
let days=\\\$((\\\${upSeconds}/86400))
UPTIME=\\\`printf \"%d días, %02dh%02dm%02ds\" \"\\\$days\" \"\\\$hours\" \"\\\$mins\" \"\\\$secs\"\\\`

MEMFREE=\\\`cat /proc/meminfo | grep MemFree | awk {'print \\\$2'}\\\`
MEMTOTAL=\\\`cat /proc/meminfo | grep MemTotal | awk {'print \\\$2'}\\\`

SDUSED=\\\`df -h | grep 'dev/root' | awk '{print \\\$3}' | xargs\\\`
SDAVAIL=\\\`df -h | grep 'dev/root' | awk '{print \\\$4}' | xargs\\\`

# get the load averages
read one five fifteen rest < /proc/loadavg

DARKGREY=\"\\\$(tput sgr0 ; tput bold ; tput setaf 0)\"
RED=\"\\\$(tput sgr0 ; tput setaf 1)\"
GREEN=\"\\\$(tput sgr0 ; tput setaf 2)\"
BLUE=\"\\\$(tput sgr0 ; tput setaf 4)\"
NC=\"\\\$(tput sgr0)\" # No Color

echo \"\\\${GREEN}
   .~~.   .~~.    \\\`date +\"%A, %e %B %Y, %r\"\\\`
  '. \ ' ' / .'   \\\`uname -srmo\\\`\\\${RED}
   .~ .~~~..~.
  : .~.'~'.~. :   \\\${DARKGREY}Tiempo en línea..........: \\\${BLUE}\\\${UPTIME}\\\${RED}
 ~ (   ) (   ) ~  \\\${DARKGREY}Memoria..................: \\\${BLUE}\\\${MEMFREE}kB (libre) / \\\${MEMTOTAL}kB (total)\\\${RED}
( : '~'.~.'~' : ) \\\${DARKGREY}Uso de disco.............: \\\${BLUE}\\\${SDUSED} (usado) / \\\${SDAVAIL} (libre)\\\${RED}
 ~ .~ (   ) ~. ~  \\\${DARKGREY}Cargas de trabajo........: \\\${BLUE}\\\${one}, \\\${five}, \\\${fifteen} (1, 5, 15 min)\\\${RED}
  (  : '~' :  )   \\\${DARKGREY}Procesos en ejecución....: \\\${BLUE}\\\`ps ax | wc -l | tr -d \" \"\\\`\\\${RED}
   '~ .~~~. ~'    \\\${DARKGREY}Direcciones IP...........: \\\${BLUE}\\\`ip a | grep glo | awk '{print \\\$2}' | head -1 | cut -f1 -d/\\\` y \\\`wget -q -O - http://icanhazip.com/ | tail\\\`\\\${RED}
       '~'        \\\${DARKGREY}Temperatura del sistema..: \\\${BLUE}\\\`/usr/bin/vcgencmd measure_temp | sed -r -e \"s/^temp=([0-9]*)\\\.([0-9])'C$/\1,\2 C/\"\\\`\\\${NC}
\"
EOS
"
	fi

	sudo chmod a+x /etc/update-motd.d/*
}


## Funciones 6: configurador_ntp
function configurador_ntp {
	if [[ ${programas_a_instalar} = *'ntp'* ]]; then
		echo 'Configurando servidor de hora español (hora.roa.es)...'

		sed '/^pool 0.[a-z]*.pool.ntp.org iburst$/i server hora.roa.es' /etc/ntp.conf | sudo tee /etc/ntp.conf > /dev/null
	fi
}


## Funciones 7: limpiador
function limpiador {
	echo 'Haciendo limpieza...'

	if [ ${general_sistema} = 0 ]; then
		echo 'Eliminando el paquete "dphys-swapfile"...'

		sudo dphys-swapfile swapoff
		sudo dphys-swapfile uninstall

		sudo ${gestor_paquetes} purge dphys-swapfile -y
	fi

	sudo ${gestor_paquetes} autoremove -y
}


## Funciones 8: configurador_ipv6
function configurador_ipv6 {
	if [ -z "$ipv6_ipv6" ]; then
		echo -n '¿Se necesitará activar el soporte para IPv6? [S/n]: '
		read ipv6_ipv6

		ipv6_ipv6=${ipv6_ipv6:0:1}
		ipv6_ipv6=${ipv6_ipv6,,}
	fi

	if [ ${ipv6_ipv6} != 'n' ]; then
		sudo sed -i -e 's/net.ipv6.conf.all.disable_ipv6 = 1/net.ipv6.conf.all.disable_ipv6 = 0/g' /etc/sysctl.conf
	fi
}


## Funciones 9: configurador_cortafuegos
function configurador_cortafuegos {
	if [ -z "$cortafuegos_cortafuegos" ]; then
		echo -n '¿Se necesitará instalar un cortafuegos? [S/n]: '
		read cortafuegos_cortafuegos

		cortafuegos_cortafuegos=${cortafuegos_cortafuegos:0:1}
		cortafuegos_cortafuegos=${cortafuegos_cortafuegos,,}
	fi

	if [ ${cortafuegos_cortafuegos} != 'n' ]; then
		echo 'Instalando el cortafuegos UFW...'

		sudo ${gestor_paquetes} install ufw -y

		echo 'Configurando el cortafuegos UFW para permitir las conexiones SSH...'
		sudo ufw allow 22/tcp comment 'Servidor SSH'
		sudo ufw enable

		echo 'No olvide, de ser necesario, añadir más reglas con la orden "ufw allow ..."'
	fi
}


## Funciones 10: actualizador_dns
function actualizador_dns {
	if [ -z "$dns_dns" ]; then
		echo -n '¿Se asignará un DNS dinámico? [S/n]: '
		read dns_dns

		dns_dns=${dns_dns:0:1}
		dns_dns=${dns_dns,,}
	fi

	if [ ${dns_dns} != 'n' ]; then
		echo 'Instalando el paquete "curl", necesario para el DNS dinámico...'

		sudo ${gestor_paquetes} install curl -y

		echo 'Configurando parámetros del DNS dinámico...'

		if [ -z "$dns_usuario" ]; then
			echo -n 'Nombre de usuario: '
			read dns_usuario
		fi

		if [ -z "$dns_contrasenya" ]; then
			echo -n 'Contraseña: '
			read dns_contrasenya
		fi

		if [ -z "$dns_num_dominios" ]; then
			echo -n '¿Cuántos dominios DNS se van a gestionar?: '
			read dns_num_dominios
		fi

		if [ -z "$dns_dominios" ]; then
			for (( i = 0; i<${dns_num_dominios}; i++ )); do
				echo -n 'Introduzca el dominio nº' $(( i+1 ))': '
				read dns_dominios[$i]
			done
		fi

		sudo bash -c "cat <<EOS > /usr/local/bin/actualizador.sh
#!/bin/bash

## Parámetros
usuario='${dns_usuario}'
password='${dns_contrasenya}'

EOS
"

		for (( i = 0; i<${dns_num_dominios}; i++ )); do
			sudo bash -c "echo \"hosts[${i}]='${dns_dominios[$i]}'\" >> /usr/local/bin/actualizador.sh"
		done

		sudo bash -c "cat <<EOS >> /usr/local/bin/actualizador.sh

url='https://www.ovh.com/nic/update?system=dyndns'

## Log (1=true, 0=false)
log=1
log_file='/var/log/dynhost.log'

## Actualizar IP
if [ \"\\\$log\" = '0' ]; then
  log_file='/dev/null'
fi

for host in \"\\\${hosts[@]}\"; do
  echo \"\\\`date\\\`, \\\$host: \\\`curl --user \\\"\\\$usuario:\\\$password\\\" \\\"\\\${url}&hostname=\\\${host}\\\"\\\`\" >> \\\$log_file
done

EOS
"

		sudo chmod a+x /usr/local/bin/actualizador.sh

		echo 'Ejecutando el script por primera vez...'

		sudo touch /var/log/dynhost.log

		sudo chmod 666 /var/log/dynhost.log

		/usr/local/bin/actualizador.sh

		echo 'Instalando la tarea programada (crontab)...'

		crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Actualización de la IP dinámica
@reboot								/usr/local/bin/actualizador.sh
0,30			*		*	*	*	/usr/local/bin/actualizador.sh

EOS

		crontab crontab.tmp
    	rm crontab.tmp
	fi
}


## Funciones 11: configurador_backups
function configurador_backups {
	if [ -z "$backups_backups" ]; then
		echo -n '¿Se realizarán copias de seguridad? [S/n]: '
		read backups_backups

		backups_backups=${backups_backups:0:1}
		backups_backups=${backups_backups,,}
	fi

	if [ ${backups_backups} != 'n' ]; then
		echo 'Instalando el paquete "duplicity", necesario para las copias de seguridad...'

		sudo ${gestor_paquetes} install duplicity -y

		echo 'Configurando parámetros de la copia de seguridad...'

		case ${general_sistema} in
			0) backups_tipo_sistema='RaspberryPi' ;;
			1) backups_tipo_sistema='VPS' ;;
			*) backups_tipo_sistema='Otros' ;;
		esac

		if [ -z "$backups_montaje" ]; then
			echo -n 'Punto de montaje donde se almacenarán las copias de seguridad: '
			read backups_backups
		fi

		sudo bash -c "cat <<EOS > /usr/local/bin/backup.sh
#!/bin/bash

duplicity --no-encryption --full-if-older-than 1M --exclude /mnt --exclude /media --exclude /tmp --exclude /proc --exclude /sys --exclude /var/lib/lxcfs / \"file:///${backups_montaje}/Copias de seguridad/${backups_tipo_sistema}/${general_nombre_sistema}\" >> /var/log/duplicity.log

EOS
"

		sudo chmod u+x /usr/local/bin/backup.sh

		sudo crontab -l > crontab.tmp

		sudo bash -c "cat <<EOS >> crontab.tmp
# Copia de seguridad semanal
0			5		*	*	7	/usr/local/bin/backup.sh
EOS
"

		sudo crontab crontab.tmp
    	rm crontab.tmp

		# TODO: clean_old_backups.sh

	fi
}


## Funciones 12: configurador_internet_movil
function configurador_internet_movil {
	if [ ${general_sistema} = 0 ]; then
		if [ -z "$internet_movil_internet_movil" ]; then
			echo -n '¿Se necesitará gestionar una conexión a Internet con un módem USB? [S/n]: '
			read internet_movil_internet_movil

			internet_movil_internet_movil=${internet_movil_internet_movil:0:1}
			internet_movil_internet_movil=${internet_movil_internet_movil,,}
		fi

		if [ ${internet_movil_internet_movil} != 'n' ]; then
			echo 'Descargando el paquete "UMTSkeeper", necesario para administrar el módem usb...'

			wget http://mintakaconciencia.net/squares/umtskeeper/src/umtskeeper.tar.gz

			echo "\"UMTSkeeper\" ha sido descargado en \"$(pwd)\""

			echo 'Configurando parámetros del gestor del módem USB...'

			sudo bash -c "cat <<EOS > /usr/local/bin/internet_movil.sh
#!/bin/bash

/home/pi/umtskeeper/umtskeeper --sakisoperators \"USBINTERFACE='0' OTHER='USBMODEM' USBMODEM='12d1:1506' APN='CUSTOM_APN' CUSTOM_APN='gprs.pepephone.com' APN_USER='0' APN_PASS='0'\" --sakisswitches \"--sudo --console\" --devicename 'Huawei' --log --silent --monthstart 1 --nat 'no' --httpserver --httpport 8080

EOS
"
		fi
	fi
}


## Funciones 13: configurador_ssh_inverso
function configurador_ssh_inverso {
	if [ ${general_sistema} = 0 ]; then
		if [ -z "$ssh_inverso_ssh_inverso" ]; then
			echo -n '¿Se necesitará un túnel SSH inverso? [S/n]: '
			read ssh_inverso_ssh_inverso

			ssh_inverso_ssh_inverso=${ssh_inverso_ssh_inverso:0:1}
			ssh_inverso_ssh_inverso=${ssh_inverso_ssh_inverso,,}
		fi

		if [ ${ssh_inverso_ssh_inverso} != 'n' ]; then
			echo 'Instalando el paquete "autossh", necesario para mantener el túnel SSH...'

			sudo ${gestor_paquetes} install autossh -y

			echo 'Configurando parámetros del túnel SSH...'

			ssh_inverso_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

			OLDIFS=$IFS
			IFS="\."

			read -a ssh_inverso_split_ip <<<"${ssh_inverso_ip}"

			IFS=$OLDIFS

			sudo bash -c "cat <<EOS > /usr/local/bin/tunel-${general_nombre_sistema}-Ultra.sh
#!/bin/bash

autossh -M 5122 -f -C -i /home/pi/.ssh/${general_nombre_sistema}.pem -o ServerAliveInterval=20 -N -R 2200${ssh_inverso_split_ip[3]}:${ssh_inverso_ip}:22 root@***REMOVED*** -p 22007

EOS
"

			sudo bash -c "cat <<EOS > /usr/local/bin/conexion-${general_nombre_sistema}-Ultra.sh
#!/bin/bash

ssh -C -i /home/pi/.ssh/${general_nombre_sistema}.pem -R 2200${ssh_inverso_split_ip[3]}:${ssh_inverso_ip}:22 root@***REMOVED*** -p 22007

EOS
"
		fi
	fi
}


## Funciones 14: configurador_contador_linux
function configurador_contador_linux {
	echo -n '¿Se debe instalar el script del contador LinuxCounter? [S/n]: '
	read contador_linux_contador

	contador_linux_contador=${contador_linux_contador:0:1}
	contador_linux_contador=${contador_linux_contador,,}

	if [ ${contador_linux_contador} != 'n' ]; then
		echo 'Instalando el script del contador...'

		wget https://github.com/christinloehner/linuxcounter-update-examples/raw/master/_official/lico-update.sh

		chmod +x lico-update.sh

		sudo mv lico-update.sh /usr/local/bin/lico-update.sh

		echo 'Configurando parámetros del script del contador...'

		/usr/local/bin/lico-update.sh -i
		/usr/local/bin/lico-update.sh -m
		/usr/local/bin/lico-update.sh -ci
	fi
}


## Funciones 15: instalador_mailers
function instalador_mailers {
	if [[ ${programas_a_instalar} = *'mutt'* ]]; then
		echo 'Instalando mailers...'

		sudo ${gestor_paquetes} install gpgsm -y

		if [ ${general_sistema} = 0 ] || [ ${general_sistema} = 1 ]; then
			sudo bash -c "cat <<EEOS > /usr/local/bin/informe.sh
#!/usr/bin/env bash

cat <<EOS | mutt -s \"\\\$(whoami)@\\\$(uname -n): informe diario\" veltys@gmail.com
Informe diario de \\\$(uname -n), correspondiente al \\\$(date):

\\\$(cat /var/log/health.log)

\\\$(/usr/local/bin/grafico_temperaturas.sh /var/log/health.log)

EOS

truncate -s 0 /var/log/health.log
EEOS
"

			sudo chmod a+x /usr/local/bin/informe.sh

			sudo bash -c "cat <<EEOS > /usr/local/bin/reinicio.sh
#!/usr/bin/env bash

sleep 60

cat <<EOS | mutt -s \"\\\$(whoami)@\\\$(uname -n): informe especial\" veltys@gmail.com
Informe especial de \\\$(uname -n), generado el \\\$(date):

\\\$(uname -n) se ha reiniciado. Si no ha sido intencional este reinicio, es posible que haya habido un corte de luz.

EOS
EEOS
"

			sudo chmod a+x /usr/local/bin/reinicio.sh
		fi
	fi

	# FIXME: Añadir el resto
}


## Funciones 16: instalador_claves_ssh
function instalador_claves_ssh {
	echo 'Obteniendo las claves públicas para el servidor SSH...'

	if [ -z "$claves_ssh_url" ]; then
		echo -n 'Introduzca la URL del servidor HTTP que contiene las claves: '
		read claves_ssh_url
	fi

	wget ${claves_ssh_url}

	mkdir ~/.ssh

	chmod 700 ~/.ssh

	mv authorized_keys ~/.ssh/

	# TODO: Instalar claves propias también
}


## Funciones 17: personalizador_entorno
function personalizador_entorno {
	echo 'Estableciendo personalizaciones del entorno...'

	sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc
	sed -i -e "s/#alias dir='dir --color=auto'/alias dir='dir --color=auto'/g" ~/.bashrc
	sed -i -e "s/#alias vdir='vdir --color=auto'/alias vdir='vdir --color=auto'/g" ~/.bashrc

	sed -i -e 's/#export GCC_COLORS/export GCC_COLORS/g' ~/.bashrc
	sed -i -e "s/#alias ll='ls -l'/alias ll='ls -l'/g" ~/.bashrc
	sed -i -e "s/#alias la='ls -A'/alias la='ls -A'/g" ~/.bashrc
	sed -i -e "s/#alias l='ls -CF'/alias l='ls -CF'/g" ~/.bashrc

	if [ -z "$entorno_agente" ]; then
		echo -n '¿Será necesario llamar al agente SSH (por ejemplo, para trabajar con Git)? [S/n]: '
		read entorno_agente

		entorno_agente=${entorno_agente:0:1}
		entorno_agente=${entorno_agente,,}
	fi

	if [ ${entorno_agente} != 'n' ]; then
		echo 'Instalando autoarranque del agente SSH...'

		cat <<EOS >> ~/.bashrc

# Añadir clave(s) SSH al agente
eval \$(ssh-agent)
ssh-add ~/.ssh/${general_nombre_sistema}.pem
EOS
	fi

	cat <<EOS >> ~/.bash_aliases
alias ping='ping -c 4'
# alias su='su -p'
alias traceroute='traceroute -I'
EOS

	if [ ${general_sistema} = 0 ]; then
		cat <<EOS >> ~/.bash_aliases
alias apagar_pantalla='/usr/bin/vcgencmd display_power 0'
alias encender_pantalla='/usr/bin/vcgencmd display_power 1'
alias temperatura='/usr/bin/vcgencmd measure_temp'
alias arreglar_iconos='sudo gdk-pixbuf-query-loaders --update-cache && sudo shutodown -r now'
EOS
	fi
}


## Funciones 18: configurador_fstab
function configurador_fstab {
	echo 'Añadiendo sistemas de archivos remotos a /etc/fstab...'

	if [[ ${programas_a_instalar} = *'cifs-utils'* ]]; then
		if [ -z "$fstab_servidor_smb" ]; then
			echo -n 'Introduzca la dirección del servidor SMB: '
			read fstab_servidor_smb
		fi

		if [ -z "$fstab_usuario_smb" ]; then
			echo -n 'Introduzca el usuario del servidor SMB: '
			read fstab_usuario_smb
		fi

		if [ -z "$fstab_contrasenya_smb" ]; then
			echo -n 'Introduzca la contraseña del servidor SMB: '
			read fstab_contrasenya_smb
		fi

		sudo bash -c "cat <<EOS > /root/.smbcredentials_${fstab_usuario_smb,,}
username=${fstab_usuario_smb}
password=${fstab_contrasenya_smb}
EOS
"

		if [ -z "$fstab_num_cifs" ]; then
			echo -n '¿Cuántas unidades CIFS se van a montar?: '
			read fstab_num_cifs
		fi

		if [ -z "$fstab_cifs" ]; then
			for (( i = 0; i<${fstab_num_cifs}; i++ )); do
				echo -n 'Introduzca la unidad nº' $(( i+1 ))': '
				read fstab_cifs[$i]
			done
		fi

		# FIXME: Esto aún no pirula
		for (( i = 0; i<${fstab_num_cifs}; i++ )); do
			sudo bash -c "echo \\\"//${fstab_servidor_smb}/${fstab_cifs[$i]}// /\\040}			/media/${fstab_cifs[$i]}// /\\040}			cifs		credentials=/root/.smbcredentials_${fstab_usuario_smb,,},iocharset=utf8,nofail,file_mode=0777,dir_mode=0777,vers=3.0,x-systemd.automount	0	0"

			sudo mkdir "/media/${fstab_cifs[$i]}"
		done

		sudo chmod 777 /media/*
	fi

	if [[ ${programas_a_instalar} = *'sshfs'* ]]; then
		if [ -z "$fstab_servidor_ssh" ]; then
			echo -n 'Introduzca la dirección del servidor SSH: '
			read fstab_servidor_ssh
		fi

		if [ -z "$fstab_usuario_ssh" ]; then
			echo -n 'Introduzca el usuario del servidor SSH: '
			read fstab_usuario_ssh
		fi

		if [ -z "$fstab_num_ssh" ]; then
			echo -n '¿Cuántas unidades SSHFS se van a montar?: '
			read fstab_num_ssh
		fi

		if [ -z "$fstab_ssh" ]; then
			for (( i = 0; i<${fstab_num_ssh}; i++ )); do
				echo -n 'Introduzca la unidad nº' $(( i+1 ))': '
				read fstab_ssh[$i]
			done
		fi

		# FIXME: Esto aún no pirula
		for (( i = 0; i<${fstab_num_ssh}; i++ )); do
			sudo bash -c "${fstab_usuario_ssh}@${fstab_servidor_ssh}:/home/${fstab_usuario_ssh}/				/media/${fstab_ssh[$i]}				fuse.sshfs	allow_other,IdentityFile=/home/pi/.ssh/${general_nombre_sistema}.pem									0	0"

			sudo mkdir "/media/${fstab_ssh[$i]}"
		done

		sudo chmod 777 /media/*
	fi

	if [ ${general_sistema} = 0 ]; then
		echo 'En una Raspberry Pi, es necesario configurar manualmente el archivo de intercambio en /etc/fstab'
		echo 'No olvide reiniciar y configurarlo'
	fi
}


## Funciones 19: instalador_crontabs
function instalador_crontabs {
	echo 'Instalando las tareas programadas (crontabs)...'

	if [ ${general_sistema} = 0 ]; then
		crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Envío y borrado diarios del registro de las temperaturas del sistema
59			23		*	*	*	/usr/local/bin/informe.sh

# Aviso en caso de reinicio
@reboot								/usr/local/bin/reinicio.sh
EOS

		crontab crontab.tmp

		sudo crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Registro cada media hora de las temperaturas del sistema
0,30			*		*	*	*	echo "\`date\`, \`uptime -p\`, \`/usr/bin/vcgencmd measure_temp\`, \`cat /proc/loadavg\`" >> /var/log/health.log
EOS

		sudo crontab crontab.tmp
    	rm crontab.tmp

		sudo touch /var/log/health.log
		sudo chmod 666 /var/log/health.log
	elif [ ${general_sistema} = 1 ]; then
		crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

#Envío y borrado diarios del registro del estado del sistema
59						23	*	*	*	/usr/local/bin/informe.sh

# Aviso en caso de reinicio
@reboot							/usr/local/bin/reinicio.sh
EOS

		crontab crontab.tmp

		sudo crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Registro cada media hora del estado del sistema
0,30			*		*	*	*	echo "`date`, `uptime -p`, `cat /proc/loadavg`" >> /var/log/health.log
EOS

		sudo crontab crontab.tmp
    	rm crontab.tmp

		sudo touch /var/log/health.log
		sudo chmod 666 /var/log/health.log

	fi
}


## Funciones 20: configurador_locales
function configurador_locales {
	if [ ${general_sistema} != 0 ]; then
		sudo ${gestor_paquetes} install manpages-es manpages-es-extra -y
		sudo dpkg-reconfigure locales
		export LANG=es_ES.UTF-8
	fi
}


## Funciones 21: instalador_kde
function instalador_kde {
	if [ ${general_sistema} != 0 ]; then
		if [ ${sistema_operativo} = 'Debian' ]; then

			if [ -z "$kde_kde" ]; then
				echo -n '¿Instalar el escritorio KDE? [s/N]: '
				read kde_kde

				kde_kde=${kde_kde:0:1}
				kde_kde=${kde_kde,,}
			fi

			if [ ${kde_kde} = 's' ]; then
				echo 'Instalando KDE...'

				sudo ${gestor_paquetes} install kde-plasma-desktop kde-l10n-es kwin-x11 systemsettings kscreen xorg -y

				# Componente gráfico del cortafuegos, instalable en el caso de tener KDE
				if [ ${cortafuegos_cortafuegos} != 'n' ]; then
					sudo ${gestor_paquetes} install gufw -y
				fi
			fi
		fi
	fi
}


## Bienvenida
echo 'Bienvenido al instalador interactivo de máquinas Linux'

## Configurador general
configurador_general

## Contraseñas
cambiador_contrasenyas

## Actualizaciones e instalación
actualizador_sistema

instalador_paquetes

## Configurador del MOTD
configurador_motd

## Configurador del servidor de hora
configurador_ntp

## Desinstalador de paquetes no necesarios
limpiador

## Configurador del soporte de IPv6
configurador_ipv6

## Configurador del cortafuegos
configurador_cortafuegos

## Actualizador de DNS dinámico
actualizador_dns

## Configurador de copias de seguridad
configurador_backups

## Configurador del Internet móvil
configurador_internet_movil

## Configurador del túnel SSH inverso
configurador_ssh_inverso

## Configurador del contador de Linux
# configurador_contador_linux

## Instalador de los "mailers"
instalador_mailers

## Instalador de las claves públicas SSH
instalador_claves_ssh

## Personalizador del entorno
personalizador_entorno

## VNC
echo 'No olvide instalar o actualizar el servidor VNC, si procede'

## Montaje de sistemas de archivos
configurador_fstab

## Instalación de crontabs
instalador_crontabs

# TODO: Instalar y configurar el cliente VPN (PPP)
# sudo nano /etc/ppp/peers/Plus
# sudo nano /etc/ppp/ip-up.d/000updateroutingtable
# sudo chmod a+x /etc/ppp/ip-up.d/000updateroutingtable

## Arreglador del ahorro de energía del HDMI
arreglador_hdmi

## Configurador de las locales
configurador_locales

## Instalador del maravilloso KDE
instalador_kde
