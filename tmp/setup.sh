#!/bin/sh

NUM_DEVS=${1:-100}

echo "creating $NUM_DEVS devices..."

systemctl stop NetworkManager

# mask the Dispatcher as well.
systemctl mask NetworkManager-dispatcher
systemctl stop NetworkManager-dispatcher

# cleanup from previous run
pkill -f 'dnsmasq.*172.16.1.1,172.16.20.1'
ip netns del T 2>/dev/null
ip link | sed -n 's/^[0-9]\+:.*\(t-[^@:]\+\)@.*/\1/p' | xargs -n 1 ip link del 2>/dev/null

ip netns add T
ip --netns T link add t-br0 type bridge
ip --netns T link set t-br0 type bridge stp_state 0
ip --netns T link set t-br0 up
ip --netns T addr add 172.16.0.1/16 dev t-br0
ip netns exec T dnsmasq --conf-file=/dev/null --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --listen-address=172.16.0.1 --dhcp-range=172.16.1.1,172.16.20.1,60 --no-ping &
for i in `seq 1 $NUM_DEVS`; do
  ip --netns T link add t-a$i type veth peer t-b$i
  ip --netns T link set t-a$i up
  ip --netns T link set t-b$i up master t-br0
done

cat <<EOF > /etc/NetworkManager/conf.d/99-xxcustom.conf
[main]
dhcp=internal
no-auto-default=*
dns=none
[device-99-my]
match-device=interface-name:t-a*
managed=1
[logging]
level=INFO
EOF

for i in `seq 1 $NUM_DEVS`; do
    ip --netns T link set t-a$i netns $$
    ip link set t-a$i up
done

systemctl start NetworkManager
sleep 10
