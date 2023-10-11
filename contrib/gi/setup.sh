#!/bin/sh

NUM_DEVS=${1:-100}

echo "creating $NUM_DEVS devices..."
DHCP_NUM=34
NUM_NS=$(($NUM_DEVS/$DHCP_NUM+1))
echo "creating $NUM_NS namespaces..."

# cleanup from previous run
pkill dhcpd
ip link | sed -n 's/^[0-9]\+:.*\(t-[^@:]\+\)@.*/\1/p' | xargs -n 1 ip link del 2>/dev/null
for i in $(seq 1 20); do
    ip netns del $i 2>&1 1>/dev/null
done

START=1
END=$DHCP_NUM

for ns in $(seq 1 $((NUM_NS))); do
    echo "START.. $START"
    echo "END... $END"
    # If we are over required devs now we are all done
    if [ $START -gt $NUM_DEVS ]; then
        echo "All done"
        break
    fi
    echo "Creating namespace $ns"
    # Create a sinhle namespace and a bridge inside
    ip netns add $ns
    ip --netns $ns link add t-br0 type bridge
    ip --netns $ns link set t-br0 type bridge stp_state 0
    ip --netns $ns link set t-br0 up
    ip --netns $ns addr add 173.16.$ns.1/24 dev t-br0

    # We might be over total wanted nuber of devs
    if [ $END -gt $NUM_DEVS ]; then
        echo "We are over $NUM_DEVS"
        END=$NUM_DEVS
    fi

    for i in $(seq $START $END); do
        echo "Creating device $i"
        ip link add t-a$i type veth peer t-b$i
        ip link set t-a$i up
        ip link set t-b$i up
        ip link set t-b$i netns $ns
        ip --netns $ns link set t-b$i up master t-br0
    done

    # Create a lease file and start dhcpd server
    touch /tmp/dhcpd$ns.lease
    echo "starting dhcpd"
    cat > /tmp/dhcpd$ns.conf <<EOF
default-lease-time 60;
max-lease-time 120;
subnet 173.16.$ns.0 netmask 255.255.255.0 {
       range 173.16.$ns.2 173.16.$ns.254;
       option routers 173.16.$ns.1;
       option domain-name "voko";
       option domain-name-servers 173.16.$ns.1;
}
EOF
    ip netns exec $ns nice -n -10 dhcpd -4 -cf /tmp/dhcpd$ns.conf -pf /tmp/dhcpd"$ns"_perf.pid -lf /tmp/dhcpd$ns.lease &

    START=$(($START+$DHCP_NUM))
    END=$(($END+$DHCP_NUM))
done

