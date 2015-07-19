#!/bin/bash

# This script is responsible for keeping the 3g modem's connection alive
# It pings google.com once per minute
# If google.com is unavailable, it resets the modem and dials t-mobile 

INTERVAL=60

while true
do
  # TODO vnstat -i ppp0 --oneline
  if ! ping -c 1 google.com; then
    # internet is down, reset and dial
    exec reset_modem.sh
    exec wvdial
  fi
  sleep $INTERVAL 
done

