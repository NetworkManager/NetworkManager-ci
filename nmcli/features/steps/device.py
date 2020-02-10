# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob

from steps import command_output, command_code, additional_sleep



@step(u'{action} all "{what}" devices')
def do_device_stuff(context, action, what):
    command_code(context, "for dev in $(nmcli device status | grep '%s' | awk {'print $1'}); do nmcli device %s $dev; done" % (what, action))


@step(u'Add a secondary address to device "{device}" within the same subnet')
def add_secondary_addr_same_subnet(context, device):
    from netaddr import IPNetwork
    primary_ipn = IPNetwork(command_output(context, "ip -4 a s %s | awk '/inet .*dynamic/ {print $2}'" % device))
    if str(primary_ipn.ip).split('.')[2] == str(primary_ipn.ip+1).split('.')[2]:
        secondary_ip = primary_ipn.ip+1
    else:
        secondary_ip = primary_ipn.ip-1
    assert command_code(context, 'ip addr add dev %s %s/%d' % (device, str(secondary_ip), primary_ipn.prefixlen)) == 0


@step(u'device "{device}" has DNS server "{dns}"')
def check_dns_domain(context, device, dns):
    try:
        context.execute_steps('* "DNS: %s\\r\\n" is visible with command "prepare/%s %s"' % (re.escape(dns), context.dns_script, device))
    except AssertionError:
        out = command_output(context, "prepare/%s %s" % (context.dns_script, device)).strip()
        raise AssertionError("Actual DNS configuration for %s is:\n%s\n" % (device, out))


@step(u'device "{device}" does not have DNS server "{dns}"')
def check_dns_domain(context, device, dns):
    try:
        context.execute_steps(u'''* "DNS: %s\\r\\n" is not visible with command "prepare/%s %s"''' % (re.escape(dns), context.dns_script, device))
    except AssertionError:
        out = command_output(context, "prepare/%s.py %s" % (context.dns_script, device)).strip()
        raise AssertionError("Actual DNS configuration for %s is:\n%s\n" % (device, out))


@step(u'device "{device}" has DNS domain "{domain}"')
@step(u'device "{device}" has DNS domain "{domain}" for "{kind}"')
def check_dns_domain(context, device, domain, kind="routing"):
    try:
        context.execute_steps(u'''* "Domain: \(%s\) %s\\r\\n" is visible with command "prepare/%s %s"''' % (kind, re.escape(domain), context.dns_script, device))
    except AssertionError:
        out = command_output(context, "prepare/%s %s" % (context.dns_script, device)).strip()
        raise AssertionError("Actual DNS configuration for %s is:\n%s\n" % (device, out))


@step(u'Create device "{dev}" in "{ns}" with address "{addr}"')
def create_device_in_ns(context, dev, ns, addr):
    command_code(context, 'ip -n %s link add %s type veth peer name %sp' % (ns, dev, dev))
    command_code(context, "ip -n %s link set %s up" % (ns, dev))
    command_code(context, "ip -n %s addr add %s dev %s" % (ns, addr, dev))
#    veth_to_delete = getattr(context, "veth_to_delete", [])
#    veth_to_delete += [dev, dev+"p"]
#    context.veth_to_delete = veth_to_delete


@step(u'device "{device}" does not have DNS domain "{domain}"')
@step(u'device "{device}" does not have DNS domain "{domain}" for "{kind}"')
def check_dns_domain(context, device, domain, kind="routing"):
    try:
        context.execute_steps(u'''* "Domain: \(%s\) %s\\r\\n" is not visible with command "prepare/%s %s"''' % (kind, re.escape(domain), context.dns_script, device))
    except AssertionError:
        out = command_output(context, "prepare/%s %s" % (context.dns_script, device)).strip()
        raise AssertionError("Actual DNS configuration for %s is:\n%s\n" % (device, out))


