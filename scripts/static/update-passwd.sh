#!/bin/bash

set -u

_CONFIG=/opt/retronas/config/retronas.cfg
source $_CONFIG
source ${LIBDIR}/common.sh


USERNAME=${OLDRNUSER}
PASSWD="${1}"

[ -z "$PASSWD" ] && echo "No password supplied, exiting" && PAUSE && EXIT_CANCEL

# SYSTEM
echo "Updating system password for $USERNAME"
echo -e "${PASSWD}\n${PASSWD}" | sudo passwd $USERNAME 2>/dev/null

# SAMBA
SMB_SYSTEMD=$(systemctl show smbd.service --full --property FragmentPath --value)
if [ ! -z "${SMB_SYSTEMD}" ] && [ -f "${SMB_SYSTEMD}" ]
then
    echo "Updating Samba password for $USERNAME"
    echo -e "${PASSWD}\n${PASSWD}" | sudo smbpasswd -s -a $USERNAME 2>/dev/null
fi

# ATALK
ATALK_SYSTEMD=$(systemctl show atalkd.service --full --property FragmentPath --value)
if [ ! -z "${ATALK_SYSTEMD}" ] && [ -f "${ATALK_SYSTEMD}" ]
then
    ATALKDIR=/opt/retronas/bin/netatalk2x
    echo "Updating AppleTalk password for $USERNAME"
    if [ -f ${ATALKDIR}/etc/netatalk/afppasswd ]
    then
      touch ${ATALKDIR}/etc/netatalk/afppasswd
      sudo ${ATALKDIR}/bin/afpexpect.sh -a "${USERNAME}" "${PASSWD}" 2>/dev/null
    else
      echo "Appears you are using Netatalk 4 or above, password not managed here"
    fi
fi

# X11VNC
X11VNC=$(which x11vnc)
if [ ! -z "${X11VNC}" ]
then
    echo "Updating X11VNC password for $USERNAME"
    sudo $X11VNC -storepasswd "${PASSWD}" /etc/vncpasswd_retronas
    sudo -u $USERNAME $X11VNC -storepasswd "${PASSWD}" /home/$USERNAME/vncpasswd_retronas
fi

# RASCSI
if [ -f /opt/retronas/bin/RASCSI/rascsi ]
then 
    echo "Updating RASCSI password for $USERNAME"
    RASCSI_PASSWD=/etc/rascsi_passwd
    touch ${RASCSI_PASSWD}
    chmod 600 ${RASCSI_PASSWD}
    echo -e "${PASSWD}" | sudo tee ${RASCSI_PASSWD}
fi

# HTPASSWD (MD5 Apache)
HTPASSWD=/etc/retronas.htpasswd
if [ -f $HTPASSWD ]
then
  echo "Updating htpasswd password for $USERNAME"
  sed -i "/^${USERNAME}:.*/d" $HTPASSWD
  echo -e "${USERNAME}:$(openssl passwd -apr1 $PASSWD)" >> $HTPASSWD
fi
