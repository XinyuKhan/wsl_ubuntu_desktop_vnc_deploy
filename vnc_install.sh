#!/bin/bash

# only run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "->>>>>>>>>> VNC Install <<<<<<<<<<"

source vnc_env.sh


echo "->>>>>>>>>> Copying the resources <<<<<<<<<<"
cp -rf resources /tmp/



echo "->>>>>>>>>> Installing basic packs <<<<<<<<<<"
apt-get update
apt-get install -y \
        inetutils-ping \
        lsb-release \
        net-tools \
        unzip \
        vim \
        zip \
        curl \
        git \
        wget 


echo "->>>>>>>>>> Installing VNC server <<<<<<<<<<"
apt-get update
apt install -y tigervnc-standalone-server



echo "->>>>>>>>>> Installing Desktop <<<<<<<<<<"
apt-get update
sudo apt install -y tasksel
sudo tasksel install ubuntu-desktop


echo "->>>>>>>>>> Installing dotnet-runtime <<<<<<<<<<"
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/packages-microsoft-prod.deb
apt update
apt install -y dotnet-runtime-5.0
rm -rf /tmp/packages-microsoft-prod.deb

echo "->>>>>>>>>> Installing systemd-genie <<<<<<<<<<"
# deb_name=`curl -s https://api.github.com/repos/arkane-systems/genie/releases/latest | grep name | grep deb | cut -d '"' -f 4`
# wget https://github.com/arkane-systems/genie/releases/latest/download/$deb_name
# sudo dpkg -i $deb_name
# sudo apt --fix-broken install
apt-get update
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/resources/systemd-genie_1.36_amd64.deb
apt --fix-broken install -y

echo "->>>>>>>>>> Set password of VNC <<<<<<<<<<"

CALL_USER=${SUDO_USER:-${USER}}

VNC_PASSWD="${CALL_USER}"
VNC_ENV_DIR="/home/${CALL_USER}/.vnc"
VNC_PASSWD_FILE_PATH="${VNC_ENV_DIR}/passwd"

mkdir "${VNC_ENV_DIR}"
echo "${VNC_PASSWD}" | vncpasswd -f >> "${VNC_PASSWD_FILE_PATH}"
chown ${CALL_USER}: ${VNC_PASSWD_FILE_PATH}
chmod 600 ${VNC_PASSWD_FILE_PATH}

GDM_HOME=`echo ~gdm`
GDM_VNC_ENV_DIR="${GDM_HOME}/.vnc"
GDM_VNC_PASSWD_FILE_PATH="${GDM_VNC_ENV_DIR}/passwd"

mkdir "${GDM_VNC_ENV_DIR}"
echo "${VNC_PASSWD}" | vncpasswd -f >> "${GDM_VNC_PASSWD_FILE_PATH}"
chown gdm: ${GDM_VNC_PASSWD_FILE_PATH}
chmod 600 ${GDM_VNC_PASSWD_FILE_PATH}

echo "->>>>>>>>>> Modify Xorg <<<<<<<<<<"
mv -f /tmp/resources/vnc_xorg /usr/bin/Xorg
chown root: /usr/bin/Xorg
chmod 0755 /usr/bin/Xorg


echo "->>>>>>>>>> Modify GDM configuration <<<<<<<<<<"

GDM_CONFIG=/etc/gdm3/custom.conf
sed -ri 's/^#?\s*AutomaticLoginEnable\s+.*/AutomaticLoginEnable = true/' ${GDM_CONFIG}
sed -ri "s/^#?\s*AutomaticLogin\s+.*/AutomaticLogin = ${CALL_USER}/" ${GDM_CONFIG}


rm -rf /var/lib/apt/lists/*
rm -rf /tmp/resources/