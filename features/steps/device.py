# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import json
import pexpect
import shlex
import time
from behave import step, given

import nmci
from nmci.util import NM


@step('{action} all "{what}" devices')
def do_device_stuff(context, action, what):
    context.command_code(
        "for dev in $(nmcli device status | grep '%s' | awk {'print $1'}); do nmcli device %s $dev; done"
        % (what, action)
    )


@step('Add a secondary address to device "{device}" within the same subnet')
def add_secondary_addr_same_subnet(context, device):
    from netaddr import IPNetwork

    primary_ipn = IPNetwork(
        context.command_output(
            "ip -4 a s %s | awk '/inet .*dynamic/ {print $2}'" % device
        )
    )
    if str(primary_ipn.ip).split(".")[2] == str(primary_ipn.ip + 1).split(".")[2]:
        secondary_ip = primary_ipn.ip + 1
    else:
        secondary_ip = primary_ipn.ip - 1
    context.process.run_stdout(
        f"ip addr add dev {device} {secondary_ip}/{primary_ipn.prefixlen}"
    )


def dns_check(dns_plugin, device, kind, arg, has):
    info = None
    ex = None
    attempt = 0
    while attempt < 8:
        try:
            info = nmci.misc.get_dns_info(dns_plugin, ifname=device)

            assert info["default_route"] is not None or dns_plugin == "systemd-resolved"

            if kind == "dns":
                xhas = arg in info["dns"]
                if has == xhas:
                    return
            elif kind in ["domain-search", "domain-routing"]:
                xkind = kind[7:]
                xhas = any((arg == d[0] and xkind == d[1] for d in info["domains"]))
                if has == xhas:
                    return
            elif kind == "domain":
                xhas = any((arg == d[0] for d in info["domains"]))
                if has == xhas:
                    return
            elif kind == "default-route":
                if arg == "no":
                    if info["default_route"] in [None, False] and not any(
                        (d[0] == "." for d in info["domains"])
                    ):
                        return
                elif arg == "default":
                    if info["default_route"] in [None, True] and not any(
                        (d[0] == "." for d in info["domains"])
                    ):
                        return
                elif arg in ["routing", "search"]:
                    if info["default_route"] in [None, True] and any(
                        (d[0] == "." and d[1] == arg for d in info["domains"])
                    ):
                        return
                else:
                    raise ValueError(f"unsupported default-route kind {arg}")
            else:
                raise ValueError(f'unsupported kind "{kind}"')
        except Exception as e:
            ex = e
        attempt += 1
        time.sleep(1)

    assert False, (
        'DNS %s "%s" is unexpectedly %sset for device "%s" (plugin %s) (settings: %s) (exception: %s)'
        % (kind, arg, "not " if has else "", device, dns_plugin, info, ex)
    )


@step('device "{device}" has DNS server "{dns}"')
def dns_check_dns_has(context, device, dns):
    dns_check(context.dns_plugin, device, "dns", dns, True)


@step('device "{device}" does not have DNS server "{dns}"')
def dns_check_dns_not(context, device, dns):
    dns_check(context.dns_plugin, device, "dns", dns, False)


@step('device "{device}" has DNS domain "{domain}"')
@step('device "{device}" has DNS domain "{domain}" for "{kind}"')
def dns_check_domain_has(context, device, domain, kind="domain-routing"):
    dns_check(context.dns_plugin, device, kind, domain, True)


@step('device "{device}" does not have DNS domain "{domain}"')
@step('device "{device}" does not have DNS domain "{domain}" for "{kind}"')
def dns_check_domain_not(context, device, domain, kind="domain"):
    dns_check(context.dns_plugin, device, kind, domain, False)


@step('device "{device}" has "{what}" DNS default-route')
def dns_check_default_route_has(context, device, what):
    assert what in ["no", "default", "routing", "search"]
    dns_check(context.dns_plugin, device, "default-route", what, None)