@step(u'Compare kernel and NM devices')
def compare_devices(context):
    # A tool that gets devices from Route Netlink & NetworkManager and
    # finds differencies (errors in NetworkManager external change tracking)
    #
    # Currently only takes master-slave relationships into account.
    # Could be easily extended...
    #
    # Lubomir Rintel <lrintel@redhat.com>

    from gi.repository import NM
    from pyroute2 import IPRoute

    def nm_devices():
        """
        Query devices from NetworkManager
        """

        client = NM.Client.new (None)

        devs = client.get_devices()
        devices = {}

        for c in devs:
            iface = c.get_iface()
            if iface:
                devices[c.get_iface()] = {}

        # Enslave devices
        for c in devs:
            typ = type(c).__name__

            if typ == 'DeviceBridge':
                slaves = c.get_slaves()
            elif typ == 'DeviceBond':
                slaves = c.get_slaves()
            elif typ == 'DeviceTeam':
                slaves = c.get_slaves()
            else:
                slaves = []

            for s in slaves:
                devices[s.get_iface()]['master'] = c.get_iface()

        return devices


    def rtnl_devices():
        """
        Query devices from route netlink
        """

        ip = IPRoute()
        devs = ip.get_links()
        ip.close()

        names = {}
        devices = {}

        for l in devs:
            names[l['index']] = l.get_attr('IFLA_IFNAME')

        for l in devs:
            master = l.get_attr('IFLA_MASTER')
            name = names[l['index']]

            devices[name] = {}
            if master:
                devices[name]['master'] = names[master]

        return devices

    def deep_compare(a_desc, a, b_desc, b):
        """
        Deeply compare structures
        """

        ret = True;

        a_type = type(a).__name__
        b_type = type(b).__name__

        if a_type != b_type:
            print ('%s is a %s whereas %s is a %s' % (a_desc, a_type,
                                                      b_desc, b_type))
            return False

        if a_type == 'dict':
            for a_key in a.keys():
                if a_key in b:
                    if not deep_compare(a_desc + '.' + a_key, a[a_key],
                                b_desc + '.' + a_key, b[a_key]):
                        ret = False
                else:
                    print ('%s does not have %s' % (b_desc, a_key))
                    ret = False

            for b_key in b.keys():
                if b_key not in a:
                    print ('%s does not have %s' % (a_desc, b_key))
                    ret = False
        else:
            if a != b:
                print ('%s == %s while %s == %s' % (a_desc, a,
                                                    b_desc, b))
                ret = False

        return ret

    assert deep_compare ('NM', nm_devices(), 'RTNL', rtnl_devices()), \
            "Kernel and NetworkManager's device lists are different"


@step(u'Connect device "{device}"')
def connect_device(context, device):
    cli = pexpect.spawn('nmcli device con %s' % device, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while connecting a device %s\n%s%s' % (device, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli device connect %s timed out (180s)' % device)


@step(u'Connect wifi device to "{network}" network')
def connect_wifi_device(context, network):
    cli = pexpect.spawn('nmcli device wifi connect "%s"' % network, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while connecting to network %s\n%s%s' % (network, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli device wifi connect ... timed out (180s)')


@step(u'Connect wifi device to "{network}" network with options "{options}"')
def connect_wifi_device_w_options(context, network, options):
    cli = pexpect.spawn('nmcli device wifi connect "%s" %s' % (network, options), timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while connecting to network %s\n%s%s' % (network, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli device wifi connect ... timed out (180s)')


@step(u'Note the "{prop}" property from ifconfig output for device "{device}"')
def note_print_property(context, prop, device):
    ifc = pexpect.spawn('ifconfig %s' % device, logfile=context.log, encoding='utf-8')
    ifc.expect('%s\s(\S+)' % prop)
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = ifc.match.group(1)


@step(u'Note MAC address output for device "{device}" via ethtool')
def note_mac_address(context, device):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = command_output(context, "ethtool -P %s |grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'" % device).strip()


