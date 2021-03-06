##
## Run this script on a fresh copy of Raspbian Jessie Lite, with the commands:
## curl -O https://raw.githubusercontent.com/heatseeknyc/firmware/master/build.sh
## bash build.sh
##

set -e

if [ "$(whoami)" != "pi" ]; then
    echo "This script must be run as the 'pi' user."
    exit
fi

cd ~

mkdir -p secret
while [ ! -f "secret/id_rsa" ]; do
    cat <<EOF
Ask a friend for the hub secret key,
or get it from /root/.ssh/id_rsa on an existing hub,
and copy it to ~/secret/id_rsa

(for example, from your laptop:
scp hub_root_id_rsa pi@raspberrypi.local:secret/id_rsa
-or-
ssh pi@raspberrypi.local "cat > secret/id_rsa"
and then paste the secret key contents, press return, and press Control-D)

EOF
    read -p 'Press enter when done.'
done

cat <<EOF
On the next screen, configure ONLY these settings:

2 Change User Password
5 Internationalisation Options
  > I1 Change Locale - deselect en_GB and select en_US.UTF-8. then select en_US.UTF-8 for system default.
  > I2 Change Timezone - select US. then select Eastern.
9 Advanced Options > A8 Serial > No

Finally, select Finish.
Select No if prompted to reboot.

EOF
read -p 'Press enter to begin...'
sudo raspi-config
export LANG=en_US.utf8  # doesn't get properly set until reboot

sudo apt-get update
sudo apt-get -y install \
     git \
     python3-pip \
     sqlite3 \
     supervisor \
     usb-modeswitch \
     vnstat \
     wvdial \

# TODO this doesn't work during setup without a modem:
# sudo vnstat -u -i ppp0  # start vnstat listening on ppp0 database

git clone -b master https://github.com/heatseeknyc/firmware.git  # don't use default dev branch in production
cd firmware

sudo pip3 install -r requirements.txt

sqlite3 ~/heatseeknyc.db < schema.sql

# allow passwordless ssh from the tunnel server to hubs:
mkdir -p ~/.ssh
cp conf/relay_rsa.pub ~/.ssh/authorized_keys

# allow passwordless ssh from hubs to the tunnel server to establish the reverse tunnel:
sudo mkdir -p /root/.ssh
sudo cp conf/id_rsa.pub ~/secret/id_rsa /root/.ssh
sudo chmod 600 /root/.ssh/id_rsa
echo "Establishing tunnel.heatseek.org as a known host, enter 'yes' if prompted:"
sudo ssh hubs@tunnel.heatseek.org echo Success.

sudo ln -sf $PWD/conf/wvdial.conf /etc/
sudo sed -i 's/^usepeerdns/# usepeerdns/' /etc/ppp/peers/wvdial
sudo cp conf/resolv.conf /etc
sudo chattr +i /etc/resolv.conf

# enable UART for talking to XBee
sudo sed -i 's/^enable_uart=0/enable_uart=1/' /boot/config.txt

sudo ln -s $PWD/conf/supervisor.conf /etc/supervisor/conf.d/heatseeknyc.conf

cat <<EOF
On the next screen, configure ONLY the setting:

1 Expand Filesystem

Then select Finish.

**DO NOT REBOOT**

EOF
read -p 'Press enter to begin...'
sudo raspi-config
cat <<EOF
**DO NOT REBOOT**

If you reboot the filesystem will be resized and the image will be huge.

To copy the 'Heat Seek OS' you have just built to a file, run:
sudo shutdown -h now

Then unplug the Raspberry Pi, remove the SD card, insert it into a computer and copy it to a file using a utility such as 'dd'.

**DO NOT REBOOT**
EOF
