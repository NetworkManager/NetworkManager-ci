#!/bin/sh

echo "Setting core_pattern" 1>&2
mkdir -p /run/dumps/
echo "/run/dumps/dump_%e-%P-%u-%g-%s-%t-%c-%h" > /proc/sys/kernel/core_pattern
