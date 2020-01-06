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

patch -f -p 1 --fuzz 0 --reject-file=- <<EOF
diff --git c/$FILENAME w/$FILENAME
index 7d0209629b93..9bccce89191a 100644
--- c/$FILENAME
+++ w/$FILENAME
@@ -272,31 +272,33 @@ def SetConnectivity(self, connectivity):
     self.SetProperty(MANAGER_OBJ, MANAGER_IFACE, 'Connectivity', dbus.UInt32(connectivity, variant_level=1))
 
 
 @dbus.service.method(MOCK_IFACE,
                      in_signature='ss', out_signature='')
 def SetDeviceActive(self, device_path, active_connection_path):
     dev_obj = dbusmock.get_object(device_path)
     dev_obj.Set(DEVICE_IFACE, 'ActiveConnection', dbus.ObjectPath(active_connection_path))
     old_state = dev_obj.Get(DEVICE_IFACE, 'State')
     dev_obj.Set(DEVICE_IFACE, 'State', dbus.UInt32(DeviceState.ACTIVATED))
+    dev_obj.Set(DEVICE_IFACE, 'StateReason', (dbus.UInt32(DeviceState.ACTIVATED), dbus.UInt32(0)))
 
     dev_obj.EmitSignal(DEVICE_IFACE, 'StateChanged', 'uuu', [dbus.UInt32(DeviceState.ACTIVATED), old_state, dbus.UInt32(1)])
 
 
 @dbus.service.method(MOCK_IFACE,
                      in_signature='s', out_signature='')
 def SetDeviceDisconnected(self, device_path):
     dev_obj = dbusmock.get_object(device_path)
     dev_obj.Set(DEVICE_IFACE, 'ActiveConnection', dbus.ObjectPath('/'))
     old_state = dev_obj.Get(DEVICE_IFACE, 'State')
     dev_obj.Set(DEVICE_IFACE, 'State', dbus.UInt32(DeviceState.DISCONNECTED))
+    dev_obj.Set(DEVICE_IFACE, 'StateReason', (dbus.UInt32(DeviceState.DISCONNECTED), dbus.UInt32(0)))
 
     dev_obj.EmitSignal(DEVICE_IFACE, 'StateChanged', 'uuu', [dbus.UInt32(DeviceState.DISCONNECTED), old_state, dbus.UInt32(1)])
 
 
 @dbus.service.method(MOCK_IFACE,
                      in_signature='ssi', out_signature='s')
 def AddEthernetDevice(self, device_name, iface_name, state):
     '''Add an ethernet device.
 
     You have to specify device_name, device interface name (e. g. eth0), and
EOF

done