@step(u'Note MAC address output for device "{device}" via ip command as "{index}"')
@step(u'Note MAC address output for device "{device}" via ip command')
def note_mac_address_ip(context, device, index=None):
    if call("ip a s %s |grep -q ether" %device, shell=True) == 0:
        mac = command_output(context, "ip link show %s | grep 'link/ether' | awk '{print $2}'" % device).strip()
    if call("ip a s %s |grep -q infiniband" %device, shell=True) == 0:
        ip_out = command_output(context, "ip link show %s | grep 'link/inf' | awk '{print $2}'" % device).strip()
        mac = ip_out.split()[-1]
        client_id = ""
        mac_split = mac.split(":")[-8:]
        for i in mac_split:
            if i == mac_split[-1]:
                client_id+=i
            else:
                client_id+=i+":"

        mac = client_id

    if index:
        if not hasattr(context, 'noted'):
            context.noted = {}
        context.noted[index] = mac
    else:
        if not hasattr(context, 'noted'):
            context.noted = {}
        context.noted['noted-value'] = mac
    print (mac)


@step(u'Global temporary ip is not based on mac of device "{dev}"')
def global_tem_address_check(context, dev):
    cmd = "ip a s %s" %dev
    mac = ""
    temp_ipv6 = ""
    ipv6 = ""
    for line in command_output(context,cmd).split('\n'):
        if line.find('brd ff:ff:ff:ff:ff:ff') != -1:
            mac = line.split()[1]
        if line.find('scope global temporary dynamic') != -1:
            temp_ipv6 = line.split()[1]
        if line.find('scope global dynamic') != -1:
            ipv6 = line.split()[1]

    assert temp_ipv6 != ipv6, 'IPV6 Address are similar!'
    temp_ipv6_end = temp_ipv6.split('/')[0].split(':')[-1]
    mac_end = mac.split(':')[-2]+mac.split(':')[-1]
    assert temp_ipv6_end != mac_end, 'Mac and tmp Ipv6 are similar in the end %s..%s'


@step(u'All ifaces but "{exclude_ifaces}" are not in state "{iface_state}"')
def check_ifaces_in_state(context, exclude_ifaces, iface_state):
    ex_ifaces = []
    for ex_iface in exclude_ifaces.split(','):
        ex_ifaces.append(ex_iface.strip())

    cmd = 'ip a s'
    if iface_state == "DOWN":
        cmd = cmd + "| grep -v NO-CARRIER"
    for ex_iface in ex_ifaces:
        cmd = cmd + " | grep -v " + str(ex_iface)

    context.execute_steps(u""" * "%s" is not visible with command "%s" """ % (iface_state, cmd))


@step(u'Disconnect device "{name}"')
def disconnect_connection(context, name):
    cli = pexpect.spawn('nmcli device disconnect %s' % name, logfile=context.log,  timeout=180, encoding='utf-8')

    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while disconnecting device %s\n%s%s' % (name, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli disconnect %s timed out (180s)' % name)


@step(u'Delete device "{device}"')
def delete_device(context, device):
    cli = pexpect.spawn('nmcli device delete %s' % device, logfile=context.log,  timeout=180, encoding='utf-8')

    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while deleting device %s\n%s%s' % (device, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli device delete %s timed out (180s)' % device)


@step(u'Rename device "{old_device}" to "{new_device}"')
def delete_device(context, old_device, new_device):
    command_code(context, "ip link set dev %s down" % old_device)
    command_code(context, "ip link set %s name %s" % (old_device, new_device))
    command_code(context, "ip link set dev %s ip" % old_device)


@step(u'vxlan device "{dev}" check for parent "{parent}"')
def vxlan_device_check(context, dev, parent):
    import dbus, sys

    bus = dbus.SystemBus()
    proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")


    devices = manager.GetDevices()
    assert devices, "Failed to find any vxlan interface"

    for d in devices:
        dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
        prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
        props = prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        if props['Interface'] != dev:
            continue

        vxlan = prop_iface.GetAll("org.freedesktop.NetworkManager.Device.Vxlan")

        assert vxlan['Id'] == 42, "bad id '%s'" % vxlan['Id']
        assert vxlan['Group'] == "239.1.1.1", "bad group '%s'" % vxlan['Group']

        # Get parent
        parent_proxy = bus.get_object("org.freedesktop.NetworkManager", vxlan['Parent'])
        parent_prop_iface = dbus.Interface(parent_proxy, "org.freedesktop.DBus.Properties")
        parent_props = parent_prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        assert parent_props['Interface'] == parent, "bad parent '%s'" % parent_props['Interface']

