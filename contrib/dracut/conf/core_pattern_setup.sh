#!/bin/sh

echo "Setting core_pattern" 1>&2
mkdir -p /tmp/dumps/
echo "/tmp/dumps/dump_%e-%P-%u-%g-%s-%t-%c-%h" > /proc/sys/kernel/core_pattern
