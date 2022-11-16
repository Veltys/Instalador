#!/bin/bash

# Title         : config.sh
# Description   : Configura el instalador, para que sea autónomo, o lo más autónomo posible
# Author        : Veltys
# Date          : 2022-06-30
# Version       : 1.7.0
# Usage         : sudo bash instalador.sh | ./instalador.sh
# Notes         : No es necesario ser superusuario para su correcto funcionamiento, pero sí poder hacer uso del comando "sudo"


# Gestor de paquetes
gestor_paquetes='apt-get'

# Sistema operativo
sistema_operativo=$(lsb_release -si)

# Sistema a instalar:
# r ➡ Raspberry Pi
# v ➡ VPS
# o ➡ Otro
general_sistema='v'

# Nombre propio (no DNS) del sistema
general_nombre_sistema='tester'

# Cambiar las contraseñas:
# s ➡ Sí
# n ➡ No
contrasenyas_contrasenya='n'

# Programas a instalar:
programas_opcionales=('apache2' 'libapache2-mod-php' 'php' 'speedtest-cli' 'sshfs' 'tmux');

programas_a_instalar='ca-certificates curl dnsutils elinks lsb-release htop nano neofetch nmon'

# Configurar IPv6
# s ➡ Sí
# n ➡ No
ipv6_ipv6='n'

# Instalar un cortafuegos:
# s ➡ Sí
# n ➡ No
cortafuegos_cortafuegos='n'

# Reglas adicionales para el cortafuegos
cortafuegos_reglas[0]=''

# Asignar DNS dinámico
# s ➡ Sí
# n ➡ No
dns_dns='n'

# Nombre de usuario del DNS dinámico
dns_usuario=''

# Contraseña del DNS dinámico
dns_contrasenya=''

# Número de dominios del DNS dinámico
dns_num_dominios=''

# Dominios del DNS dinámico
dns_dominios=''

# Realizar copias de seguridad
backups_backups='n'

# Punto de montaje donde se almacenarán las copias de seguridad
backups_montaje=''

# Gestionar una conexión a Internet con un módem USB
internet_movil_internet_movil='n'

# Túnel SSH inverso
ssh_inverso_ssh_inverso='n'

# Dirección de correo electrónico
mailers_correo=''

# Usuario IMAP
mailers_usuario_imap=''

# Contraseña IMAP
mailers_contrasenya_imap=''

# Carpeta IMAP
mailers_folder=''

# Archivo de cola IMAP
mailers_spoolfile=''

# Carpeta de borradores IMAP
mailers_postponed=''

# URL SMTP
mailer_smtp_url=''

# Contraseña SMTP
mailer_contrasenya_smtp=''

# URL del servidor HTTP con las claves SSH
claves_ssh_url='#'

# Llamar al agente SSH:
# s ➡ Sí
# n ➡ No
entorno_agente='n'

# Número de servidores SMB con los que se trabajará
fstab_num_servidores_smb=''

# Dirección de los servidores SMB
fstab_servidores_smb[0]=''

# Usuarios de los servidores SMB
fstab_usuarios_smb[0]=''

# Contraseñas de los servidores SMB
fstab_contrasenyas_smb[0]=''

# Número de unidades CIFS a montar
fstab_num_cifs[0]=''

# Unidades CIFS
declare -A fstab_cifs
fstab_cifs[0,0]=''

# Número de servidores SSH con los que se trabajará
fstab_num_servidores_ssh=''

# Direcciones de los servidores SSH
fstab_servidores_ssh[0]=''

# Usuarios de los servidores SSH
fstab_usuarios_ssh[0]=''

# Número de unidades SSH a montar
fstab_num_ssh[0]=''

# Unidades SSH
declare -A fstab_ssh
fstab_ssh[0,0]=''

# Ruta a las unidades SSH
declare -A fstab_ruta_ssh
fstab_ruta_ssh[0,0]=''

# Instalar KDE
# s ➡ Sí
# n ➡ No
kde_kde='n'