@step(u'vxlan device "{dev}" check for ports "{dst_port}, {src_min}, {src_max}"')
def vxlan_device_check_ports(context, dev, dst_port, src_min, src_max):
    import dbus, sys

    bus = dbus.SystemBus()
    proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")


    devices = manager.GetDevices()
    assert devices, "Failed to find any vxlan interface"

    for d in devices:
        dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
        prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
        props = prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        if props['Interface'] != dev:
            continue

        vxlan = prop_iface.GetAll("org.freedesktop.NetworkManager.Device.Vxlan")

        assert vxlan['SrcPortMin'] == src_min, "bad src port min '%s'" % vxlan['SrcPortMin']
        assert vxlan['SrcPortMax'] == src_max, "bad src port max '%s'" % vxlan['SrcPortMax']
        assert vxlan['DstPort'] == dst_port, "bad dst port '%s'" % vxlan['DstPort']


@step(u'Snapshot "{action}" for "{devices}"')
@step(u'Snapshot "{action}" for "{devices}" with timeout "{timeout}"')
@step(u'Snapshot for "{devices}" "{action}" device "{device}"')
def snapshot_action(context, action, devices, timeout=0, device=None):
    def initialize_manager_for_device(device):
        import dbus
        bus = dbus.SystemBus()
        # Get a proxy for the base NetworkManager object
        proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
        manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
        dpath = None
        # Find the device
        devices = manager.GetDevices()
        for d in devices:
            dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
            prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
            iface = prop_iface.Get("org.freedesktop.NetworkManager.Device", "Interface")
            if iface == device:
                dpath = d
                return manager, dpath
        if not dpath or not len(dpath):
            raise Exception("NetworkManager knows nothing about %s" % device)

    if not hasattr(context, 'checkpoints'):
        context.checkpoints = {}

    dpaths = []
    if devices == 'all':
        import dbus
        bus = dbus.SystemBus()
        # Get a proxy for the base NetworkManager object
        proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
        manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
    else:
        for device in devices.split(','):
            manager, dpath = initialize_manager_for_device(device)
            dpaths.append(dpath)

    if action == "create":
        print ("Create checkpoint for device(s) %s" % devices)
        context.checkpoints[devices] = manager.CheckpointCreate(dpaths,
                                      int(timeout),   # no rollback
                                      1)  # DESTROY_ALL
    if action == "revert":
        print ("Rollback checkpoint for device(s) %s" % devices)
        results = manager.CheckpointRollback(context.checkpoints[devices])
        for d in results:
            print ("  - device %s: result %u" % (d, results[d]))

    if action == "delete":
        print ("Destroy checkpoint for device(s) %s" % devices)
        manager.CheckpointDestroy(context.checkpoints[devices])

    if action == "does contain" or action == "does not contain":
        print ("Checking that device %s is %s in checkpoint for device(s) %s" % (device, action, devices))
        if device != "last":
            manager, dpath = initialize_manager_for_device(device)
            context.checkpoints_last_device = dpath
        else:
            dpath = context.checkpoints_last_device
        checkpoint_proxy = bus.get_object("org.freedesktop.NetworkManager", context.checkpoints[devices])
        prop = dbus.Interface(checkpoint_proxy, "org.freedesktop.DBus.Properties")
        checkpoint_devices = prop.Get("org.freedesktop.NetworkManager.Checkpoint", "Devices")
        if action == "does contain":
            assert dpath in checkpoint_devices, "Device %s is not in checkpoint for device(s) %s" % (device, devices)
        elif action == "does not contain":
            assert dpath not in checkpoint_devices, "Device %s is in checkpoint for device(s) %s" % (device, devices)