@step("Compare kernel and NM master-slave devices")
def compare_devices(context):
    # A tool that gets devices from Route Netlink & NetworkManager and
    # finds differencies (errors in NetworkManager external change tracking)
    #
    # Currently only takes master-slave relationships into account.
    # Could be easily extended...
    #
    # Lubomir Rintel <lrintel@redhat.com>

    from gi.repository import NM  # pylint: disable=import-error
    from pyroute2 import IPRoute  # pylint: disable=import-error

    def nm_devices():
        """
        Query devices from NetworkManager
        """

        client = NM.Client.new(None)

        devs = client.get_devices()
        devices = {}

        # Enslave devices
        for c in devs:
            typ = type(c).__name__

            if typ in ["DeviceBridge", "DeviceBond", "DeviceTeam"]:
                for s in c.get_slaves():
                    devices[s.get_iface()] = {"master": c.get_iface()}

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
            names[l["index"]] = l.get_attr("IFLA_IFNAME")

        for l in devs:
            master = l.get_attr("IFLA_MASTER")
            name = names[l["index"]]

            if master:
                devices[name] = {"master": names[master]}

        return devices

    def deep_compare(a_desc, a, b_desc, b):
        """
        Deeply compare structures
        """

        ret = True

        a_type = type(a).__name__
        b_type = type(b).__name__

        if a_type != b_type:
            print("%s is a %s whereas %s is a %s" % (a_desc, a_type, b_desc, b_type))
            return False

        if a_type == "dict":
            for a_key in a.keys():
                if a_key in b:
                    if not deep_compare(
                        a_desc + "." + a_key, a[a_key], b_desc + "." + a_key, b[a_key]
                    ):
                        ret = False
                else:
                    print("%s does not have %s: %s" % (b_desc, a_key, str(a[a_key])))
                    ret = False

            for b_key in b.keys():
                if b_key not in a:
                    print("%s does not have %s: %s" % (a_desc, b_key, str(b[b_key])))
                    ret = False
        else:
            if a != b:
                print("%s == %s while %s == %s" % (a_desc, a, b_desc, b))
                ret = False

        return ret

    assert deep_compare(
        "NM", nm_devices(), "RTNL", rtnl_devices()
    ), "Kernel and NetworkManager's device lists are different"


@step('Connect device "{device}"')
def connect_device(context, device):
    cli = context.pexpect_spawn("nmcli device con %s" % device, timeout=180)
    r = cli.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, "Got an Error while connecting a device %s\n%s%s" % (
        device,
        cli.after,
        cli.buffer,
    )
    assert r != 1, "nmcli device connect %s timed out (180s)" % device


@step('Connect wifi device to "{network}" network')
def connect_wifi_device(context, network):
    cli = context.pexpect_spawn('nmcli device wifi connect "%s"' % network, timeout=180)
    r = cli.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, "Got an Error while connecting to network %s\n%s%s" % (
        network,
        cli.after,
        cli.buffer,
    )
    assert r != 1, "nmcli device wifi connect ... timed out (180s)"


@step('Connect wifi device to "{network}" network with options "{options}"')
def connect_wifi_device_w_options(context, network, options):
    cli = context.pexpect_spawn(
        'nmcli device wifi connect "%s" %s' % (network, options), timeout=180
    )
    r = cli.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, "Got an Error while connecting to network %s\n%s%s" % (
        network,
        cli.after,
        cli.buffer,
    )
    assert r != 1, "nmcli device wifi connect ... timed out (180s)"


@step('Note MAC address output for device "{device}" via ethtool')
def note_mac_address(context, device):
    if not hasattr(context, "noted"):
        context.noted = {}
    context.noted["noted-value"] = context.command_output(
        "ethtool -P %s |grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'" % device
    ).strip()


