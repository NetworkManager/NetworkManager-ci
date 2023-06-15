#!/bin/bash
#
# Usage: $0 NUM_IF NUM_AD TIMEOUT
#     NUM_IF: how many devices are used
#     NUM_AD: how many addresses per device are used
#     TIMEOUT: after how many seconds should the loop be breaked

# Clean up
cleanup () {
    ip netns del ${NAME}ev
    rm -f .tmp/${NAME}-events.pid
    exit 0
}

if [ $# -eq 4 ]
then
    NAME=$1
    NUM_IF=$2
    NUM_AD=$3
    TIMEOUT=$4
else
    cleanup
fi

# Set up
touch .tmp/${NAME}-events.pid || exit 1
echo $$ > .tmp/${NAME}-events.pid || exit 1
ip netns add ${NAME}ev

trap cleanup SIGTERM

for i in $(seq 0 $NUM_IF); do
    echo "link add ${NAME}$i type veth peer NAME ${NAME}$i netns ${NAME}ev"
    echo "link set ${NAME}$i up"
done | ip -b -

for i in $(seq 0 $NUM_IF); do
    echo "link set ${NAME}$i up"
done | ip -n ${NAME}ev -b -

# Run loop

ADDR_ADD=$(for i in $(seq 0 $NUM_IF); do for j in $(seq 1 $NUM_AD); do echo "addr add dev ${NAME}$i 172.32.${i}.${j}/24"; done; done )
ADDR_DEL=$(for i in $(seq 0 $NUM_IF); do for j in $(seq 1 $NUM_AD); do echo "addr del dev ${NAME}$i 172.32.${i}.${j}/24"; done; done )

STARTTIME=$(date -u +%s)
ENDTIME=$(($STARTTIME + $TIMEOUT))

while [ $(date -u +%s) -le $ENDTIME ]; do
    printf "$ADDR_ADD" | sort -R | ip -b -
    printf "$ADDR_DEL" | sort -R | ip -b -
done

cleanup
