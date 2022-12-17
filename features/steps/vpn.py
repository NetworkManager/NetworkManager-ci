import glob
import os
import pexpect
import time
from behave import step  # pylint: disable=no-name-in-module
import nmci


def vpn_options_str(vpn_data, vpn_secrets):
    vpn_data_str = ", ".join(["%s = %s" % (attr, vpn_data[attr]) for attr in vpn_data.keys()])
    vpn_data_str = "vpn.data '%s'" % vpn_data_str

    vpn_secrets_str = ""
    if vpn_secrets:
        vpn_secrets_str = ", ".join(
            ["%s = %s" % (attr, vpn_secrets[attr]) for attr in vpn_secrets.keys()])
        vpn_secrets_str = " vpn.secrets '%s'" % vpn_secrets_str

    with open("/tmp/vpn.data", "w") as f:
        f.write(vpn_data_str + vpn_secrets_str)

    return vpn_data_str + vpn_secrets_str


@step(u'Use certificate "{cert}" with key "{key}" and authority "{ca}" for gateway "{gateway}" on OpenVPN connection "{name}"')
def set_openvpn_connection(context, cert, key, ca, gateway, name):
    path = "%s/contrib/openvpn" % os.getcwd()
    samples = glob.glob(os.path.abspath(path))[0]+'/'

    vpn_data = {
        "tunnel-mtu": "1400",
        "key": samples + key,
        "connection-type": "tls",
        "ca": samples + ca,
        "cert": samples + cert,
        "remote": gateway,
        "cert-pass-flags": "0",
    }

    context.execute_steps('''
    * Modify connection "%s" changing options "%s"
    ''' % (name, vpn_options_str(vpn_data, {})))

    time.sleep(1)


@step(u'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on Libreswan connection "{name}"')
def set_libreswan_connection(context, user, password, group, secret, gateway, name):
    if nmci.process.run_search_stdout("rpm -qa", "libreswan-4") is not None and 'release 8' not in context.rh_release:
        username_option = "leftusername"
    else:
        username_option = "leftxauthusername"
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

    vpn_secrets = {}
    if password != "ask":
        vpn_secrets["xauthpassword"] = password
    if secret != "ask":
        vpn_secrets["pskvalue"] = secret

    context.execute_steps('''
    * Modify connection "%s" changing options "%s"
    ''' % (name, vpn_options_str(vpn_data, vpn_secrets)))


@step(u'Use user "{user}" with secret "{secret}" for gateway "{gateway}" on Strongswan connection "{name}"')
def set_strongswan_connection(context, user, secret, gateway, name):
    vpn_data = {
        "user": user,
        "address": gateway,
        "method": "psk",
        "virtual": "yes",
    }

    vpn_secrets = {
        "password": secret,
    }

    context.execute_steps('''
    * Modify connection "%s" changing options "%s"
    ''' % (name, vpn_options_str(vpn_data, vpn_secrets)))


@step(u'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on VPNC connection "{name}"')
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

    vpn_secrets = {
        "IPSec secret": secret,
        "Xauth password": password,
    }

    context.execute_steps('''
    * Modify connection "%s" changing options "%s"
    ''' % (name, vpn_options_str(vpn_data, vpn_secrets)))


@step(u'Use user "{user}" with password "{password}" and MPPE set to "{mppe}" for gateway "{gateway}" on PPTP connection "{name}"')
def set_pptp_connection(context, user, password, mppe, gateway, name):
    vpn_data = {
        "password-flags": "2" if password == "file" else "0",
        "user": user,
        "require-mppe": mppe,
        "gateway": gateway,
    }

    vpn_secrets = {
        "password": password,
    }

    context.execute_steps('''
    * Modify connection "%s" changing options "%s"
    ''' % (name, vpn_options_str(vpn_data, vpn_secrets)))


@step(u'Connect to vpn "{vpn}" with password "{password}"')
@step(u'Connect to vpn "{vpn}" with password "{password}" after "{time_out}" seconds')
@step(u'Connect to vpn "{vpn}" with password "{password}" and secret "{secret}"')
def connect_to_vpn(context, vpn, password, secret=None, time_out=None):
    cli = context.pexpect_spawn('nmcli -a connect up %s' % (vpn), timeout=180)
    if not time_out:
        time.sleep(1)
    else:
        time.sleep(int(time_out))
    cli.sendline(password)
    if secret is not None:
        time.sleep(1)
        cli.sendline(secret)
    if nmci.process.systemctl("-q is-active polkit").returncode == 0:
        r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
        assert r != 0, 'Got an Error while connecting to network %s\n%s%s' % (vpn, cli.after, cli.buffer)
        assert r != 1, 'nmcli vpn connect ... timed out (180s)'
    else:
        # Remove me when 1756441 is fixed
        r = cli.expect(['Connection successfully activated', pexpect.TIMEOUT])
        assert r == 0, 'Got an Error while connecting to network %s\n%s%s' % (vpn, cli.after, cli.buffer)