# syntax for property: prop1=val1,prop2=val2,...
#  where prop1 is list of indices of dbus LldpNeighbor object, delimited by ':'
#  empty index means search in all indices on this level of object
# use d-feet to see the structure of 'LldpNeighbors' object
# example: ":802-1-vlans::id=10" - search for all elements of 'LldpNeighbor' (it is an array),
#  pick index '802-1-vlans', then search there is some object with id equal to 10
# note: empty index is usefull to search in all elements of an array
@step(u'Check "{property}" in LldpNeighbors via DBus for device "{device}"')
def check_lldp_neighbours(context, property, device):
    import dbus
    bus = dbus.SystemBus()
    path = '/org/freedesktop/NetworkManager'
    nm_proxy = bus.get_object("org.freedesktop.NetworkManager", path)
    nm = dbus.Interface(nm_proxy, "org.freedesktop.NetworkManager")
    dev_path = nm.GetDeviceByIpIface(device)

    dev_proxy = bus.get_object("org.freedesktop.NetworkManager", dev_path)
    dev = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
    lldp_neighbors = dev.Get('org.freedesktop.NetworkManager.Device', 'LldpNeighbors')

    # recursively checks the queue of indices on object, when que empty compare to value
    # if index is empty, search every index of object on that level
    def check_obj(idx, obj, val, queue):
        # stop recursion, if queue is empty
        if len(queue)==0:
            val_obj = obj[idx]
            if val_obj != val:
                bad_vals.append(str(val_obj))
                return False
            return True
        # if the index is empty, use 'for' loop on object
        if idx == '':
            ret = False
            for o in obj:
                ret = ret or check_obj(queue[0], o, val, queue[1:])
            return ret
        # otherwise access index on object and call recursively
        else:
            return check_obj(queue[0], obj[idx], val, queue[1:])

    for prop in property.split(','):
        path, val = prop.split("=")
        val = eval(val)
        queue = path.split(":")
        bad_vals = []
        assert check_obj(queue[0], lldp_neighbors, val, queue[1:]), "value '%s' for property '%s' not found in ['%s']" % (val, path, "','".join(bad_vals))


@step(u'Check "{flag}" band cap flag set if device supported')
def band_cap_set_if_supported(context, flag, device='wlan0'):
    try:
        if flag == 'NM_802_11_DEVICE_CAP_FREQ_2GHZ':
            context.execute_steps(u'''* "2... MHz" is visible with command "nmcli -f FREQ d w"''')
        elif flag == 'NM_802_11_DEVICE_CAP_FREQ_5GHZ':
            context.execute_steps(u'''* "5... MHz" is visible with command "nmcli -f FREQ d w"''')
    except AssertionError:
        assert not flag_cap_set(context, flag=flag, device=device, giveexception=False), "The flag is set, though we don't see any such network!"
        return
    assert flag_cap_set(context, flag=flag, device=device, giveexception=False), "Device supports the band, but the flag is unset!"


