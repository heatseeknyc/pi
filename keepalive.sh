
while true; do
    if ! ping -c 1 http://relay.heatseek.org; then
        if ! ping -c 1 google.com; then
            if (( ++failures >= 1000 )); then  # every 17 hours
                echo "$failures failures, killing usb."
                echo 0 > /sys/devices/platform/soc/20980000.usb/buspower
                sleep 10
                echo "rebooting."
                shutdown -r now
            elif (( ++failures % 10  == 0 )); then  # every 10 minutes
                echo "$failures failures, killing wvdial."
                killall wvdial
            fi
        fi
    else
        failures=0  # all is well
    fi
    sleep 60
done
