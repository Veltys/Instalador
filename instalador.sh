#!/usr/bin/env bash

## Variables
gestorPaquetes='apt'

## Funciones 1: actualizador
function actualizador {
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

	sudo chmod u+x /usr/local/bin/actualizador.sh

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
}



## Funciones 2: backup
function backup {
	case $sistema in
		0) backup_tipo_sistema='RaspberryPi' ;;
		1) backup_tipo_sistema='VPS' ;;
		*) backup_tipo_sistema='Otros' ;;
	esac

	sudo bash -c "cat <<EOS > /usr/local/bin/backup.sh
#!/bin/bash

export FTP_PASSWORD=\"***REMOVED***\"

duplicity --no-encryption --full-if-older-than 1M --exclude /mnt --exclude /media --exclude /tmp --exclude /proc --exclude /sys --exclude /var/lib/lxcfs / ftp://***REMOVED***@***REMOVED***/${backup_tipo_sistema}/${nombre_sistema} >> /var/log/duplicity.log

unset FTP_PASSWORD

EOS
"

	sudo chmod u+x /usr/local/bin/backup.sh

	sudo crontab -l > crontab.tmp

	sudo cat <<EOS >> crontab.tmp
# Copia de seguridad semanal
0			5		*	*	7	/usr/local/bin/backup.sh
EOS

	sudo crontab crontab.tmp
    rm crontab.tmp
}



## Funciones 3: internet_movil
function internet_movil {
	sudo bash -c "cat <<EOS > /usr/local/bin/internet_movil.sh
#!/bin/bash

/home/pi/umtskeeper/umtskeeper --sakisoperators \"USBINTERFACE='0' OTHER='USBMODEM' USBMODEM='12d1:1506' APN='CUSTOM_APN' CUSTOM_APN='gprs.pepephone.com' APN_USER='0' APN_PASS='0'\" --sakisswitches \"--sudo --console\" --devicename 'Huawei' --log --silent --monthstart 1 --nat 'no' --httpserver --httpport 8080

EOS
"
}



## Funciones 4: ssh_inverso
function ssh_inverso {
	ssh_inverso_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

	IFS=\. read -a ssh_inverso_split_ip <<<"${ssh_inverso_ip}"

	sudo bash -c "cat <<EOS > /usr/local/bin/tunel-${nombre_sistema}-Ultra.sh
#!/bin/bash

autossh -M 5122 -f -C -i /home/pi/.ssh/${nombre_sistema}.pem -o ServerAliveInterval=20 -N -R 2200${ssh_inverso_split_ip[3]}:${ssh_inverso_ip}:22 root@***REMOVED*** -p 22008

EOS
"

	sudo bash -c "cat <<EOS > /usr/local/bin/conexion-${nombre_sistema}-Ultra.sh
#!/bin/bash

ssh -C -i /home/pi/.ssh/${nombre_sistema}.pem -R 2200${ssh_inverso_split_ip[3]}:${ssh_inverso_ip}:22 root@***REMOVED*** -p 22008

EOS
"

	echo -n '¿Generar una clave nueva para el sistema? [S/n]: '
	read ssh_inverso_clave

	ssh_inverso_clave=${ssh_inverso_clave:0:1}
	ssh_inverso_clave=${ssh_inverso_clave,,}

	if [ $ssh_inverso_clave != 'n' ]; then
		ssh-keygen -b 2048 -t rsa -f /home/pi/.ssh/${sistema}.pem	
		mv /home/pi/.ssh/${sistema}.pem.pub /home/pi/.ssh/${sistema}.pub

		echo 'No olvide copiar la clave pública al servidor SSH'
	else
		echo 'No olvide copiar la clave privada al sistema'
	fi
}



## Funciones 5: instalar_crontabs
function instalar_crontabs {
	if [ $sistema = 0 ]; then

		crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Envío y borrado diarios del registro de las temperaturas del sistema
59			23		*	*	*	/usr/local/bin/informe.sh

# Aviso en caso de reinicio
@reboot							/usr/local/bin/reinicio.sh
EOS

		crontab crontab.tmp

		sudo crontab -l > crontab.tmp

		cat <<EOS >> crontab.tmp

# Registro cada media hora de las temperaturas del sistema
0,30			*		*	*	*	echo "\`date\`, \`uptime -p\`, \`/opt/vc/bin/vcgencmd measure_temp\`, \`cat /proc/loadavg\`" >> /var/log/health.log
EOS

		sudo crontab crontab.tmp
    	rm crontab.tmp
	fi
}



## Configuración
echo -n '¿Qué se va a instalar? [(R)aspberry|(V)PS|Otro]: '
read sistema

sistema=${sistema:0:1}
sistema=${sistema,,}

