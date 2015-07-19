#!/bin/bash

# This script tells the relay this hub is online

function detect_xbee_id {
  # try to read XBee ID every 6 seconds for up to a minute
  for _ in $(seq 10)
  do
    # query SH and SL. receiver.py should receive the response and write to db:
    # (thus note that even if id is already in db, this refreshes it)
    python3 -m hub.request_xbee_id
    sleep 6
    XBEE_ID=$(python3 -m hub.get_xbee_id)

    if [ "$XBEE_ID" != "" ]; then break; fi
  done
}

function detect_port {
  # watch for new tunnel port
  NEW_PORT=$(supervisorctl tail ssh | awk '/^Allocated port / { print $3 }' | tail -1)
  if [ "$NEW_PORT" != "$PORT" ]; then 
    echo "port change from $PORT to $NEW_PORT detected"
  fi
  PORT=$NEW_PORT
}

function notify_relay {
  echo "posting hub=$PI_ID&xbee=$XBEE_ID&port=$PORT..."
  curl -s -d "hub=$PI_ID" -d "xbee=$XBEE_ID" -d "port=$PORT" http://relay.heatseeknyc.com/hubs
}

PI_ID=$(python3 -m hub.get_pi_id)
PORT=""
NEW_PORT=""
XBEE_ID=""

# Send heartbeat every 10 minutes
while true
do
  detect_xbee_id
  detect_port
  notify_relay
  sleep 600
done
