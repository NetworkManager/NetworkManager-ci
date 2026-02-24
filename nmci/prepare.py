import glob
import os
import time
import shutil
import re

import nmci


def setup_libreswan(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    """
    Setup Libreswan for a given mode and DH group.

    :param context: behave context
    :type context: behave.runner.Context
    :param mode: mode of the connection
    :type mode: str
    :param dh_group: DH group
    :type dh_group: str
    :param phase1_al: phase1 algorithm, defaults to "aes"
    :type phase1_al: str, optional
    :param phase2_al: phase2 algorithm, defaults to None
    :type phase2_al: str, optional
    """
    RC = nmci.process.run_code(
        f"MODE={mode} bash prepare/libreswan.sh",
        shell=True,
        ignore_stderr=True,
        timeout=60,
    )
    if RC != 0:
        teardown_libreswan(context)
        assert False, "Libreswan setup failed"


def teardown_libreswan(context):
    """
    Teardown Libreswan.

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.process.run_stdout("bash prepare/libreswan.sh teardown", ignore_stderr=True)
    print("Attach Libreswan logs")
    journal_log = nmci.misc.journal_show(
        syslog_identifier="pluto",
        cursor=context.log_cursor,
        journal_args="-o cat",
    )
    nmci.embed.embed_data("Libreswan Pluto Journal", journal_log)

    conf = nmci.util.file_get_content_simple("/var/ipsec/connection.conf")
    nmci.embed.embed_data("Libreswan Config", conf)


def setup_openvpn(context, tags):
    """
    Setup OpenVPN server and client for a given mode and DH group.

    :param context: behave context
    :type context: behave.runner.Context
    :param tags: list of tags
    :type tags: list
    :return: OpenVPN server process
    :rtype: pexpect.spawn
    """
    path = "%s/contrib/openvpn" % os.getcwd()
    samples = glob.glob(os.path.abspath(path))[0]
    nmci.process.run_stdout(f"chcon -R system_u:object_r:usr_t:s0 {samples}")
    conf = [
        "# OpenVPN configuration for client testing",
        "mode server",
        "tls-server",
        "port 1194",
        "proto udp",
        "dev tun",
        "persist-key",
        "persist-tun",
        "tun-mtu 1400",
        f"ca {samples}/sample-keys/ca.crt",
        f"cert {samples}/sample-keys/server.crt",
        f"key {samples}/sample-keys/server.key",
        f"dh {samples}/sample-keys/dh2048.pem",
    ]
    if "openvpn6" not in tags:
        conf += [
            "server 172.31.70.0 255.255.255.0",
            "topology net30",
            'push "dhcp-option DNS 172.31.70.53"',
            'push "dhcp-option DOMAIN vpn.domain"',
        ]
    if "openvpn4" not in tags:
        conf += [
            "tun-ipv6",
            "push tun-ipv6",
            "server-ipv6 2001:db8:666:dead::/64",
            'push "route-ipv6 2001:db8:666:dead::/64"',
        ]
    if "openvpn_passwd" in tags:
        conf += [
            "script-security 2",
            f"auth-user-pass-verify {samples}/oath.sh via-file",
            "verify-client-cert none",
        ]
    if "oath" in tags:
        context.ovpn_key = nmci.process.run_stdout(
            "head -10 /dev/urandom | sha256sum | cut -b 1-30", shell=True
        ).strip("\n")
        conf += [
            "management 127.0.0.1 7505",
            "management-client-auth",
            "verb 5",
            "script-security 2",
            f"auth-user-pass-verify {samples}/oath.sh via-file",
            "verify-client-cert none",
        ]
    nmci.util.file_set_content("/etc/openvpn/trest-server.conf", conf)
    time.sleep(1)
    ovpn_proc = context.pexpect_service(
        "openvpn --writepid /tmp/openvpn.pid --config /etc/openvpn/trest-server.conf"
    )
    res = ovpn_proc.expect(
        ["Initialization Sequence Completed", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF],
        timeout=20,
    )
    assert res == 0, "OpenVPN Server did not come up in 20 seconds"

    if "oath" in tags:
        context.ovpn_mgmt = context.pexpect_service("telnet 127.0.0.1 7505")
        # enable logging of commands in management console
        context.ovpn_mgmt.send("log on all\n")

    return ovpn_proc


def setup_strongswan(context):
    """
    Setup Strongswan.

    :param context: behave context
    :type context: behave.runner.Context
    """
    RC = nmci.process.run_code(
        "sh prepare/strongswan.sh", ignore_stderr=True, timeout=60
    )
    if RC != 0:
        teardown_strongswan(context)
        assert False, "Strongswan setup failed"


def teardown_strongswan(context):
    """
    Teardown Strongswan

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.process.run_stdout("sh prepare/strongswan.sh teardown", ignore_stderr=True)


def setup_racoon(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    """
    Setup Racoon for a given mode and DH group.

    :param context: behave context
    :type context: behave.runner.Context
    :param mode: mode of the connection
    :type mode: str
    :param dh_group: DH group
    :type dh_group: str
    :param phase1_al: phase1 algorithm, defaults to "aes"
    :type phase1_al: str, optional
    :param phase2_al: phase2 algorithm, defaults to None
    :type phase2_al: str, optional
    """
    nmci.veth.wait_for_testeth0()
    if context.arch == "s390x":
        if not os.path.isfile("/usr/sbin/racoon"):
            nmci.process.dnf(
                f"-y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.{context.arch}.rpm"
            )
    else:
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        if not os.path.isfile("/usr/sbin/racoon"):
            nmci.process.dnf("-y install ipsec-tools")

    RC = nmci.process.run_code(
        f"sh prepare/racoon.sh {mode} {dh_group} {phase1_al}",
        timeout=60,
        ignore_stderr=True,
    )
    if RC != 0:
        teardown_racoon(context)
        assert False, "Racoon setup failed"


def teardown_racoon(context):
    """
    Teardown Racoon.

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.process.run_stdout("sh prepare/racoon.sh teardown")


def setup_hostapd(context):
    """
    Setup hostapd.

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.veth.wait_for_testeth0()
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        if not os.path.isfile("/usr/sbin/hostapd"):
            nmci.process.dnf("-y install hostapd")
            time.sleep(10)
    if (
        nmci.process.run_code(
            "sh prepare/hostapd_wired.sh contrib/8021x/certs",
            timeout=60,
            ignore_stderr=True,
        )
        != 0
    ):
        nmci.process.run_stdout(
            "sh prepare/hostapd_wired.sh teardown", ignore_stderr=True
        )
        assert False, "hostapd setup failed"


def teardown_hostapd(context):
    """
    Teardown hostapd.

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.process.run_stdout("sh prepare/hostapd_wired.sh teardown", ignore_stderr=True)
    nmci.veth.wait_for_testeth0()


def setup_pkcs11(context):
    """
    Setup SoftHSM2 token, key and cert for 802.1x testing.
    Don't touch token, key or cert if they're already present in order
    to avoid SoftHSM errors. No teardown for this reason, too.

    :param context: behave context
    :type context: behave.runner.Context
    """
    install_packages = []
    if not shutil.which("softhsm2-util"):
        install_packages.append("softhsm")
    if not shutil.which("pkcs11-tool"):
        install_packages.append("opensc")
    if len(install_packages) > 0:
        nmci.process.dnf(
            f"-y install {' '.join(install_packages)}",
            ignore_stderr=True,
        )
    re_token = re.compile(r"(?m)Label:[\s]*nmci[\s]*$")
    re_nmclient = re.compile(r"(?m)label:[\s]*nmclient$")

    nmci.util.file_set_content(
        "/tmp/pkcs11_passwd-file",
        ["802-1x.identity:test", "802-1x.private-key-password:1234"],
    )
    if not nmci.process.run_search_stdout(
        "softhsm2-util --show-slots", re_token, pattern_flags=0
    ):
        nmci.process.run_stdout(
            "softhsm2-util --init-token --free --pin 1234 --so-pin 123456 --label 'nmci'"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y privkey -O",
        re_nmclient,
        pattern_flags=0,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y privkey --write-object contrib/8021x/certs/client/test_user.key.pem"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y cert -O",
        re_nmclient,
        pattern_flags=0,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y cert --write-object contrib/8021x/certs/client/test_user.cert.der"
        )


def wifi_rescan(context):
    """
    Rescan for wireless networks.

    :param context: behave context
    :type context: behave.runner.Context
    """
    if "wpa2-psk" in nmci.process.nmcli_force("dev wifi list").stdout:
        return
    print("Commencing wireless network rescan")
    timeout_len = 180
    timeout = nmci.util.start_timeout(timeout_len)
    while timeout.loop_sleep(5):
        if (
            "wpa2-psk"
            not in nmci.process.nmcli_force("dev wifi list --rescan yes").stdout
        ):
            print("* still not seeing wpa2-psk")
        else:
            return
    assert False, f"Not seeing wpa2-psk in {timeout_len} seconds"


def setup_hostapd_wireless(context, args=None):
    """
    Setup hostapd for wireless testing.

    :param context: behave context
    :type context: behave.runner.Context
    :param args: additional arguments for hostapd_wireless.sh, defaults to None
    :type args: list, optional
    """
    nmci.veth.wait_for_testeth0()
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        if not os.path.isfile("/usr/sbin/hostapd"):
            nmci.process.dnf("-y install hostapd")
            time.sleep(10)
    argv = ["sh", "prepare/hostapd_wireless.sh", "contrib/8021x/certs"]
    if args is not None:
        argv.extend(args)
    nmci.process.run_stdout(
        argv,
        ignore_stderr=True,
        timeout=180,
    )
    # "check" file is touched once first check is passed
    # so first setup calls rescan, later setups  calls touch "check" file
    wifi_rescan(context)


def teardown_hostapd_wireless(context):
    """
    Teardown hostapd for wireless testing.

    :param context: behave context
    :type context: behave.runner.Context
    """
    nmci.process.run_stdout(
        "sh prepare/hostapd_wireless.sh teardown",
        ignore_stderr=True,
        timeout=15,
    )
    context.NM_pid = nmci.nmutil.nm_pid()
