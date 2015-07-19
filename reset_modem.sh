#!/bin/bash

# This script resets the modem by rebinding the USB bus to the OS. This
# resets the entire USB stack, power cycling the modem.

# Use mode switch to ensure the OS recognizes our device as a modem and
# not a disk. You can ensure this worked by making sure that a wwan0
# interface is listed for the modem in ifconfig.
echo "ensuring the OS recognizes the USB device as a modem and not a disk"
usb_modeswitch \
	--no-inquire \
	--verbose \
	--sysmode \
	-s 20 \
	--default-vendor 12d1 \
	--default-product 1446 \
	-c conf/usb_modeswitch.conf
sleep 5

# Reset the usb bus.
#
# The format for specifying bus bus path is: <bus>-<rank>.<port>.
# If port is omitted all ports are reset for the given bus+rank.
#
# Below we are writing 1-1 to the `unbind` and `bind` descriptors to
# reset the one and only USB bus.
echo "unbinding"
echo "1-1" | tee /sys/bus/usb/drivers/usb/unbind
sleep 5
echo "binding"
echo "1-1" | tee /sys/bus/usb/drivers/usb/bind
sleep 15
