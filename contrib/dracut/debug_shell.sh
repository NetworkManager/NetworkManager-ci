#!/bin/bash

tail -f /tmp/dracut_boot.log &
while read line; do
    echo "$line" | timeout 1 tee /tmp/dracut_input > /dev/null
done

kill $!