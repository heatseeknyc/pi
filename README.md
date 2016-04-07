# Installing ("flashing") firmware

## Raspberry π ("Heat Seek OS")
1. Place `heatseekos.img` on your Desktop _TODO put it in Google Drive_
1. Insert an SD card into your computer or a USB card reader, potentially with an adapter to make it fit.
1. Once you see the disk appear in Finder, go to Terminal.
1. Run `diskutil unmountDisk /dev/disk2`
1. Run `sudo dd bs=1m if=$HOME/Desktop/heatseekos.img of=/dev/disk2 && say "Done flashing SD card."`
1. Wait about 25 minutes.
1. After the command finishes, go to Finder and eject the "boot" disk.
1. Remove the SD card and stick it in a π!

## XBee
1. Download and install [FTDI VCP drivers](http://www.ftdichip.com/Drivers/VCP.htm) for the [XBee dongle](https://www.sparkfun.com/products/11697).
1. Restart your computer, or things will misbehave.
1. Download and install [XCTU](http://www.digi.com/products/xbee-rf-solutions/xctu-software/xctu)
1. Put an XBee in the dongle and insert ehd ongle into your computer.
1. Open XCTU, click the top left "+" button to add the XBee.
1. Choose the device with a name like "usbserial-…"
1. Once the XBee has been added, click on it, and the click on the button with a person's outline on it, aka "Profile", and choose one of the following files:
  - [hub-pro.xml](https://raw.githubusercontent.com/heatseeknyc/firmware/master/xctung/hub-pro.xml) for a hub's XBee Pro
  - [cell-pro.xml](https://raw.githubusercontent.com/heatseeknyc/firmware/master/xctung/cell-pro.xml) for a cell's XBee Pro
  - [cell.xml](https://raw.githubusercontent.com/heatseeknyc/firmware/master/xctung/cell.xml) for a cell's regular XBee
1. If prompted, agree to update the firmware.
1. After everything is done click the pencil button, aka "Write", to write the changes.
1. Click the X button on the XBee to remove it from XCTU, and then remove the USB dongle.

# Updating a Running Hub

    cd firmware
    git pull
    sudo supervisorctl reload

# How to set up a hub from scratch

## Ingredients
- Raspberry π
- XBee
- Heat Seek hub board (allows you to connect the XBee to the π)
- 3G USB modem with SIM card
- SD card
- SD card adapter (lets you put the SD card into a computer to copy Raspbian to it)
- USB-to-Ethernet adapter. [This one](http://www.amazon.com/Cable-Matters%C2%AE-SuperSpeed-Gigabit-Ethernet/dp/B00BBD7NFU) works. Others, including a Gigaware one I tried, may not.

## Steps
1. Download the [latest Raspbian](http://downloads.raspberrypi.org/raspbian_latest)
1. Extract the .zip archive to get the .img file.
1. Copy it to the SD card. On a Mac, you do `diskutil list` to see which device is the SD card (for me it's always `/dev/disk2`), then `diskutil unmountDisk /dev/disk2` (or whatever device yours is), and finally `sudo dd bs=1m if=2015-05-05-raspbian-wheezy.img of=/dev/disk2` (or whatever Raspbian and disk you have). The final command takes about half an hour.
1. Eject the SD card, with Command+E in the Finder.
1. Put the SD card in the π, connect the USB-to-ethernet adapter from the π to your router, and plug in the π!
1. On a computer, try `ssh pi@raspberrypi.local`. If that doesn't work, run `nmap -p 22 --open 192.168.1.0/24` (with whatever your router's IP address range is) to find the ip address, and then run `ssh pi@192.168.1.108` (with the IP address you found). The password is 'raspberry'.
1. Now you're on the π! Run `git clone https://github.com/heatseeknyc/firmware.git && cd firmware && bash build.sh`
1. The setup script will ask you to configure the π, which involves changing the password, setting up the timezone and keyboard layout, et cetera… It will then reboot and you should run `cd firmware && bash build.sh` again, to finish the setup.
1. Unplug the ethernet adapter and replace it with the 3G modem, and wait for the modem light to turn solid blue.
1. Go to http://relay.heatseeknyc.com and enter the hub's XBee id (e.g. `0013a20040c17e5a`) and you should be able to see some info.
1. If you put batteries in cells their readings should start showing up on the Relay site. Though this all depends on the XBees having the correct settings, see "DigiMesh Firmware" below for those settings, which can be changed programatically from the π if you know what you're doing (see `hub/hourly.py` for an example) or can be changed with Digi's xctung software on your Mac using a [dongle](https://www.sparkfun.com/products/11697)

## Debugging
1. If the modem is solid blue, then ideally you'll be able to access the hub's page on http://relay.heatseeknyc.com, where you can find its current "reverse SSH port", as the last number in the "Status Log" section.
1. Once you have that port, then you can SSH into the π by first SSH'ing into relay.heatseeknyc.com, and then from there running `ssh -p <port> localhost` (replacing `<port>` with the latest port number from the Status Log)
1. Once you're SSH'ed into the π, you can look at logs of any of the processes listed in `conf/sueprvisor.conf` with a command like `sudo supervisorctl tail -f 3g`

## (Optional) Direct Ethernet Connection to a Computer
If you can't connect to a router, or something running a DHCP server, then you may need to use a fixed IP address:
**remove this when you're done, or things will misbehave**
On your Mac, with the SD card inserted, edit /Volumes/boot/cmdline.txt to set `ip=169.254.169.254`


# How to set up an XBee from the π
1. Turn off and unplug the hub before plugging in a different XBee chip.
1. Make sure nothing is talking to the XBee serial port. In particular, run `sudo supervisorctl stop receiver`
1. Connect to the XBEE over serial, with `sudo screen /dev/ttyAMA0`
1. Enter *command mode*, by typing `+++` and waiting to receive `OK`
1. Restore the XBee to factory defaults, by typing `ATRE`, pressing return, and waiting to receive `OK`
1. Set each parameter from "DigiMesh Firmware" below. For example if you are setting up a Cell, type `ATD02`, press return, wait for `OK`, type `ATD50`, press return, wait for `OK`, et cetera…
1. Make the changes permanent by writing to flash, by typing `ATWR`, pressing return, and waiting for `OK`.

# DigiMesh Firmware

## Cell
- **D0** = 2
- **D5** = 0
- **D7** = 0
- **D8** = 0
- **P0** = 0
- **PR** = 1DEF *default is 1FFF, but we turn off the pullups for AD0 (5th bit) and !SLEEP (10th bit)*
- **IR** = FFFF
- **SM** = 8

## Hub
- **AP** = 1
- **SM** = 7
- **SO** = 1
- **SP** = 1 *thence 57A58 (59m50s)*
- **ST** = 2710 (10s)

# How to edit the image file to make updates

First off, you need a linux machine and must be uid 1000, usually this is the first user created on the system. 
to find out your id, run this command: `id`
Then find a free loop device:

    sudo losetup -f

usually that will return `loop0` but if not, use whatever it returns in the place of `loop0` in the commands below.
next, load the image into the loop device and mount it.

    sudo losetup /dev/loop0 ~/heatseekos.img
    sudo mount /dev/loop0p2 /mnt

next, edit the files to your hearts content in the /mnt directory of your linux machine.
finally unmount the image to save it:

    sudo umount /mnt
    sudo losetup -d /dev/loop0

to flash this new image to an sd card, first find out the device name of the sdcard. `/dev/disk3` or `/dev/sdb` etc.

    sudo dd bs=4M if=heatseekos.img of=/dev/sdb

for a progress meter, use `pv` aquired by: `sudo apt-get install -y pv`

    dd bs=4M if=heatseekos.img | pv | sudo dd bs=4M of=/dev/sdb