case $sistema in
	'r') sistema=0

		 programas=('cifs-utils' 'gparted' 'ntp' 'pptp-linux' 'sshfs');;

	'v') sistema=1

		 programas=('cifs-utils'                 'pptp-linux' 'sshfs');;

	*  ) sistema=2

		 programas=('cifs-utils' 'gparted' 'ntp' 'pptp-linux' 'sshfs');;
esac

echo -n 'Nombre del sistema: '
read nombre_sistema


## Contraseñas
if [ $sistema != 0 ] && [ $sistema != 1 ]; then
	echo -n '¿Es necesario cambiar las contraseñas? [S/n]: '
	read contrasenya

	contrasenya=${contrasenya:0:1}
	contrasenya=${contrasenya,,}
fi

if [ $sistema = 0 ] || [ $sistema = 1 ] || [ $contrasenya != 'n' ]; then
	passwd

	sudo passwd
fi


## Actualizaciones e instalación
echo 'Actualizando sistema...'

sudo ${gestorPaquetes} update
sudo ${gestorPaquetes} upgrade -y

echo 'Instalando paquetes...'

programas_a_instalar='elinks htop nano'

for (( i = 0; i<${#programas[@]}; i++ )); do
	echo -n "¿Instalar el paquete \"${programas[$i]}\"? [S/n]: "
	read instalar

	instalar=${instalar:0:1}
	instalar=${instalar,,}

	if [ $instalar != 'n' ]; then
		programas_a_instalar="$programas_a_instalar ${programas[$i]}"
	fi
done

sudo ${gestorPaquetes} install ${programas_a_instalar} -y


## Configuración del servidor de hora
if [[ $programas_a_instalar = *'ntp'* ]]; then
	echo 'Configurando servidor de hora español (hora.roa.es)...'

	sed '/pool 0.debian.pool.ntp.org iburst/i server hora.roa.es' /etc/ntp.conf | sudo tee /etc/ntp.conf > /dev/null
fi


## Desinstalación de paquetes no necesarios
if [ $sistema = 0 ]; then
	echo 'Eliminando el paquete "dphys-swapfile"...'

	sudo dphys-swapfile swapoff
	sudo dphys-swapfile uninstall

	sudo ${gestorPaquetes} purge dphys-swapfile -y
fi


## Scripting 1: actualizador.sh
echo -n '¿Se asignará un DNS dinámico? [S/n]: '
read dns

dns=${dns:0:1}
dns=${dns,,}

if [ $dns != 'n' ]; then
	echo 'Instalando el paquete "curl", necesario para el DNS dinámico...'

	sudo ${gestorPaquetes} install curl -y

	echo 'Configurando parámetros del DNS dinámico...'

	actualizador
fi


## Scripting 2: backup.sh
echo -n '¿Se realizarán copias de seguridad? [S/n]: '
read copia_de_seguridad

copia_de_seguridad=${copia_de_seguridad:0:1}
copia_de_seguridad=${copia_de_seguridad,,}

if [ $copia_de_seguridad != 'n' ]; then
	echo 'Instalando el paquete "duplicity", necesario para las copias de seguridad...'

	sudo ${gestorPaquetes} install duplicity -y

	echo 'Configurando parámetros de la copia de seguridad...'

	backup
fi


## Scripting 3: internet_movil.sh
if [ $sistema = 0 ]; then
	echo -n '¿Se necesitará gestionar una conexión a Internet con un módem USB? [S/n]: '
	read modem_usb

	modem_usb=${modem_usb:0:1}
	modem_usb=${modem_usb,,}

	if [ $modem_usb != 'n' ]; then
		echo 'Descargando el paquete "UMTSkeeper", necesario para administrar el módem usb...'

		wget http://mintakaconciencia.net/squares/umtskeeper/src/umtskeeper.tar.gz

		echo "\"UMTSkeeper\" ha sido descargado en \"$(pwd)\""

		echo 'Configurando parámetros del gestor del módem USB...'

		internet_movil
	fi
fi


## Scripting 4: conexion-*.sh y tunel-*.sh
if [ $sistema = 0 ]; then
	echo -n '¿Se necesitará un túnel SSH inverso? [S/n]: '
	read tunel_ssh

	tunel_ssh=${tunel_ssh:0:1}
	tunel_ssh=${tunel_ssh,,}

	if [ $tunel_ssh != 'n' ]; then
		echo 'Instalando el paquete "autossh", necesario para mantener el túnel SSH...'

		sudo ${gestorPaquetes} install autossh -y

		echo 'Configurando parámetros del túnel SSH...'

		ssh_inverso
	fi
fi


## Scripting 5: contador
echo -n '¿Se debe instalar el script del contador LinuxCounter? [S/n]: '
read contador

contador=${contador:0:1}
contador=${contador,,}

if [ $contador != 'n' ]; then
	echo 'Instalando el script del contador...'

	wget https://github.com/christinloehner/linuxcounter-update-examples/raw/master/_official/lico-update.sh

	chmod +x lico-update.sh

	sudo mv lico-update.sh /usr/local/bin/lico-update.sh

	echo 'Configurando parámetros del script del contador...'

	/usr/local/bin/lico-update.sh -i
	/usr/local/bin/lico-update.sh -m
	/usr/local/bin/lico-update.sh -ci
fi


## Scripting 6: mailers
if [ $sistema = 0 ]; then
	echo 'Instalando mailers...'

	sudo bash -c "cat <<EEOS > /usr/local/bin/informe.sh
#!/usr/bin/env bash

cat <<EOS | mutt -s \"\\\$( whoami )@\\\$(uname -n): informe diario\" ***REMOVED***
Informe diario de \\\$(uname -n), correspondiente al \\\$( date ):

\\\$( cat /var/log/health.log )

EOS

truncate -s 0 /var/log/health.log
EEOS
"

	sudo chmod a+x /usr/local/bin/informe.sh

	sudo bash -c "cat <<EEOS > /usr/local/bin/reinicio.sh
#!/usr/bin/env bash

sleep 60

cat <<EOS | mutt -s \"\\\$( whoami )@\\\$(uname -n): informe especial\" ***REMOVED***
Informe especial de \\\$(uname -n), generado el \\\$( date ):

\\\$(uname -n) se ha reiniciado. Si no ha sido intencional este reinicio, es posible que haya habido un corte de luz.

EOS
EEOS
"

	sudo chmod a+x /usr/local/bin/reinicio.sh
fi


## Claves públicas SSH
echo 'Obteniendo las claves públicas para el servidor SSH...'

wget --user=***REMOVED*** --password=***REMOVED*** ***REMOVED***

if [ $sistema = 0 ]; then
	mkdir ~/.ssh

	chmod 700 ~/.ssh
fi

mv authorized_keys ~/.ssh/


## Personalizaciones del entorno
echo 'Estableciendo personalizaciones del entorno...'

sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc
sed -i -e 's/#export GCC_COLORS/export GCC_COLORS=/g' ~/.bashrc
sed -i -e "s/#alias ll='ls -l'/alias ll='ls -l'/g" ~/.bashrc
sed -i -e "s/#alias la='ls -A'/alias la='ls -A'/g" ~/.bashrc
sed -i -e "s/#alias l='ls -CF'/alias l='ls -CF'/g" ~/.bashrc

echo -n '¿Será necesario llamar al agente SSH (por ejemplo, para trabajar con Git)? [S/n]: '
read agente

agente=${agente:0:1}
agente=${agente,,}

if [ $agente != 'n' ]; then
	echo 'Instalando autoarranque del agente SSH...'

	cat <<EOS >> ~/.bashrc

# Añadir clave(s) SSH al agente
eval \$(ssh-agent)
ssh-add ~/.ssh/${nombre_sistema}.pem
EOS
fi

cat <<EOS >> ~/.bash_aliases
alias su='su -p'
alias ping='ping -c 4'
EOS

if [ $sistema = 0 ]; then
	cat <<EOS >> ~/.bash_aliases
alias apagar_pantalla='/opt/vc/bin/vcgencmd display_power 0'
alias encender_pantalla='/opt/vc/bin/vcgencmd display_power 1'
alias temperatura='/opt/vc/bin/vcgencmd measure_temp'
alias arreglar_iconos='sudo gdk-pixbuf-query-loaders --update-cache && sudo shutodown -r now'
EOS
fi


## VNC
echo 'No olvide instalar o actualizar el servidor VNC, si procede'


## Montaje de sistemas de archivos
echo 'Añadiendo sistemas de archivos remotos a /etc/fstab...'

if [[ $programas_a_instalar = *'cifs-utils'* ]]; then
	sudo bash -c "cat <<EOS > /root/.smbcredentials_***REMOVED***
username=***REMOVED***
password=***REMOVED***
EOS
"

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

if [[ $programas_a_instalar = *'sshfs'* ]]; then
	sudo bash -c "cat <<EOS >> /etc/fstab
***REMOVED***
EOS
"

	sudo mkdir ***REMOVED***

	sudo chmod 777 ***REMOVED***
fi

if [ $sistema = 0 ]; then
	echo 'En una Raspberry Pi, es necesario configurar manualmente el archivo de intercambio en /etc/fstab'
	echo 'No olvide reiniciar y configurarlo'
fi


## Instalación de crontabs
echo 'Instalando las tareas programadas (crontabs)...'

instalar_crontabs


# TODO: Instalar y configurar el cliente VPN (PPP)
# sudo nano /etc/ppp/peers/Plus
# sudo nano /etc/ppp/ip-up.d/000updateroutingtable
# sudo chmod a+x /etc/ppp/ip-up.d/000updateroutingtable

## Arreglo del ahorro de energía del HDMI
sudo bash -c "cat <<EOS >> /boot/config.txt

# Enable idle HDMI poweroff
hdmi_blanking=1
EOS
"