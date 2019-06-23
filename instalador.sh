#!/bin/bash

# Title         : instalador.sh
# Description   : Instala los programas necesarios para la correcta puesta en marcha de un servidor basado en el glorioso Debian GNU/Linux
# Author        : Veltys
# Date          : 23-07-2019
# Version       : 2.0.4
# Usage         : sudo bash instalador.sh | ./instalador.sh
# Notes         : No es necesario ser superusuario para su correcto funcionamiento, pero sí poder hacer uso del comando "sudo"


## Variables
gestor_paquetes='apt-get'


## Funciones 1: configurador_general
function configurador_general {
	echo -n '¿Qué se va a instalar? [(R)aspberry Pi|(V)PS|Otro]: '
	read general_sistema

	echo -n 'Ok. Instalaremos '

	general_sistema=${general_sistema:0:1}
	general_sistema=${general_sistema,,}

	case ${general_sistema} in
		'r') general_sistema=0
			 echo 'una Raspberry Pi'

			 programas=('cifs-utils' 'gparted' 'ntp' 'pptp-linux' 'sshfs');;

		'v') general_sistema=1
			 echo 'un servidor VPS'

			 programas=('cifs-utils'           'ntp' 'pptp-linux' 'sshfs');;

		*  ) general_sistema=2
			 echo 'otro tipo de sistema'

			 programas=('cifs-utils' 'gparted' 'ntp' 'pptp-linux' 'sshfs');;
	esac

	echo -n 'Nombre propio (no DNS) del sistema: '
	read general_nombre_sistema
}