@step('Note MAC address output for device "{device}" via ip command as "{index}"')
@step('Note MAC address output for device "{device}" via ip command')
def note_mac_address_ip(context, device, index=None):
    if context.command_code("ip a s %s |grep -q ether" % device, shell=True) == 0:
        mac = context.command_output(
            "ip link show %s | grep 'link/ether' | awk '{print $2}'" % device
        ).strip()
    if context.command_code("ip a s %s |grep -q infiniband" % device, shell=True) == 0:
        ip_out = context.command_output(
            "ip link show %s | grep 'link/inf' | awk '{print $2}'" % device
        ).strip()
        mac = ip_out.split()[-1]
        client_id = ""
        mac_split = mac.split(":")[-8:]
        for i in mac_split:
            if i == mac_split[-1]:
                client_id += i
            else:
                client_id += i + ":"

        mac = client_id

    if index:
        if not hasattr(context, "noted"):
            context.noted = {}
        context.noted[index] = mac
    else:
        if not hasattr(context, "noted"):
            context.noted = {}
        context.noted["noted-value"] = mac
    print(mac)


@step('Global temporary ip is not based on mac of device "{dev}"')
def global_tem_address_check(context, dev):
    cmd = "ip a s %s" % dev
    mac = ""
    temp_ipv6 = ""
    ipv6 = ""
    for line in context.command_output(cmd).split("\n"):
        if line.find("brd ff:ff:ff:ff:ff:ff") != -1:
            mac = line.split()[1]
        if line.find("scope global temporary dynamic") != -1:
            temp_ipv6 = line.split()[1]
        if line.find("scope global dynamic") != -1:
            ipv6 = line.split()[1]

    assert temp_ipv6 != ipv6, "IPV6 Address are similar!"
    temp_ipv6_end = temp_ipv6.split("/")[0].split(":")[-1]
    mac_end = mac.split(":")[-2] + mac.split(":")[-1]
    assert temp_ipv6_end != mac_end, "Mac and tmp Ipv6 are similar in the end %s..%s"


@step('All ifaces but "{exclude_ifaces}" are not in state "{iface_state}"')
def check_ifaces_in_state(context, exclude_ifaces, iface_state):
    ex_ifaces = []
    for ex_iface in exclude_ifaces.split(","):
        ex_ifaces.append(ex_iface.strip())

    cmd = "ip a s"
    if iface_state == "DOWN":
        cmd = cmd + "| grep -v NO-CARRIER"
    for ex_iface in ex_ifaces:
        cmd = cmd + " | grep -v " + str(ex_iface)

    context.execute_steps(
        """ * "%s" is not visible with command "%s" """ % (iface_state, cmd)
    )


@step('Disconnect device "{name}"')
def disconnect_connection(context, name):
    cli = context.pexpect_spawn("nmcli device disconnect %s" % name)

    r = cli.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, "Got an Error while disconnecting device %s\n%s%s" % (
        name,
        cli.after,
        cli.buffer,
    )
    assert r != 1, "nmcli disconnect %s timed out (180s)" % name


@step('Delete device "{device}"')
def delete_device(context, device):
    cli = context.pexpect_spawn("nmcli device delete %s" % device)

    r = cli.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, "Got an Error while deleting device %s\n%s%s" % (
        device,
        cli.after,
        cli.buffer,
    )
    assert r != 1, "nmcli device delete %s timed out (180s)" % device


@step('vxlan device "{dev}" check for parent "{parent}"')
def vxlan_device_check(context, dev, parent):
    import dbus, sys

    bus = dbus.SystemBus()
    proxy = bus.get_object(
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
    )
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")

    devices = manager.GetDevices()
    assert devices, "Failed to find any vxlan interface"

    for d in devices:
        dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
        prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
        props = prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        if props["Interface"] != dev:
            continue

        vxlan = prop_iface.GetAll("org.freedesktop.NetworkManager.Device.Vxlan")

        assert vxlan["Id"] == 42, "bad id '%s'" % vxlan["Id"]
        assert vxlan["Group"] == "239.1.1.1", "bad group '%s'" % vxlan["Group"]

        # Get parent
        parent_proxy = bus.get_object("org.freedesktop.NetworkManager", vxlan["Parent"])
        parent_prop_iface = dbus.Interface(
            parent_proxy, "org.freedesktop.DBus.Properties"
        )
        parent_props = parent_prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        assert parent_props["Interface"] == parent, (
            "bad parent '%s'" % parent_props["Interface"]
        )


