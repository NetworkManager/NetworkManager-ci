import time
from behave import step  # pylint: disable=no-name-in-module
import nmci


@step('Add "{vpn}" VPN connection named "{name}" for device "{ifname}"')
def add_vpnc_connection_for_iface(context, name, ifname, vpn):
    nmci.cleanup.cleanup_add_connection(name)
    command = (
        f'connection add con-name "{name}" type vpn ifname {ifname} vpn-type {vpn}'
    )
    nmci.process.nmcli(command)


@step(
    'Use certificate "{cert}" with key "{key}" and authority "{ca_file}" for gateway "{gateway}" on OpenVPN connection "{name}"'
)
def set_openvpn_connection(context, cert, key, ca_file, gateway, name):
    cert_path = nmci.util.base_dir("contrib/openvpn/")

    vpn_data = {
        "tunnel-mtu": "1400",
        "key": cert_path + key,
        "connection-type": "tls",
        "ca": cert_path + ca_file,
        "cert": cert_path + cert,
        "remote": gateway,
        "cert-pass-flags": "0",
    }

    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str}")


@step(
    'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on Libreswan connection "{name}"'
)
def set_libreswan_connection(context, user, password, group, secret, gateway, name):

    username_option = "leftxauthusername"
    if int(context.rh_release_num) != 8:
        if (
            nmci.process.run_search_stdout("rpm -q libreswan", "libreswan-4")
            is not None
        ):
            username_option = "leftusername"

    vpn_data = {
        username_option: user,
        "right": gateway,
        "xauthpasswordinputmodes": "ask" if password == "ask" else "save",
        "xauthpassword-flags": "2" if password == "ask" else "0",
        "pskinputmodes": "ask" if secret == "ask" else "save",
        "pskvalue-flags": "2" if secret == "ask" else "0",
        "vendor": "Cisco",
    }
    if group != "Main":
        vpn_data["leftid"] = group

    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {}
    if password != "ask":
        vpn_secrets["xauthpassword"] = password
    if secret != "ask":
        vpn_secrets["pskvalue"] = secret

    vpn_secrets_str = ""
    if vpn_secrets:
        vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with secret "{secret}" for gateway "{gateway}" on Strongswan connection "{name}"'
)
def set_strongswan_connection(context, user, secret, gateway, name):
    vpn_data = {
        "user": user,
        "address": gateway,
        "method": "psk",
        "virtual": "yes",
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "password": secret,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on VPNC connection "{name}"'
)
def set_vpnc_connection(context, user, password, group, secret, gateway, name):
    vpn_data = {
        "NAT Traversal Mode": "natt",
        "ipsec-secret-type": "save",
        "IPSec secret-flags": "0",
        "xauth-password-type": "save",
        "Vendor": "cisco",
        "Xauth username": user,
        "IPSec gateway": gateway,
        "Xauth password-flags": "0",
        "IPSec ID": group,
        "Perfect Forward Secrecy": "server",
        "IKE DH Group": "dh2",
        "Local Port": "0",
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "IPSec secret": secret,
        "Xauth password": password,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with password "{password}" and MPPE set to "{mppe}" for gateway "{gateway}" on PPTP connection "{name}"'
)
def set_pptp_connection(context, user, password, mppe, gateway, name):
    vpn_data = {
        "password-flags": "2" if password == "file" else "0",
        "user": user,
        "require-mppe": mppe,
        "gateway": gateway,
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "password": password,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step('Connect to vpn "{vpn}" with password "{password}"')
@step('Connect to vpn "{vpn}" with password "{password}" after "{time_out}" seconds')
@step('Connect to vpn "{vpn}" with password "{password}" and secret "{secret}"')
def connect_to_vpn(context, vpn, password, secret=None, time_out=0):
    cli = nmci.pexpect.pexpect_spawn(f"nmcli -a connect up {vpn}", timeout=180)
    time.sleep(int(time_out))
    cli.expect("Password.*:")
    cli.sendline(password)
    if secret is not None:
        cli.expect("Group password.*:")
        cli.sendline(secret)
    if nmci.process.systemctl("-q is-active polkit").returncode == 0:
        ret = cli.expect(["Error", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF])
        assert (
            ret != 0
        ), f"Got an Error while connecting to network {vpn}\n{cli.after}{cli.buffer}"
        assert ret != 1, "nmcli vpn connect ... timed out (180s)"
    else:
        # Remove me when 1756441 is fixed
        ret = cli.expect(["Connection successfully activated", nmci.pexpect.TIMEOUT])
        assert (
            ret == 0
        ), f"Got an Error while connecting to network {vpn}\n{cli.after}{cli.buffer}"
