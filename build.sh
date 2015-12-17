if [ "$PWD" != "/home/pi/firmware" ]; then
    echo This file must be located in /home/pi/firmware
    exit
fi
git checkout master  # don't use dev branch in production

read -p "Have you already run raspi-config? [yN]" yn
if [ "$yn" != "y" ]; then
    read -p $'Configure options 2, 4 > Locale, 4 > Change Timezone, and 8 > Serial > No.\nDo not do option 1.\nPress enter to begin.'
    sudo raspi-config
    sudo reboot
    exit
fi

set -ex

sudo apt-get update
sudo apt-get -y install usb-modeswitch wvdial supervisor python3-pip vnstat sqlite3

# TODO this doesn't work during setup without a modem
# sudo vnstat -u -i ppp0  # start vnstat listening on ppp0 database

sudo pip-3.2 install -Ur requirements.txt

# TODO set up heatseeknyc.db using schema.sql, either by installing sqlite3 command or via python

mkdir -p ~/.ssh
cat conf/relay_rsa.pub >> ~/.ssh/authorized_keys

# allow passwordless ssh into the relay server to establish the reverse tunnel:
# TODO how to statically build this in to Heat Seek OS without compromising relay server? password during setup?
# TODO just copy a static key pair at this point, with corresponding pair built into the relay's sshd container
sudo ssh-keygen
sudo ssh-copy-id hubs@relay.heatseeknyc.com

sudo ln -sf $PWD/conf/wvdial.conf /etc/
sudo sed -i 's/^usepeerdns/# usepeerdns/' /etc/ppp/peers/wvdial
sudo tee /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
sudo chattr +i /etc/resolv.conf

sudo ln -s $PWD/conf/supervisor.conf /etc/supervisor/conf.d/heatseeknyc.conf

read -p $'Configure option 1.\nDo not reboot!\nPress enter to begin.'
sudo raspi-config
