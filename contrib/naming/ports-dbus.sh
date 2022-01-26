#!/bin/sh

dev="$1"
port="$2"

dev_path=$(nmcli -g general.dbus-path device show $dev)
port_path=$(nmcli -g general.dbus-path device show $port)
dbus_ports=$(busctl get-property org.freedesktop.NetworkManager $dev_path org.freedesktop.NetworkManager.Device Ports)

if [ "$dbus_ports" != "ao 1 \"${port_path}\"" ]; then
    echo "*** Error: wrong dbus port"
    exit 1
fi

echo "dbus ports:$dbus_ports"
