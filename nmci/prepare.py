import glob
import os
import time
import shutil
import re

import nmci


def setup_libreswan(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    RC = nmci.process.run_code(
        f"MODE={mode} sh prepare/libreswan.sh",
        shell=True,
        ignore_stderr=True,
        timeout=60,
    )
    if RC != 0:
        teardown_libreswan(context)
        assert False, "Libreswan setup failed"


def teardown_libreswan(context):
    nmci.process.run_stdout("sh prepare/libreswan.sh teardown", ignore_stderr=True)
    print("Attach Libreswan logs")
    journal_log = nmci.misc.journal_show(
        syslog_identifier="pluto",
        cursor=context.log_cursor,
        journal_args="-o cat",
    )
    nmci.embed.embed_data("Libreswan Pluto Journal", journal_log)

    conf = nmci.util.file_get_content_simple("/opt/ipsec/connection.conf")
    nmci.embed.embed_data("Libreswan Config", conf)


def setup_openvpn(context, tags):
    nmci.process.run_stdout(
        "chcon -R system_u:object_r:usr_t:s0 contrib/openvpn/sample-keys/"
    )
    path = "%s/contrib/openvpn" % os.getcwd()
    samples = glob.glob(os.path.abspath(path))[0]
    conf = [
        "# OpenVPN configuration for client testing",
        "mode server",
        "tls-server",
        "port 1194",
        "proto udp",
        "dev tun",
        "persist-key",
        "persist-tun",
        f"ca {samples}/sample-keys/ca.crt",
        f"cert {samples}/sample-keys/server.crt",
        f"key {samples}/sample-keys/server.key",
        f"dh {samples}/sample-keys/dh2048.pem",
    ]
    if "openvpn6" not in tags:
        conf += [
            "server 172.31.70.0 255.255.255.0",
            'push "dhcp-option DNS 172.31.70.53"',
            'push "dhcp-option DOMAIN vpn.domain"',
        ]
    if "openvpn4" not in tags:
        conf += [
            "tun-ipv6",
            "push tun-ipv6",
            "ifconfig-ipv6 2001:db8:666:dead::1/64 2001:db8:666:dead::1",
            'push "ifconfig-ipv6 2001:db8:666:dead::2/64 2001:db8:666:dead::1"',
            # Not working for newer Fedoras (rhbz1909741)
            # 'ifconfig-ipv6-pool 2001:db8:666:dead::/64',
            'push "route-ipv6 2001:db8:666:dead::/64 2001:db8:666:dead::1"',
        ]
    nmci.util.file_set_content("/etc/openvpn/trest-server.conf", conf)
    time.sleep(1)
    ovpn_proc = context.pexpect_service("sudo openvpn /etc/openvpn/trest-server.conf")
    res = ovpn_proc.expect(
        ["Initialization Sequence Completed", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF],
        timeout=20,
    )
    assert res == 0, "OpenVPN Server did not come up in 20 seconds"
    return ovpn_proc


def setup_strongswan(context):
    RC = nmci.process.run_code(
        "sh prepare/strongswan.sh", ignore_stderr=True, timeout=60
    )
    if RC != 0:
        teardown_strongswan(context)
        assert False, "Strongswan setup failed"


def teardown_strongswan(context):
    nmci.process.run_stdout("sh prepare/strongswan.sh teardown", ignore_stderr=True)


def setup_racoon(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    nmci.veth.wait_for_testeth0()
    if context.arch == "s390x":
        nmci.process.run_stdout(
            f"[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.{context.arch}.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    else:
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )

    RC = nmci.process.run_code(
        f"sh prepare/racoon.sh {mode} {dh_group} {phase1_al}",
        timeout=60,
        ignore_stderr=True,
    )
    if RC != 0:
        teardown_racoon(context)
        assert False, "Racoon setup failed"


def teardown_racoon(context):
    nmci.process.run_stdout("sh prepare/racoon.sh teardown")


def setup_hostapd(context):
    nmci.veth.wait_for_testeth0()
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
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
    nmci.process.run_stdout("sh prepare/hostapd_wired.sh teardown", ignore_stderr=True)
    nmci.veth.wait_for_testeth0()


def setup_pkcs11(context):
    """
    Don't touch token, key or cert if they're already present in order
    to avoid SoftHSM errors. No teardown for this reason, too.
    """
    install_packages = []
    if not shutil.which("softhsm2-util"):
        install_packages.append("softhsm")
    if not shutil.which("pkcs11-tool"):
        install_packages.append("opensc")
    if len(install_packages) > 0:
        nmci.process.run_stdout(
            f"yum -y install {' '.join(install_packages)}",
            timeout=120,
            ignore_stderr=True,
        )
    re_token = re.compile(r"(?m)Label:[\s]*nmci[\s]*$")
    re_nmclient = re.compile(r"(?m)label:[\s]*nmclient$")

    nmci.util.file_set_content(
        "/tmp/pkcs11_passwd-file",
        ["802-1x.identity:test", "802-1x.private-key-password:1234"],
    )
    if not nmci.process.run_search_stdout(
        "softhsm2-util --show-slots", re_token, pattern_flags=None
    ):
        nmci.process.run_stdout(
            "softhsm2-util --init-token --free --pin 1234 --so-pin 123456 --label 'nmci'"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y privkey -O",
        re_nmclient,
        pattern_flags=None,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y privkey --write-object contrib/8021x/certs/client/test_user.key.pem"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y cert -O",
        re_nmclient,
        pattern_flags=None,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y cert --write-object contrib/8021x/certs/client/test_user.cert.der"
        )


def wifi_rescan(context):
    if "wpa2-psk" in nmci.process.nmcli_force("dev wifi list").stdout:
        return
    print("Commencing wireless network rescan")
    timeout = nmci.util.start_timeout(60)
    while timeout.loop_sleep(5):
        if (
            "wpa2-psk"
            not in nmci.process.nmcli_force("dev wifi list --rescan yes").stdout
        ):
            print("* still not seeing wpa2-psk")
        else:
            return
    assert False, "Not seeing wpa2-psk in 60 seconds"


def setup_hostapd_wireless(context, args=None):
    nmci.veth.wait_for_testeth0()
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
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
    nmci.process.run_stdout(
        "sh prepare/hostapd_wireless.sh teardown",
        ignore_stderr=True,
        timeout=15,
    )
    context.NM_pid = nmci.nmutil.nm_pid()
