#!/bin/bash
#
# Usage: $0 NUM_IF NUM_AD TIMEOUT
#     NUM_IF: how many devices are used
#     NUM_AD: how many addresses per device are used
#     TIMEOUT: after how many seconds should the loop be breaked

# Clean up
cleanup () {
    ip netns del nll3ev
    rm -f .tmp/nll3-events.pid
    exit 0
}

if [ $# -eq 3 ]
then
    NUM_IF=$1
    NUM_AD=$2
    TIMEOUT=$3
else
    cleanup
fi

# Set up
touch .tmp/nll3-events.pid || exit 1
echo $$ > .tmp/nll3-events.pid || exit 1
ip netns add nll3ev

trap cleanup SIGTERM

for i in $(seq 0 $NUM_IF); do
    echo "link add nll3_$i type veth peer name nll3_$i netns nll3ev"
    echo "link set nll3_$i up"
done | ip -b -

for i in $(seq 0 $NUM_IF); do
    echo "link set nll3_$i up"
done | ip -n nll3ev -b -

# Run loop

ADDR_ADD=$(for i in $(seq 0 $NUM_IF); do for j in $(seq 1 $NUM_AD); do echo "addr add dev nll3_$i 172.32.${i}.${j}/24"; done; done )
ADDR_DEL=$(for i in $(seq 0 $NUM_IF); do for j in $(seq 1 $NUM_AD); do echo "addr del dev nll3_$i 172.32.${i}.${j}/24"; done; done )

STARTTIME=$(date -u +%s)
ENDTIME=$(($STARTTIME + $TIMEOUT))

while [ $(date -u +%s) -le $ENDTIME ]; do
    printf "$ADDR_ADD" | sort -R | ip -b -
    printf "$ADDR_DEL" | sort -R | ip -b -
    sleep 0.1
done

cleanup
