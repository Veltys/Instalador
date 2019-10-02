#!/bin/bash

# Title         : config.sh
# Description   : Configura el instalador, para que sea autónomo, o lo más autónomo posible
# Author        : Veltys
# Date          : 02-10-2019
# Version       : 1.0.1
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
general_sistema=''

# Nombre propio (no DNS) del sistema
general_nombre_sistema=''

# Cambiar las contraseñas:
# s ➡ Sí
# n ➡ No
contrasenyas_contrasenya=''

# Instalar un cortafuegos:
# s ➡ Sí
# n ➡ No
cortafuegos_cortafuegos=''

# Asignar DNS dinámico
# s ➡ Sí
# n ➡ No
dns_dns=''

# Nombre de usuario del DNS dinámico
dns_usuario=''

# Contraseña del DNS dinámico
dns_contrasenya=''

# Número de dominios del DNS dinámico
dns_num_dominios=''

# Dominios del DNS dinámico
dns_dominios=''

# Realizar copias de seguridad
backups_backups=''

# Dirección del servidor FTP de copias de seguridad
backups_servidor_ftp=''

# Usuario del servidor FTP de copias de seguridad
backups_usuario_ftp=''

# Contraseña del servidor FTP de copias de seguridad
backups_contrasenya_ftp=''

# Gestionar una conexión a Internet con un módem USB
internet_movil_internet_movil=''

# Túnel SSH inverso
ssh_inverso_ssh_inverso=''

# URL del servidor HTTP con las claves SSH
claves_ssh_url=''

# Llamar al agente SSH:
# s ➡ Sí
# n ➡ No
entorno_agente=''

# Dirección del servidor SMB
fstab_servidor_smb=''

# Usuario del servidor SMB
fstab_usuario_smb=''

# Contraseña del servidor SMB
fstab_contrasenya_smb=''

# Unidades CIFS a montar
fstab_num_cifs=''

# Unidades CIFS
fstab_cifs=''

# Dirección del servidor SSH
fstab_servidor_ssh=''

# Usuario del servidor SSH
fstab_usuario_ssh=''

# Unidades SSH a montar
fstab_num_ssh=''

# Unidades SSH
fstab_ssh=''

# Instalar KDE
# s ➡ Sí
# n ➡ No
kde_kde=''