@step('vxlan device "{dev}" check for ports "{dst_port}, {src_min}, {src_max}"')
def vxlan_device_check_ports(context, dev, dst_port, src_min, src_max):
    import dbus, sys

    bus = dbus.SystemBus()
    proxy = bus.get_object(
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
    )
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")

    devices = manager.GetDevices()
    assert devices, "Failed to find any vxlan interface"

    for d in devices:
        dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
        prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
        props = prop_iface.GetAll("org.freedesktop.NetworkManager.Device")

        if props["Interface"] != dev:
            continue

        vxlan = prop_iface.GetAll("org.freedesktop.NetworkManager.Device.Vxlan")

        assert vxlan["SrcPortMin"] == src_min, (
            "bad src port min '%s'" % vxlan["SrcPortMin"]
        )
        assert vxlan["SrcPortMax"] == src_max, (
            "bad src port max '%s'" % vxlan["SrcPortMax"]
        )
        assert vxlan["DstPort"] == dst_port, "bad dst port '%s'" % vxlan["DstPort"]


@step('Snapshot "{action}" for "{devices}"')
@step('Snapshot "{action}" for "{devices}" with timeout "{timeout}"')
@step('Snapshot for "{devices}" "{action}" device "{device}"')
def snapshot_action(context, action, devices, timeout=0, device=None):
    # We need to sleep here a bit to have all expected profiles ready
    time.sleep(0.25)

    def initialize_manager_for_device(device):
        import dbus

        bus = dbus.SystemBus()
        # Get a proxy for the base NetworkManager object
        proxy = bus.get_object(
            "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
        )
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
        assert dpath and len(dpath), "NetworkManager knows nothing about %s" % device

    if not hasattr(context, "checkpoints"):
        context.checkpoints = {}

    dpaths = []
    if devices == "all":
        import dbus

        bus = dbus.SystemBus()
        # Get a proxy for the base NetworkManager object
        proxy = bus.get_object(
            "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
        )
        manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
    else:
        for device in devices.split(","):
            manager, dpath = initialize_manager_for_device(device)
            dpaths.append(dpath)

    if action == "create":
        print("Create checkpoint for device(s) %s" % devices)
        context.checkpoints[devices] = manager.CheckpointCreate(
            dpaths, int(timeout), 1  # no rollback
        )  # DESTROY_ALL
    if action == "revert":
        print("Rollback checkpoint for device(s) %s" % devices)
        results = manager.CheckpointRollback(context.checkpoints[devices])
        for d in results:
            print("  - device %s: result %u" % (d, results[d]))

    if action == "delete":
        print("Destroy checkpoint for device(s) %s" % devices)
        manager.CheckpointDestroy(context.checkpoints[devices])

    if action == "does contain" or action == "does not contain":
        print(
            "Checking that device %s is %s in checkpoint for device(s) %s"
            % (device, action, devices)
        )
        if device != "last":
            manager, dpath = initialize_manager_for_device(device)
            context.checkpoints_last_device = dpath
        else:
            dpath = context.checkpoints_last_device
        checkpoint_proxy = bus.get_object(
            "org.freedesktop.NetworkManager", context.checkpoints[devices]
        )
        prop = dbus.Interface(checkpoint_proxy, "org.freedesktop.DBus.Properties")
        checkpoint_devices = prop.Get(
            "org.freedesktop.NetworkManager.Checkpoint", "Devices"
        )
        if action == "does contain":
            assert (
                dpath in checkpoint_devices
            ), "Device %s is not in checkpoint for device(s) %s" % (device, devices)
        elif action == "does not contain":
            assert (
                dpath not in checkpoint_devices
            ), "Device %s is in checkpoint for device(s) %s" % (device, devices)


