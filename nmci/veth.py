import os
import shutil
import time

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _Veth:
    def restore_connections(self):
        """
        Delete all custom devices besides eth/lo/orig, and recreate testeth connection profiles.
        """
        print("* recreate all connections")
        conns = nmci.process.nmcli("-g NAME connection show").strip().split("\n")
        nmci.process.nmcli_force(["con", "del"] + conns)
        devs = [
            d
            for d in nmci.process.nmcli("-g DEVICE device").strip().split("\n")
            if not d.startswith("eth") and d != "lo" and not d.startswith("orig")
        ]
        for d in devs:
            nmci.process.nmcli_force(["dev", "del", d])
        for X in range(1, 11):
            nmci.process.nmcli(
                f"connection add type ethernet con-name testeth{X} ifname eth{X} autoconnect no"
            )
        self.restore_testeth0()

    def manage_device(self, device, rule_name=None):
        """
        Set device mode to 'managed'.

        :param device: name of the device
        :type device: str
        :param rule_name: name of the custom udev rule, defaults to None
        :type rule_name: str, optional
        """
        rule_name = rule_name or device
        rule_file = f"/etc/udev/rules.d/88-veth-{rule_name}.rules"
        if not os.path.isfile(rule_file):
            rule = (
                'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="%s*", ENV{NM_UNMANAGED}="0"'
                % device
            )
            nmci.util.file_set_content(rule_file, [rule])
            nmci.util.update_udevadm()
            nmci.cleanup.add_udev_rule(rule_file)

    def manage_veths(self):
        """
        Set the mode to 'managed' for all veth devices with names accepted by the regex :code:`eth[0-9]*[0-9]?`.
        """
        if not os.path.isfile("/tmp/nm_veth_configured"):
            rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"'
            nmci.util.file_set_content("/etc/udev/rules.d/88-veths-eth.rules", [rule])
            nmci.util.update_udevadm()

    def unmanage_veths(self):
        """
        Removes the :code:`88-veths-*` udev rule, which sets the mode to "managed"
        for all veth devices with names accepted by the regex :code:`eth[0-9]*[0-9]?`.
        """
        nmci.process.run_stdout("rm -f /etc/udev/rules.d/88-veths-*.rules")
        nmci.util.update_udevadm()

    def check_vethsetup(self):
        """Re-run the veth setup while validating its correct execution."""
        print("Regenerate veth setup")
        try:
            nmci.process.run_stdout(
                "sh prepare/vethsetup.sh check", ignore_stderr=True, timeout=60
            )
        except Exception as e:
            nmci.util.file_set_content("/tmp/nm_veth_configured")
            raise e
        nmci.cext.context.nm_pid = nmci.nmutil.nm_pid()

    def teardown_testveth(self, ns):
        """
        Remove the testveth setup in a given namespace.

        :param ns: namespace identifier
        :type ns: str
        """
        print(f"Removing the setup in {ns} namespace")
        if os.path.isfile(f"/tmp/{ns}.pid"):
            nmci.process.run_stdout(
                f"ip netns exec {ns} pkill -SIGCONT -F /tmp/{ns}.pid"
            )
            nmci.process.run_stdout(f"ip netns exec {ns} pkill -F /tmp/{ns}.pid")
        device = ns.split("_")[0]
        print(device)
        nmci.process.run(f"pkill -F /var/run/dhclient-{device}.pid", ignore_stderr=True)
        # We need to reset this too
        nmci.process.run_stdout("sysctl net.ipv6.conf.all.forwarding=0")

        self.unmanage_veths()
        nmci.nmutil.reload_NM_service()

    def reset_hwaddr_nmcli(self, ifname):
        """
        Reset the link-local address of a given interface.

        :param ifname: name of the device
        :type ifname: str
        """
        if not os.path.isfile("/tmp/nm_veth_configured"):
            if os.path.isfile("/tmp/nm_dcb_inf_wol_sriov_configured"):
                if nmci.process.run(f"ethtool -P {ifname}", ignore_stderr=True) != 0:
                    return True
            hwaddr = nmci.process.run_stdout(f"ethtool -P {ifname}").split()[2]
            if hwaddr != "not":
                # "Permanent address: not set" means there's no permanent address
                nmci.process.run_stdout(f"ip link set {ifname} address {hwaddr}")
        nmci.process.run_stdout(f"ip link set {ifname} up")

    def restore_testeth0(self):
        """
        Restore the testeth0 configuration.
        """
        print("* restoring testeth0")
        nmci.process.nmcli_force("con delete testeth0")

        if not os.path.isfile("/tmp/nm_plugin"):
            raise Exception(f"Invalid /tmp/nm_plugin: File not found")

        with open("/tmp/nm_plugin", "r") as f:
            plugin = f.read()

        if "ifcfg" in plugin:
            # defaults to ifcfg files (RHELs)
            shutil.copy2(
                "/tmp/testeth0", "/etc/sysconfig/network-scripts/ifcfg-testeth0"
            )
        elif "keyfile" in plugin:
            # defaults to keyfiles (F33+)
            shutil.copy2(
                "/tmp/testeth0",
                "/etc/NetworkManager/system-connections/testeth0.nmconnection",
            )
        else:
            raise Exception(f"Invalid /tmp/nm_plugin: {plugin}")

        time.sleep(1)
        nmci.process.nmcli("con reload")
        time.sleep(1)
        nmci.process.nmcli("con up testeth0")
        time.sleep(2)

    def wait_for_testeth0(self):
        """
        Wait for the testeth0 connection to sucessfully activate from multiple states.

        Possible states:
        - If it does not exist, restore it.
        - If it is not running, activate it.
        - If it does not have ipv4 addr/gateway/dns assigned, wait for the assignment.
        """
        print("* waiting for testeth0 to connect")
        if "testeth0" not in nmci.process.nmcli("connection"):
            self.restore_testeth0()

        if "testeth0" not in nmci.process.nmcli("connection show -a"):
            print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
            if "(connected)" in nmci.process.nmcli("device show eth0"):
                profile = nmci.process.nmcli(
                    "-g GENERAL.CONNECTION device show eth0"
                ).strip()
                print(
                    f" ** device eth0 is connected to '{profile}', let's disconnect it first"
                )
                nmci.process.nmcli_force("dev disconnect eth0")
            nmci.process.nmcli("con up testeth0")

        counter = 0
        # We need to check for all 3 items to have working connection out
        testeth0 = nmci.process.nmcli("con show testeth0")
        while (
            "IP4.ADDRESS" not in testeth0
            or "IP4.GATEWAY" not in testeth0
            or "IP4.DNS" not in testeth0
        ):
            time.sleep(1)
            print(
                f" ** {counter}: we don't have IPv4 (address, default route or dns) complete"
            )
            counter += 1
            if counter == 20:
                self.restore_testeth0()
            if counter == 60:
                assert False, "Testeth0 cannot be upped..this is wrong"
            testeth0 = nmci.process.nmcli("con show testeth0")
        print(" ** we do have IPv4 complete")


_module = _Veth()
