import glob
import os
import re
import shutil
import subprocess
import time

import nmci


def dump_status(context, when, fail_only=False):
    nm_running = (
        nmci.process.systemctl("status NetworkManager", do_embed=False).returncode == 0
    )

    cmds = [
        'date "+%Y%m%d-%H%M%S.%N"',
        "NetworkManager --version",
        "ip addr",
        "ip -4 route",
        "ip -6 route",
        "nft list ruleset",
    ]
    if nm_running:
        cmds += [
            nmci.process.WithShell("hostnamectl 2>&1"),
            "nmcli -f ALL g",
            "nmcli -f ALL c",
            "nmcli -f ALL d",
            "nmcli -f ALL d w l",
            "NetworkManager --print-config",
            "cat /etc/resolv.conf",
            # use '[d]hclient' to not match grep command itself.
            nmci.process.WithShell("ps aux | grep -w '[d]hclient'"),
        ]

    headings = {len(cmds): "\nVeth setup network namespace and DHCP server state:\n"}

    if nm_running and os.path.isfile("/tmp/nm_veth_configured"):
        cmds += [
            "ip -n vethsetup addr",
            "ip -n vethsetup -4 route",
            "ip -n vethsetup -6 route",
            nmci.process.WithShell("ps aux | grep -w '[d]nsmasq'"),
            "ip netns exec vethsetup nft list ruleset",
        ]

    named_nss = nmci.ip.netns_list()

    # vethsetup is handled separately
    named_nss = [n for n in named_nss if n != "vethsetup"]

    if len(named_nss) > 0:
        add_to_heading = "\nStatus of other named network namespaces:\n"
        for ns in sorted(named_nss):
            heading = f"{add_to_heading}\nnetwork namespace {ns}:"
            if len(add_to_heading) > 0:
                add_to_heading = ""
            headings[len(cmds)] = heading
            cmds += [
                f"ip -n {ns} a",
                f"ip -n {ns} -4 r",
                f"ip -n {ns} -6 r",
                f"ip netns exec {ns} nft list ruleset",
            ]

    procs = [nmci.process.Popen(c, stderr=subprocess.DEVNULL) for c in cmds]

    timeout = nmci.util.start_timeout(20)
    while timeout.loop_sleep(0.05):
        any_pending = False
        for proc in procs:
            if proc.read_and_poll() is None:
                if timeout.was_expired:
                    proc.terminate_and_wait(timeout_before_kill=3)
                else:
                    any_pending = True
        if not any_pending or timeout.was_expired:
            break

    msg = ""
    for i in range(len(procs)):
        proc = procs[i]
        if i in headings.keys():
            msg = f"{msg}\n{headings[i]}"
        msg += f"\n--- {proc.argv} ---\n"
        msg += proc.stdout.decode("utf-8", errors="replace")
    if timeout.was_expired:
        msg += "\n\nWARNING: timeout expired waiting for processes. Processes were terminated."

    nmci.embed.embed_data("Status " + when, msg, fail_only=fail_only)

    # Always include memory stats
    if context.nm_pid is not None:
        try:
            kb = nmci.nmutil.nm_size_kb()
        except nmci.util.ExpectedException as e:
            msg = f"Daemon memory consumption: unknown ({e})\n"
        else:
            msg = f"Daemon memory consumption: {kb} KiB\n"
        if (
            os.path.isfile("/etc/systemd/system/NetworkManager.service")
            and nmci.process.run_code(
                "grep -q valgrind /etc/systemd/system/NetworkManager.service",
                do_embed=False,
            )
            == 0
        ):
            result = nmci.process.run(
                "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                shell=True,
                do_embed=False,
            )
            msg += result.stdout
        nmci.embed.embed_data("Memory use " + when, msg)


def restore_connections(context):
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
    restore_testeth0(context)


def manage_veths(context):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"'
        nmci.util.file_set_content("/etc/udev/rules.d/88-veths-eth.rules", [rule])
        nmci.util.update_udevadm()


def unmanage_veths(context):
    nmci.process.run_stdout("rm -f /etc/udev/rules.d/88-veths-*.rules")
    nmci.util.update_udevadm()


def check_vethsetup(context):
    print("Regenerate veth setup")
    nmci.process.run_stdout(
        "sh prepare/vethsetup.sh check", ignore_stderr=True, timeout=60
    )
    context.nm_pid = nmci.nmutil.nm_pid()


def teardown_testveth(context, ns):
    print(f"Removing the setup in {ns} namespace")
    if os.path.isfile(f"/tmp/{ns}.pid"):
        nmci.process.run_stdout(f"ip netns exec {ns} pkill -SIGCONT -F /tmp/{ns}.pid")
        nmci.process.run_stdout(f"ip netns exec {ns} pkill -F /tmp/{ns}.pid")
    device = ns.split("_")[0]
    print(device)
    nmci.process.run(f"pkill -F /var/run/dhclient-{device}.pid", ignore_stderr=True)
    # We need to reset this too
    nmci.process.run_stdout("sysctl net.ipv6.conf.all.forwarding=0")

    unmanage_veths(context)
    nmci.nmutil.reload_NM_service()


def reset_hwaddr_nmcli(context, ifname):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        hwaddr = nmci.process.run_stdout(f"ethtool -P {ifname}").split()[2]
        nmci.process.run_stdout(f"ip link set {ifname} address {hwaddr}")
    nmci.process.run_stdout(f"ip link set {ifname} up")


def restore_testeth0(context):
    print("* restoring testeth0")
    nmci.process.nmcli_force("con delete testeth0")

    if not os.path.isfile("/tmp/nm_plugin_keyfiles"):
        # defaults to ifcfg files (RHELs)
        nmci.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0",
            shell=True,
        )
    else:
        # defaults to keyfiles (F33+)
        nmci.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/NetworkManager/system-connections/testeth0.nmconnection",
            shell=True,
        )

    time.sleep(1)
    nmci.process.nmcli("con reload")
    time.sleep(1)
    nmci.process.nmcli("con up testeth0")
    time.sleep(2)


def wait_for_testeth0(context):
    print("* waiting for testeth0 to connect")
    if "testeth0" not in nmci.process.nmcli("connection"):
        restore_testeth0(context)

    if "testeth0" not in nmci.process.nmcli("connection show -a"):
        print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
        if "(connected)" in nmci.process.nmcli("device show eth0"):
            profile = nmci.process.nmcli("-g GENERAL.DEVICE device show eth0").strip()
            print(
                f" ** device eth0 is connected to {profile}, let's disconnect it first"
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
            restore_testeth0(context)
        if counter == 60:
            assert False, "Testeth0 cannot be upped..this is wrong"
        testeth0 = nmci.process.nmcli("con show testeth0")
    print(" ** we do have IPv4 complete")