# syntax for property: prop1=val1,prop2=val2,...
#  where prop1 is list of indices of dbus LldpNeighbor object, delimited by ':'
#  empty index means search in all indices on this level of object
# use d-feet to see the structure of 'LldpNeighbors' object
# example: ":802-1-vlans::id=10" - search for all elements of 'LldpNeighbor' (it is an array),
#  pick index '802-1-vlans', then search there is some object with id equal to 10
# note: empty index is usefull to search in all elements of an array
@step('Check "{property}" in LldpNeighbors via DBus for device "{device}"')
def check_lldp_neighbours(context, property, device):
    import dbus

    bus = dbus.SystemBus()
    path = "/org/freedesktop/NetworkManager"
    nm_proxy = bus.get_object("org.freedesktop.NetworkManager", path)
    nm = dbus.Interface(nm_proxy, "org.freedesktop.NetworkManager")
    dev_path = nm.GetDeviceByIpIface(device)

    dev_proxy = bus.get_object("org.freedesktop.NetworkManager", dev_path)
    dev = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
    lldp_neighbors = dev.Get("org.freedesktop.NetworkManager.Device", "LldpNeighbors")

    # recursively checks the queue of indices on object, when que empty compare to value
    # if index is empty, search every index of object on that level
    def check_obj(idx, obj, val, queue):
        # stop recursion, if queue is empty
        if len(queue) == 0:
            val_obj = obj[idx]
            if val_obj != val:
                bad_vals.append(str(val_obj))
                return False
            return True
        # if the index is empty, use 'for' loop on object
        if idx == "":
            ret = False
            for o in obj:
                ret = ret or check_obj(queue[0], o, val, queue[1:])
            return ret
        # otherwise access index on object and call recursively
        else:
            return check_obj(queue[0], obj[idx], val, queue[1:])

    for prop in property.split(","):
        path, val = prop.split("=")
        val = eval(val)
        queue = path.split(":")
        bad_vals = []
        assert check_obj(
            queue[0], lldp_neighbors, val, queue[1:]
        ), "value '%s' for property '%s' not found in ['%s']" % (
            val,
            path,
            "','".join(bad_vals),
        )


@step('Check "{flag}" band cap flag set if device supported')
def band_cap_set_if_supported(context, flag, device="wlan0"):
    try:
        if flag == "NM_802_11_DEVICE_CAP_FREQ_2GHZ":
            context.execute_steps(
                '''* "2... MHz" is visible with command "nmcli -f FREQ d w"'''
            )
        elif flag == "NM_802_11_DEVICE_CAP_FREQ_5GHZ":
            context.execute_steps(
                '''* "5... MHz" is visible with command "nmcli -f FREQ d w"'''
            )
    except AssertionError:
        assert not flag_cap_set(
            context, flag=flag, device=device, giveexception=False
        ), "The flag is set, though we don't see any such network!"
        return
    assert flag_cap_set(
        context, flag=flag, device=device, giveexception=False
    ), "Device supports the band, but the flag is unset!"


@given('Flag "{flag}" is {n} set in WirelessCapabilites')
@given('Flag "{flag}" is set in WirelessCapabilites')
def given_flag_cap_set(context, flag, n=None):
    step_name = context.current_step.name
    try:
        context.execute_steps(f"When {step_name}")
    except AssertionError as ae:
        if flag in [
            "NM_802_11_DEVICE_CAP_AP",
            "NM_802_11_DEVICE_CAP_ADHOC",
            "NM_802_11_DEVICE_CAP_FREQ_5GHZ",
        ]:
            context.cext.skip(f"Skipping, mismatched flag {flag}")
        else:
            raise ae


