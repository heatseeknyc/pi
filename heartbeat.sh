
while [ "$xbee_id" == "" ]; do
    python3 -m hub.request_xbee_id
    echo 'waiting for xbee id to appear in db...'
    sleep 3
    xbee_id=$(python3 -m hub.get_xbee_id)
done
echo "xbee id is $xbee_id"

pi_id=$(awk '/^Serial\t/ { print $3 }' /proc/cpuinfo)
echo "π id is $pi_id"

python3 -m hub.request_sleep_period  # refresh db for good measure
sleep 3

while true; do
    for _ in $(seq 60); do  # check for new settings every 10 seconds, for up to 10 minutes
        sleep_period=$(python3 -m hub.get_sleep_period)
        port=$(supervisorctl tail ssh | awk '/^Allocated port / { print $3 }' | tail -1)
        [[ "$sleep_period" != "$old_sleep_period" || "$port" != "$old_port" ]] && break
        sleep 10
    done
    # settings have changed or 10 minutes have passed, so time to send a heartbeat:

    # TODO also send $(vnstat -i ppp0 --oneline)
    disk_free=$(df | grep '/dev/root' | awk '{print $4}')
    uptime=$(awk '{print $1}' /proc/uptime)
    version=$(git describe --tags --always)
    data="pi=$pi_id&sp=$sleep_period&free=$disk_free&up=$uptime&v=$version&port=$port"
    url="http://relay.heatseek.org/hubs/$xbee_id"
    echo "putting $data at $url"
    if curl --silent --show-error --fail --request PUT --data "$data" "$url"; then
        echo  # server response often has no newline
        old_port="$port"
        old_sleep_period="$sleep_period"
    else
        echo 'failed to post. waiting to retry...'
        sleep 10
    fi
done