## Funciones 2: cambiador_de_contrasenyas
function cambiador_de_contrasenyas {
	if [ ${general_sistema} != 0 ] && [ ${general_sistema} != 1 ]; then
		echo -n '¿Es necesario cambiar las contraseñas? [S/n]: '
		read contrasenyas_contrasenya

		contrasenyas_contrasenya=${contrasenyas_contrasenya:0:1}
		contrasenyas_contrasenya=${contrasenyas_contrasenya,,}
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

	programas_a_instalar='elinks htop nano dnsutils mutt gpgsm speedtest-cli'

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

	sudo bash -c "cat <<EOS > /etc/update-motd.d/60-weather
#!/bin/sh

export TERM=xterm-256color

curl es.wttr.in/?0
EOS
"

	sudo chmod a+x /etc/update-motd.d/60-weather

	if [ ${general_sistema} = 0 ]; then
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
       '~'        \\\${DARKGREY}Temperatura del sistema..: \\\${BLUE}\\\`/opt/vc/bin/vcgencmd measure_temp | sed -r -e \"s/^temp=([0-9]*)\\\.([0-9])'C$/\1,\2 C/\"\\\`\\\${NC}
\"
EOS
"

		sudo chmod a+x /etc/update-motd.d/50-custom-motd
	elif [ $general_sistema = 1 ]; then
		general_os=$(lsb_release -si)

		if [ $general_os = 'Ubuntu' ]; then
			sudo ${gestor_paquetes} install landscape-common update-notifier-common -y

			sudo /usr/lib/update-notifier/update-motd-updates-available --force
		elif [ $general_os = 'Debian' ]; then
			sudo ${gestor_paquetes} install figlet

			# TODO: Quitar los ***REMOVED***
			wget ***REMOVED***

			sudo apt install ./update-notifier-common_0.99.3debian11_all.deb -y

			sudo /usr/lib/update-notifier/update-motd-updates-available --force

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

if [ -z \"\\\$DISTRIB_DESCRIPTION\" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=\\\$(lsb_release -s -d)
fi

figlet \\\$(hostname)
printf \"\\\n\"

printf \"Welcome to %s (%s).\\\n\" \"\\\$DISTRIB_DESCRIPTION\" \"\\\$(uname -r)\"
printf \"\\\n\"
EOS
"

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
ip=\\\`ifconfig \\\$(route | grep default | awk '{ print $8 }') | grep \"inet \" | awk '{print \\\$2}'\\\`

echo \"System information as of: \\\$date\"
echo
printf \"System load:\t%s\tIP Address:\t%s\n\" \\\$load \\\$ip
printf \"Memory usage:\t%s\tSystem uptime:\t%s\n\" \\\$memory_usage \"\\\$time\"
printf \"Usage on /:\t%s\tSwap usage:\t%s\n\" \\\$root_usage \\\$swap_usage
printf \"Local Users:\t%s\tProcesses:\t%s\n\" \\\$users \\\$processes
echo
EOS
"

			sudo bash -c "cat <<EOS > /etc/update-motd.d/90-updates-available
#!/bin/sh

stamp=\"/var/lib/update-notifier/updates-available\"

[ ! -r \"\\\$stamp\" ] || cat \"\\\$stamp\"
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

			sudo rm /etc/update-motd.d/10-uname

			sudo chmod a+x /etc/update-motd.d/*
		fi
	fi
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


## Funciones 8: actualizador_dns
function actualizador_dns {
	echo -n '¿Se asignará un DNS dinámico? [S/n]: '
	read actualizador_dns

	actualizador_dns=${actualizador_dns:0:1}
	actualizador_dns=${actualizador_dns,,}

	if [ ${actualizador_dns} != 'n' ]; then
		echo 'Instalando el paquete "curl", necesario para el DNS dinámico...'

		sudo ${gestor_paquetes} install curl -y

		echo 'Configurando parámetros del DNS dinámico...'

		echo -n 'Nombre de usuario: '
		read actualizador_usuario

		echo -n 'Contraseña: '
		read actualizador_contrasenya

		echo -n '¿Cuántos dominios DNS se van a gestionar?: '
		read actualizador_num_dominios

		for (( i = 0; i<${actualizador_num_dominios}; i++ )); do
			echo -n 'Introduzca el dominio nº' $(( i+1 ))': '
			read actualizador_dominios[$i]
		done

		sudo bash -c "cat <<EOS > /usr/local/bin/actualizador.sh
#!/bin/bash

## Parámetros
usuario='${actualizador_usuario}'
password='${actualizador_contrasenya}'

EOS
"

		for (( i = 0; i<${actualizador_num_dominios}; i++ )); do
			sudo bash -c "echo \"hosts[${i}]='${actualizador_dominios[$i]}'\" >> /usr/local/bin/actualizador.sh"
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



## Funciones 9: configurador_backups
function configurador_backups {
	# TODO: Delegar las copias de seguridad en CIFS, si está disponible

	echo -n '¿Se realizarán copias de seguridad? [S/n]: '
	read backups_copia_de_seguridad

	backups_copia_de_seguridad=${backups_copia_de_seguridad:0:1}
	backups_copia_de_seguridad=${backups_copia_de_seguridad,,}

	if [ ${backups_copia_de_seguridad} != 'n' ]; then
		echo 'Instalando el paquete "duplicity", necesario para las copias de seguridad...'

		sudo ${gestor_paquetes} install duplicity lftp -y

		echo 'Configurando parámetros de la copia de seguridad...'

		case ${general_sistema} in
			0) backups_tipo_sistema='RaspberryPi' ;;
			1) backups_tipo_sistema='VPS' ;;
			*) backups_tipo_sistema='Otros' ;;
		esac

		echo -n 'Introduzca la contraseña del FTP de copias de seguridad: '
		read contrasenya_ftp

		# TODO: Quitar los ***REMOVED***
		sudo bash -c "cat <<EOS > /usr/local/bin/backup.sh
#!/bin/bash

export FTP_PASSWORD=\"${contrasenya_ftp}=\"

duplicity --no-encryption --full-if-older-than 1M --exclude /mnt --exclude /media --exclude /tmp --exclude /proc --exclude /sys --exclude /var/lib/lxcfs / ftp://***REMOVED***@***REMOVED***/${backup_tipo_sistema}/${nombre_sistema} >> /var/log/duplicity.log

unset FTP_PASSWORD

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
	fi
}



## Funciones 10: configurador_internet_movil
function configurador_internet_movil {
	if [ ${general_sistema} = 0 ]; then
		echo -n '¿Se necesitará gestionar una conexión a Internet con un módem USB? [S/n]: '
		read internet_movil_modem_usb

		internet_movil_modem_usb=${internet_movil_modem_usb:0:1}
		internet_movil_modem_usb=${internet_movil_modem_usb,,}

		if [ ${internet_movil_modem_usb} != 'n' ]; then
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



## Funciones 11: configurador_ssh_inverso
function configurador_ssh_inverso {
	if [ ${general_sistema} = 0 ]; then
		echo -n '¿Se necesitará un túnel SSH inverso? [S/n]: '
		read ssh_inverso_tunel_ssh

		ssh_inverso_tunel_ssh=${ssh_inverso_tunel_ssh:0:1}
		ssh_inverso_tunel_ssh=${ssh_inverso_tunel_ssh,,}

		if [ ${ssh_inverso_tunel_ssh} != 'n' ]; then
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

			echo -n '¿Generar una clave nueva para el sistema? [S/n]: '
			read ssh_inverso_clave

			ssh_inverso_clave=${ssh_inverso_clave:0:1}
			ssh_inverso_clave=${ssh_inverso_clave,,}

			if [ $ssh_inverso_clave != 'n' ]; then
				ssh-keygen -b 2048 -t rsa -f /home/pi/.ssh/${general_nombre_sistema}.pem
				mv /home/pi/.ssh/${general_nombre_sistema}.pem.pub /home/pi/.ssh/${general_nombre_sistema}.pub

				echo 'No olvide copiar la clave pública al servidor SSH'
			else
				echo 'No olvide copiar la clave privada al sistema'
			fi
		fi
	fi
}


## Funciones 12: configurador_contador_linux
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


## Funciones 13: instalador_mailers
function instalador_mailers {
	if [ $general_sistema = 0 ]; then
		echo 'Instalando mailers...'

		sudo bash -c "cat <<EEOS > /usr/local/bin/informe.sh
#!/usr/bin/env bash

cat <<EOS | mutt -s \"\\\$( whoami )@\\\$(uname -n): informe diario\" veltys@gmail.com
Informe diario de \\\$(uname -n), correspondiente al \\\$( date ):

\\\$( cat /var/log/health.log )

\\\$( /usr/local/bin/grafico_temperaturas.sh /var/log/health.log )

EOS

truncate -s 0 /var/log/health.log
EEOS
"

		sudo chmod a+x /usr/local/bin/informe.sh

		sudo bash -c "cat <<EEOS > /usr/local/bin/reinicio.sh
#!/usr/bin/env bash

sleep 60

cat <<EOS | mutt -s \"\\\$( whoami )@\\\$(uname -n): informe especial\" veltys@gmail.com
Informe especial de \\\$(uname -n), generado el \\\$( date ):

\\\$(uname -n) se ha reiniciado. Si no ha sido intencional este reinicio, es posible que haya habido un corte de luz.

EOS
EEOS
"

		sudo chmod a+x /usr/local/bin/reinicio.sh
	fi
}


## Funciones 14: instalador_claves_ssh
function instalador_claves_ssh {
	echo 'Obteniendo las claves públicas para el servidor SSH...'

	echo -n 'Introduzca el usuario del servidor HTTP que contiene las claves: '
	read claves_ssh_usuario
	
	echo -n 'Introduzca la contraseña del servidor HTTP que contiene las claves: '
	read claves_ssh_contrasenya
	
	echo -n 'Introduzca la URL del servidor HTTP que contiene las claves: '
	read claves_ssh_url

	wget --user=${claves_ssh_usuario} --password=${claves_ssh_contrasenya} ${claves_ssh_url}

	mkdir ~/.ssh

	chmod 700 ~/.ssh

	mv authorized_keys ~/.ssh/
}


## Funciones 15: personalizador_entorno
function personalizador_entorno {
	echo 'Estableciendo personalizaciones del entorno...'

	sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc
	sed -i -e "s/#alias dir='dir --color=auto'/alias dir='dir --color=auto'/g" ~/.bashrc
	sed -i -e "s/#alias vdir='vdir --color=auto'/alias vdir='vdir --color=auto'/g" ~/.bashrc

	sed -i -e 's/#export GCC_COLORS/export GCC_COLORS=/g' ~/.bashrc
	sed -i -e "s/#alias ll='ls -l'/alias ll='ls -l'/g" ~/.bashrc
	sed -i -e "s/#alias la='ls -A'/alias la='ls -A'/g" ~/.bashrc
	sed -i -e "s/#alias l='ls -CF'/alias l='ls -CF'/g" ~/.bashrc

	echo -n '¿Será necesario llamar al agente SSH (por ejemplo, para trabajar con Git)? [S/n]: '
	read entorno_agente

	entorno_agente=${entorno_agente:0:1}
	entorno_agente=${entorno_agente,,}

	if [ ${entorno_agente} != 'n' ]; then
		echo 'Instalando autoarranque del agente SSH...'

		cat <<EOS >> ~/.bashrc

# Añadir clave(s) SSH al agente
eval \$(ssh-agent)
ssh-add ~/.ssh/${general_nombre_sistema}.pem
EOS
	fi

	cat <<EOS >> ~/.bash_aliases
alias su='su -p'
alias ping='ping -c 4'
alias traceroute='traceroute -I'
EOS

	if [ ${general_sistema} = 0 ]; then
		cat <<EOS >> ~/.bash_aliases
alias apagar_pantalla='/opt/vc/bin/vcgencmd display_power 0'
alias encender_pantalla='/opt/vc/bin/vcgencmd display_power 1'
alias temperatura='/opt/vc/bin/vcgencmd measure_temp'
alias arreglar_iconos='sudo gdk-pixbuf-query-loaders --update-cache && sudo shutodown -r now'
EOS
	fi
}



## Funciones 16: configurador_fstab
function configurador_fstab {
	echo 'Añadiendo sistemas de archivos remotos a /etc/fstab...'

	if [[ ${programas_a_instalar} = *'cifs-utils'* ]]; then
		echo -n 'Introduzca el usuario del servidor SMB: '
		read usuario_smb

		echo -n 'Introduzca la contraseña del servidor SMB: '
		read contrasenya_smb

		sudo bash -c "cat <<EOS > /root/.smbcredentials_${usuario_smb,,}
username=${usuario_smb}
password=${contrasenya_smb}
EOS
"

		# TODO: Quitar los ***REMOVED***
		sudo bash -c "cat <<EOS >> /etc/fstab
***REMOVED***
***REMOVED***
***REMOVED***
***REMOVED***

EOS
"

		sudo mkdir ***REMOVED***
		sudo mkdir ***REMOVED***
		sudo mkdir ***REMOVED***
		sudo mkdir ***REMOVED***

		sudo chmod 777 /media/*
fi

	if [[ ${programas_a_instalar} = *'sshfs'* ]]; then
		sudo bash -c "cat <<EOS >> /etc/fstab
***REMOVED***
EOS
"

		sudo mkdir ***REMOVED***

		sudo chmod 777 ***REMOVED***
	fi

	if [ ${general_sistema} = 0 ]; then
		echo 'En una Raspberry Pi, es necesario configurar manualmente el archivo de intercambio en /etc/fstab'
		echo 'No olvide reiniciar y configurarlo'
	fi
}


## Funciones 17: instalador_crontabs
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
0,30			*		*	*	*	echo "\`date\`, \`uptime -p\`, \`/opt/vc/bin/vcgencmd measure_temp\`, \`cat /proc/loadavg\`" >> /var/log/health.log
EOS

		sudo crontab crontab.tmp
    	rm crontab.tmp

		sudo touch /var/log/health.log
		sudo chmod 666 /var/log/health.log
	fi
}


## Funciones 18: arreglador_hdmi
function arreglador_hdmi {
	if [ ${general_sistema} = 0 ]; then
		sudo bash -c "cat <<EOS >> /boot/config.txt

# Enable idle HDMI poweroff
hdmi_blanking=1
EOS
"
	fi
}


## Funciones 19: configurador_locales
function configurador_locales {
	if [ ${general_sistema} != 0 ]; then
		sudo ${gestor_paquetes} install manpages-es manpages-es-extra
		sudo dpkg-reconfigure locales
		export LANG=es_ES.UTF-8
	fi
}


## Funciones 20: instalador_kde
function instalador_kde {
	if [ ${general_sistema} != 0 ]; then
		if [ ${general_os} = 'Debian' ]; then
			echo -n '¿Instalar el escritorio KDE? [s/N]: '
			read kde

			kde_kde=${kde_kde:0:1}
			kde_kde=${kde_kde,,}

			if [ ${kde_kde} = 's' ]; then
				echo 'Instalando KDE...'

				sudo ${gestor_paquetes} install kde-plasma-desktop kde-l10n-es kwin-x11 systemsettings kscreen
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