@step('Flag "{flag}" is {n} set in WirelessCapabilites')
@step('Flag "{flag}" is set in WirelessCapabilites')
def flag_cap_set(context, flag, n=None, device="wlan0", giveexception=True):
    def get_device_dbus_path(device):
        import dbus

        bus = dbus.SystemBus()
        proxy = bus.get_object(
            "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
        )
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
        assert dpath and len(dpath), "NetworkManager knows nothing about %s" % device
        return dpath

    wcaps = {
        "NM_802_11_DEVICE_CAP_CIPHER_WEP40": 0x1,
        "NM_802_11_DEVICE_CAP_CIPHER_WEP104": 0x2,
        "NM_802_11_DEVICE_CAP_CIPHER_TKIP": 0x4,
        "NM_802_11_DEVICE_CAP_CIPHER_CCMP": 0x8,
        "NM_802_11_DEVICE_CAP_WPA": 0x10,
        "NM_802_11_DEVICE_CAP_RSN": 0x20,
        "NM_802_11_DEVICE_CAP_AP": 0x40,
        "NM_802_11_DEVICE_CAP_ADHOC": 0x80,
        "NM_802_11_DEVICE_CAP_FREQ_VALID": 0x100,
        "NM_802_11_DEVICE_CAP_FREQ_2GHZ": 0x200,
        "NM_802_11_DEVICE_CAP_FREQ_5GHZ": 0x400,
    }

    path = get_device_dbus_path(device)
    cmd = (
        """dbus-send --system --print-reply \
            --dest=org.freedesktop.NetworkManager \
            %s \
            org.freedesktop.DBus.Properties.Get \
            string:"org.freedesktop.NetworkManager.Device.Wireless" \
            string:"WirelessCapabilities" | grep variant | awk '{print $3}' """
        % path
    )
    ret = int(context.command_output(cmd).strip())

    expect = n is None
    result = wcaps[flag] & ret == wcaps[flag]
    if giveexception:
        assert (
            expect == result
        ), f"The flag {flag} is mismatched! WirelessCapabilities: {ret}"
    else:
        return expect == result


@step('Force renew IPv6 for "{device}"')
def force_renew_ipv6(context, device):
    mac = context.command_output(
        "ip a s %s |grep fe80 |awk '{print $2}'" % device
    ).strip()
    context.command_code("ip -6 addr flush dev %s" % (device))
    context.command_code("ip addr add %s dev %s" % (mac, device))


@step(
    '"{typ}" lifetimes are slightly smaller than "{valid_lft}" and "{pref_lft}" for device "{device}"'
)
def correct_lifetime(context, typ, valid_lft, pref_lft, device):
    if typ == "IPv6":
        inet = "inet6"
    if typ == "IPv4":
        inet = "inet"

    valid_cmd = (
        "ip a s '%s' |grep -A 1 -w '%s'| grep -A 1 -w 'scope global' |grep valid_lft |awk '{print $2}'"
        % (device, inet)
    )
    pref_cmd = (
        "ip a s '%s' |grep -A 1 -w '%s'| grep -A 1 -w 'scope global' |grep valid_lft |awk '{print $4}'"
        % (device, inet)
    )

    valid = context.command_output(valid_cmd).split()[0]
    pref = context.command_output(pref_cmd).split()[0]

    valid = valid.strip()
    valid = valid.replace("sec", "")
    pref = pref.strip()
    pref = pref.replace("sec", "")

    assert (
        int(valid) < int(valid_lft) and int(valid) >= int(valid_lft) - 50
    ), "valid: %s, not close to: %s" % (valid, valid_lft)
    assert (
        int(pref) < int(pref_lft) and int(pref) >= int(pref_lft) - 50
    ), "pref: %s, not close to : %s" % (pref, pref_lft)


@step(
    'Check ipv6 connectivity is stable on assuming connection profile "{profile}" for device "{device}"'
)
def check_ipv6_connectivity_on_assumal(context, profile, device):
    address = context.command_output(
        "ip -6 a s %s | grep dynamic | awk '{print $2; exit}' | cut -d '/' -f1" % device
    )
    nmci.nmutil.stop_NM_service()
    assert (
        context.command_code(
            "sed -i 's/UUID=/#UUID=/' /etc/sysconfig/network-scripts/ifcfg-%s" % profile
        )
        == 0
    )
    ping = context.pexpect_spawn("ping6 %s -i 0.2 -c 50" % address)
    time.sleep(1)
    assert context.command_code("systemctl start NetworkManager.service") == 0
    time.sleep(12)
    r = ping.expect(["0% packet loss", pexpect.EOF, pexpect.TIMEOUT])
    assert r == 0, "Had packet loss on pinging the address!"