@step(u'Flag "{flag}" is {n} set in WirelessCapabilites')
@step(u'Flag "{flag}" is set in WirelessCapabilites')
def flag_cap_set(context, flag, n=None, device='wlan0', giveexception=True):

    def get_device_dbus_path(device):
        import dbus
        bus = dbus.SystemBus()
        proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
        manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
        dpath = None
        devices = manager.GetDevices()
        for d in devices:
            dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
            prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
            iface = prop_iface.Get("org.freedesktop.NetworkManager.Device", "Interface")
            if iface == device:
                dpath = d
                break
        if not dpath or not len(dpath):
            raise Exception("NetworkManager knows nothing about %s" % device)
        return dpath

    wcaps = {}
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_WEP40'] = 0x1
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_WEP104'] = 0x2
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_TKIP'] = 0x4
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_CCMP'] = 0x8
    wcaps['NM_802_11_DEVICE_CAP_WPA'] = 0x10
    wcaps['NM_802_11_DEVICE_CAP_RSN'] = 0x20
    wcaps['NM_802_11_DEVICE_CAP_AP'] = 0x40
    wcaps['NM_802_11_DEVICE_CAP_ADHOC'] = 0x80
    wcaps['NM_802_11_DEVICE_CAP_FREQ_VALID'] = 0x100
    wcaps['NM_802_11_DEVICE_CAP_FREQ_2GHZ'] = 0x200
    wcaps['NM_802_11_DEVICE_CAP_FREQ_5GHZ'] = 0x400

    path = get_device_dbus_path(device)
    cmd = '''dbus-send --system --print-reply \
            --dest=org.freedesktop.NetworkManager \
            %s \
            org.freedesktop.DBus.Properties.Get \
            string:"org.freedesktop.NetworkManager.Device.Wireless" \
            string:"WirelessCapabilities" | grep variant | awk '{print $3}' ''' % path
    ret = int(check_output(cmd, shell=True).decode('utf-8', 'ignore').strip())

    if n is None:
        if wcaps[flag] & ret == wcaps[flag]:
            return True
        elif giveexception:
            raise AssertionError("The flag is unset! WirelessCapabilities: %d" % ret)
        else:
            return False
    else:
        if wcaps[flag] & ret == wcaps[flag]:
            raise AssertionError("The flag is set! WirelessCapabilities: %d" % ret)


@step(u'Force renew IPv6 for "{device}"')
def force_renew_ipv6(context, device):
    mac = command_output(context, "ip a s %s |grep fe80 |awk '{print $2}'" % device).strip()
    command_code(context, "ip -6 addr flush dev %s" % (device))
    command_code(context, "ip addr add %s dev %s" % (mac, device))


@step(u'"{typ}" lifetimes are slightly smaller than "{valid_lft}" and "{pref_lft}" for device "{device}"')
def correct_lifetime(context, typ, valid_lft, pref_lft, device):
    if typ == 'IPv6':
        inet = "inet6"
    if typ == 'IPv4':
        inet = "inet"

    valid_cmd = "ip a s '%s' |grep -A 1 -w '%s'| grep -A 1 -w 'scope global' |grep valid_lft |awk '{print $2}'" % (device, inet)
    pref_cmd  = "ip a s '%s' |grep -A 1 -w '%s'| grep -A 1 -w 'scope global' |grep valid_lft |awk '{print $4}'" % (device, inet)

    valid = command_output(context, valid_cmd).split()[0]
    pref = command_output(context, pref_cmd).split()[0]

    valid = valid.strip()
    valid = valid.replace('sec', '')
    pref = pref.strip()
    pref = pref.replace('sec', '')

    assert int(valid) < int(valid_lft) and int(valid) >= int(valid_lft)-50, "valid: %s, not close to: %s" % (valid, valid_lft)
    assert int(pref) < int(pref_lft) and int(pref) >= int(pref_lft)-50, "pref: %s, not close to : %s" % (pref, pref_lft)


@step(u'Check ipv6 connectivity is stable on assuming connection profile "{profile}" for device "{device}"')
def check_ipv6_connectivity_on_assumal(context, profile, device):
    context.nm_restarted = True
    address = command_output(context, "ip -6 a s %s | grep dynamic | awk '{print $2; exit}' | cut -d '/' -f1" % device)
    assert command_code(context, 'systemctl stop NetworkManager.service') == 0
    assert command_code(context, "sed -i 's/UUID=/#UUID=/' /etc/sysconfig/network-scripts/ifcfg-%s" % profile)  == 0
    ping = pexpect.spawn('ping6 %s -i 0.2 -c 50' % address, logfile=context.log, encoding='utf-8')
    sleep(1)
    assert command_code(context, 'systemctl start NetworkManager.service') == 0
    sleep(12)
    r = ping.expect(["0% packet loss", pexpect.EOF, pexpect.TIMEOUT])
    if r != 0:
        raise Exception('Had packet loss on pinging the address!')
