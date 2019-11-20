#!/bin/bash

# python-dbusmock had issue https://github.com/martinpitt/python-dbusmock/pull/55
# patch the installed version (if necessary).

cd /

for FILENAME in usr/local/lib/python*/site-packages/dbusmock/templates/networkmanager.py ; do

patch -f -p 1 --fuzz 0 --reject-file=- <<EOF
diff --git c/$FILENAME w/$FILENAME
index ad0676c754ed..e711c7193733 100644
--- c/$FILENAME
+++ w/$FILENAME
@@ -314,20 +314,21 @@ def AddEthernetDevice(self, device_name, iface_name, state):
                    'HwAddress': dbus.String('78:DD:08:D2:3D:43'),
                    'PermHwAddress': dbus.String('78:DD:08:D2:3D:43'),
                    'Speed': dbus.UInt32(0)}
     self.AddObject(path,
                    'org.freedesktop.NetworkManager.Device.Wired',
                    wired_props,
                    [])
 
     props = {'DeviceType': dbus.UInt32(1),
              'State': dbus.UInt32(state),
+             'StateReason': (dbus.UInt32(state), dbus.UInt32(0)),
              'Interface': iface_name,
              'ActiveConnection': dbus.ObjectPath('/'),
              'AvailableConnections': dbus.Array([], signature='o'),
              'AutoConnect': False,
              'Managed': True,
              'Driver': 'dbusmock',
              'IpInterface': ''}
 
     obj = dbusmock.get_object(path)
     obj.AddProperties(DEVICE_IFACE, props)
@@ -382,20 +383,21 @@ def AddWiFiDevice(self, device_name, iface_name, state):
     dev_obj.access_points = []
     dev_obj.AddProperties(DEVICE_IFACE,
                           {
                               'ActiveConnection': dbus.ObjectPath('/'),
                               'AvailableConnections': dbus.Array([], signature='o'),
                               'AutoConnect': False,
                               'Managed': True,
                               'Driver': 'dbusmock',
                               'DeviceType': dbus.UInt32(2),
                               'State': dbus.UInt32(state),
+                              'StateReason': (dbus.UInt32(state), dbus.UInt32(0)),
                               'Interface': iface_name,
                               'IpInterface': iface_name,
                           })
 
     self.object_manager_emit_added(path)
 
     NM = dbusmock.get_object(MANAGER_OBJ)
     devices = NM.Get(MANAGER_IFACE, 'Devices')
     devices.append(path)
     NM.Set(MANAGER_IFACE, 'Devices', devices)
EOF

done