@step('Check "{device}" device LLDP status flag via libnm')
def device_lldp_status_libnm(context, device):
    nm_client = NM.Client.new(None)
    nm_device = nm_client.get_device_by_iface(device)
    assert nm_device is not None, f"device '{device}' not found"
    nm_device_flags = nm_device.get_interface_flags()
    assert nm_device_flags & NM.DeviceInterfaceFlags.LLDP_CLIENT_ENABLED, (
        f"LLDP status flag not set:\nDevice Flags: {nm_device_flags:032b}\n"
        f"LLDP flag:    {NM.DeviceInterfaceFlags.LLDP_CLIENT_ENABLED:032b}"
    )


@step('Activate "{device_num}" devices in "{sec_high}" seconds')
@step('Activate "{device_num}" devices in "{sec_low}" to "{sec_high}" seconds')
def activate_devices_check(context, device_num, sec_high, sec_low=0):
    nmci.cleanup.add_callback(
        callback=lambda: nmci.process.systemctl(
            ["unmask", "NetworkManager-dispatcher"]
        ),
        name="unmask NM-dispatcher",
        priority=nmci.Cleanup.PRIORITY_NM_SERVICE_RESTART,
    )
    # setup
    nmci.nmutil.stop_NM_service()
    nmci.process.systemctl(["mask", "NetworkManager-dispatcher"])
    nmci.process.systemctl(["stop", "NetworkManager-dispatcher"])
    nmci.process.run(
        f"cd contrib/gi; ./setup.sh {device_num}",
        shell=True,
        ignore_stderr=True,
        timeout=60,
    )
    nmci.nmutil.start_NM_service()

    out = context.command_output(f"cd contrib/gi; python3 activate.py {device_num}")
    # activate.py calls setup.sh which restarts NM
    context.nm_pid = nmci.nmutil.wait_for_nm_pid()
    completed_lines = [line for line in out.split("\n") if "Completed in " in line]
    assert len(
        completed_lines
    ), f"Unexpected output, did not find 'Completed in ' line:\n{out}"
    completed_line = completed_lines[0]
    sec_meas = float(completed_line.split("Completed in ")[1].split(" ")[0])
    nmci.embed.embed_data(
        f"Activation time: {sec_meas}s",
        f"speed factor: {context.machine_speed_factor}",
    )
    high_limit = float(sec_high) * context.machine_speed_factor
    low_limit = float(sec_low) * context.machine_speed_factor
    assert sec_meas <= high_limit and sec_meas >= low_limit, (
        f"Lasted {sec_meas} seconds, which is not in {context.machine_speed_factor} "
        f"times scaled range: [{low_limit};{high_limit}]."
    )


def get_routes_count(context, device=None, ip_version=4):
    if device:
        device = f"dev {device}"
    else:
        device = ""
    return len(
        context.command_output(f"ip -{ip_version} route show {device}").split("\n")
    )


@step(
    'There are "{cmp}" "{routes_count}" IP version "{ip_version}" routes for device "{device}"'
)
@step(
    'There are "{cmp}" "{routes_count}" IP version "{ip_version}" routes for device "{device}" in "{seconds}" seconds'
)
def check_route_count(context, cmp, routes_count, ip_version, device, seconds=1):
    routes_count = int(routes_count)
    xtimeout = nmci.util.start_timeout(seconds)
    while xtimeout.loop_sleep(0.2):
        routes_now = get_routes_count(context, device, ip_version)

        if cmp == "at least":
            if routes_now >= routes_count:
                return True
        elif cmp == "at most":
            if routes_now <= routes_count:
                return True
        elif cmp == "exactly":
            if routes_now == routes_count:
                return True

    assert False, f"There were {routes_now} routes found."


@step('Cleanup device "{iface}"')
def cleanup_connection(context, iface):
    nmci.cleanup.add_iface(iface)


