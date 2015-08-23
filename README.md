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
1. Now you're on the π! Run `git clone https://github.com/heatseeknyc/firmware.git && cd firmware && bash setup.sh`
1. The setup script will ask you to configure the π, which involves changing the password, setting up the timezone and keyboard layout, et cetera… It will then reboot and you should run `cd firmware && bash setup.sh` again, to finish the setup.
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


# DigiMesh Firmware
We use the DigiMesh protocol instead of the zigbee protocol to conserve
power. In zigbee, all nodes are coordinator nodes, so they must all be
online all the time, requiring constant power draw. In DigiMesh, only
the sleep coordinator needs to be online at all times, and the other
nodes can remain asleep except when transmitting readings.

## How to set up an XBee from the π
1. Turn off and unplug the hub before plugging in a different XBee chip.
1. Make sure nothing is talking to the XBee serial port. In particular, run `sudo supervisorctl stop receiver`.
1. Connect to the XBEE over serial, with `sudo screen /dev/ttyAMA0`. If
   screen doesn't work, try minicom with `sudo minicom -b 9600`.
The -b flag specifies a baud rate. You may need to `apt-get install
screen` or `apt-get install minicom`.
1. Enter *command mode*, by typing `+++` and waiting to receive `OK`
1. Restore the XBee to factory defaults, by typing `ATRE`, pressing return, and waiting to receive `OK`. Note that output gets overwritten each time. If you get multiple `OK`s, it may be hard to tell. You can confirm by sending `ATID` and pressing return to get the ID back, overwriting the output with something other than `OK`.
1. Set each parameter from "DigiMesh Firmware" below. For example if you are setting up a Cell, type `ATD02`, press return, wait for `OK`, type `ATD50`, press return, wait for `OK`, et cetera…
1. Make the changes permanent by writing to flash, by typing `ATWR`, pressing return, and waiting for `OK`.

### Hub
#### configuring the sleep coordinator node
The sleep coordinator is responsible for defining the sleep parameters
for all the cells in the mesh, and preventing the cells from time
drifting away from their siblings. It makes sense for the sleep
coordinator to be installed on the hub since it will always be awake.

It is important for the xbees attached to cells to be explicitly
configured as a "non-sleep coordinator"; this prevents them from
competing with the hub for control of the network. To do this, each
cell's xbee must have the SO bit set to the value of 1.

See [Sleep Settings within DigiMesh at
digi.com](https://www.digi.com/wiki/developer/index.php/Sleep_Settings_within_DigiMesh)

Also see [xbee pro
manual](http://ftp1.digi.com/support/documentation/90000991_N.pdf)

When configuring 

- **AP** = 1 # turn on API mode (manual page 67)
- **SM** = 7 # set sleep mode to Asynchronous cyclic sleep with pin wake-up (manual page 67)
- **SO** = 0 # set to preferred sleep coordinator (manual page 67)
- **SP** = 1 *thence 57A58 (59m50s)* # define the amount of time the module will sleep per cycle to 1 second (or 59m50s after setup) (manual page 67)
- **ST** = 2710 (10s) # set the wake period of the module (manual page 68)

### Cell
#### configuring all other nodes
Wire in thermometer by configuring pins.
- **D0** = 2
- **D5** = 0
- **D7** = 0
- **D8** = 0
- **P0** = 0
- **PR** = 80 *TODO in the future we'll use 0 for cell≥v0.4, when DIN/!CONFIG is grounded*
- **IR** = FFFF

- **SM** = 8 # set the sleep mode of the module to synchronous cyclic
  sleep mode. (manual page 68)
- **SO** = 1 # set sleep options to Non-sleep coordinator (manual page 67)

### Diagnostics
#### useful diagnostic queries when connected to node
See manual pages 69 and 70.

Send the command ATSS. This will return a hex value. [Convert it to
binary](http://www.binaryhexconverter.com/hex-to-binary-converter)
and check which bits are true. If bit 1 is true, the xbee is acting as a
coordinator node.

#### getting xbee IDs
python3 -m hub.request_xbee_id
sleep 6
python3 -m hub.get_xbee_id


### Network Setup
1) Configure the hub
  a) power off all cells/hubs
  b) power on hub
  c) setup using above bits
  d) power down hub

2) Configure cell
  a) power off all cells/hubs
  b) power on cell
  c) setup using above bits
  d) power down cell 

Deployment Steps
1) Power on sleep coordinator
2) Power on each cell in range of sleep coordinator
3) Distribute cells, ensuring they remain in range of the coordinator
controlled mesh