@step('Create "{typ}" device named "{name}"')
@step('Create "{typ}" device named "{name}" with options "{options}"')
@step('Create "{typ}" device named "{name}" in namespace "{namespace}"')
@step(
    'Create "{typ}" device named "{name}" in namespace "{namespace}" with options "{options}"'
)
@step(
    'Create "{typ}" device named "{name}" in namespace "{namespace}" with ifindex "{ifindex}" and options "{options}"'
)
def add_device(context, typ, name, namespace=None, ifindex=None, options=""):
    nmci.cleanup.add_iface(name)
    if ifindex == "None":
        ifindex = None
    if not ifindex:
        # Make sure the new device gets the hightest ifindex of all links.
        # This is what generally happens when adding a new link and some tests
        # (such as @bond_slaves_ordering_by_ifindex) rely on this; but it's
        # not guarranteed and doesn't happen when the device is moved across
        # namespaces and got a lower ifindex in the old namespace.
        ifindices = (
            link["ifindex"]
            for link in nmci.ip.link_show_all(namespace=nmci.ip.IP_NAMESPACE_ALL)
        )

        # Bump, so that we don't try to use the same ifindex even before the
        # result of previous link add is visible. Bump by two, because a veth
        # pair might be created.
        ifindex = max(context.ifindex, *ifindices) + 3
        context.ifindex = ifindex
    else:
        ifindex = int(ifindex)

    nmci.ip.link_add(
        name,
        typ,
        *shlex.split(options),
        namespace=namespace,
        ifindex=ifindex,
        wait_for_device=5,
    )


@step('Create "{count}" "{typ}" devices named "{name}"')
def add_multiple_devices(context, typ, name, count):
    # see add_device()
    ifindices = (
        link["ifindex"]
        for link in nmci.ip.link_show_all(namespace=nmci.ip.IP_NAMESPACE_ALL)
    )
    _increment_size = 2

    if typ == "veth":
        nmci.veth.manage_device(f"{name}_[0-9]*", name)
        _increment_size = 3
    # see add_device()
    context.ifindex = max(context.ifindex, *ifindices)

    names = [f"{name}_{i}" for i in range(int(count))]
    nmci.cleanup.add_iface(names, op="delete")
    for _name in names:
        context.ifindex += _increment_size
        options = f"peer name {_name}p" if typ == "veth" else ""
        nmci.ip.link_add(
            _name,
            typ,
            *shlex.split(options),
            wait_for_device=False,
            ifindex=context.ifindex,
        )


@step('Add namespace "{name}"')
@step('Add namespace "{name}" with options "{options}"')
def add_namespace(context, name, options=""):
    nmci.cleanup.add_namespace(name, teardown=False)
    nmci.process.run(f"ip netns add {name} {options}")


@step('Cleanup namespace "{name}"')
def cleanup_ns(context, name):
    nmci.cleanup.add_namespace(name)


@step('Rename device "{orig_name}" to "{new_name}"')
def rename_device(context, orig_name, new_name):

    # Rename interface back in cleanup
    nmci.cleanup.add_NM_service("restart")
    nmci.cleanup.add_callback(
        callback=lambda: nmci.ip.link_set(ifname=orig_name, up=True),
        name=f"link-up: {orig_name}",
        unique_tag=(orig_name, True),
    )
    nmci.cleanup.add_callback(
        callback=lambda: nmci.ip.link_set(ifname=new_name, name=orig_name),
        name=f"link-rename: {new_name} -> {orig_name}",
        unique_tag=(new_name, orig_name),
    )
    nmci.cleanup.add_callback(
        callback=lambda: nmci.ip.link_set(ifname=new_name, up=False),
        name=f"link-down: {new_name}",
        unique_tag=(new_name, False),
    )

    nmci.ip.link_set(ifname=orig_name, up=False)
    nmci.ip.link_set(ifname=orig_name, name=new_name)
    nmci.ip.link_set(ifname=new_name, up=True)
