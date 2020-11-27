import glob
import os
import pexpect
import re
import subprocess
import time
from behave import step


@step(u'Use certificate "{cert}" with key "{key}" and authority "{ca}" for gateway "{gateway}" on OpenVPN connection "{name}"')
def set_openvpn_connection(context, cert, key, ca, gateway, name):
    samples = glob.glob(os.path.abspath('tmp/openvpn/'))[0]+'/'
    cli = pexpect.spawn('nmcli c modify %s vpn.data "tunnel-mtu = 1400, key = %s, connection-type = tls, ca = %s, cert = %s, remote = %s, cert-pass-flags = 0"' % (name, samples + key, samples + ca, samples + cert, gateway), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection data\n%s%s' % (name, cli.after, cli.buffer))
    time.sleep(1)


@step(u'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on Libreswan connection "{name}"')
def set_libreswan_connection(context, user, password, group, secret, gateway, name):
    if password == "ask" and secret != "ask":
        cli = pexpect.spawn('nmcli c modify %s vpn.data "leftxauthusername = %s, leftid = %s, pskinputmodes = save, right = %s, xauthpasswordinputmodes = ask, pskvalue-flags = 0, xauthpassword-flags = 2, vendor = Cisco" vpn.secrets "pskvalue = %s"' % (name, user, group, gateway, secret), encoding='utf-8')
    if password == "ask" and secret == "ask":
        cli = pexpect.spawn('nmcli c modify %s vpn.data "leftxauthusername = %s, leftid = %s, pskinputmodes = ask, right = %s, xauthpasswordinputmodes = ask, pskvalue-flags = 2, xauthpassword-flags = 2, vendor = Cisco"' % (name, user, group, gateway), encoding='utf-8')
    if password != "ask" and secret == "ask":
        cli = pexpect.spawn('nmcli c modify %s vpn.data "leftxauthusername = %s, leftid = %s, pskinputmodes = ask, right = %s, xauthpasswordinputmodes = save, pskvalue-flags = 2, xauthpassword-flags = 0, vendor = Cisco" vpn.secrets "xauthpassword = %s"' % (name, user, group, gateway), encoding='utf-8')
    if password != "ask" and secret != "ask":
        if group == 'Main':
            cli = pexpect.spawn('nmcli c modify %s vpn.data "leftxauthusername = %s, pskinputmodes = save, right = %s, xauthpasswordinputmodes = save, pskvalue-flags = 0, xauthpassword-flags = 0, vendor = Cisco" vpn.secrets "pskvalue = %s, xauthpassword = %s"' % (name, user, gateway, secret, password), encoding='utf-8')
        else:
            cli = pexpect.spawn('nmcli c modify %s vpn.data "leftxauthusername = %s, leftid = %s, pskinputmodes = save, right = %s, xauthpasswordinputmodes = save, pskvalue-flags = 0, xauthpassword-flags = 0, vendor = Cisco" vpn.secrets "pskvalue = %s, xauthpassword = %s"' % (name, user, group, gateway, secret, password), encoding='utf-8')

    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection\n%s%s' % (name, cli.after, cli.buffer))


@step(u'Use user "{user}" with secret "{secret}" for gateway "{gateway}" on Strongswan connection "{name}"')
def set_libreswan_connection(context, user, secret, gateway, name):
    #cli = pexpect.spawn('nmcli c modify %s vpn.data "user = %s, address = %s, method = psk, virtual = yes, pskinputmodes = save, xauthpasswordinputmodes = save, pskvalue-flags = 0, xauthpassword-flags = 0" vpn.secrets "password = %s"' % (name, user, gateway, secret), encoding='utf-8')
    cli = pexpect.spawn('nmcli c modify %s vpn.data "user = %s, address = %s, method = psk, virtual = yes" vpn.secrets "password = %s"' % (name, user, gateway, secret), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection\n%s%s' % (name, cli.after, cli.buffer))


@step(u'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on VPNC connection "{name}"')
def set_vpnc_connection(context, user, password, group, secret, gateway, name):
    cli = pexpect.spawn('nmcli c modify %s vpn.data "NAT Traversal Mode=natt, ipsec-secret-type=save, IPSec secret-flags=0, xauth-password-type=save, Vendor=cisco, Xauth username=%s, IPSec gateway=%s, Xauth password-flags=0, IPSec ID=%s, Perfect Forward Secrecy=server, IKE DH Group=dh2, Local Port=0"' % (name, user, gateway, group), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection data\n%s%s' % (name, cli.after, cli.buffer))
    cli = pexpect.spawn('nmcli c modify %s vpn.secrets "IPSec secret=%s, Xauth password=%s"' % (name, secret, password), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection secrets\n%s%s' % (name, cli.after, cli.buffer))


@step(u'Use user "{user}" with password "{password}" and MPPE set to "{mppe}" for gateway "{gateway}" on PPTP connection "{name}"')
def set_pptp_connection(context, user, password, mppe, gateway, name):
    flag = "0"
    if password == "file":
        flag = "2"
    cli = pexpect.spawn('nmcli c modify %s vpn.data "password-flags = %s, user = %s, require-mppe = %s, gateway = %s"' % (name, flag, user, mppe, gateway), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while editing %s connection data\n%s%s' % (name, cli.after, cli.buffer))
    time.sleep(1)
    if flag != "2":
        cli = pexpect.spawn('nmcli c modify %s vpn.secrets "password = %s"' % (name, password), encoding='utf-8')
        r = cli.expect(['Error', pexpect.EOF])
        if r == 0:
            raise Exception('Got an Error while editing %s connection secrets\n%s%s' % (name, cli.after, cli.buffer))


@step(u'Connect to vpn "{vpn}" with password "{password}"')
@step(u'Connect to vpn "{vpn}" with password "{password}" with timeout "{time_out}"')
@step(u'Connect to vpn "{vpn}" with password "{password}" and secret "{secret}"')
def connect_to_vpn(context, vpn, password, secret=None, time_out=None):
    cli = pexpect.spawn('nmcli -a connect up %s' % (vpn), timeout = 180, logfile=context.log, encoding='utf-8')
    if not time_out:
        time.sleep(1)
    else:
        time.sleep(int(time_out))
    cli.sendline(password)
    if secret != None:
        time.sleep(1)
        cli.sendline(secret)
    if subprocess.call("systemctl -q is-active polkit", shell=True) == 0:
        r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
        if r == 0:
            raise Exception('Got an Error while connecting to network %s\n%s%s' % (vpn, cli.after, cli.buffer))
        elif r == 1:
            raise Exception('nmcli vpn connect ... timed out (180s)')
    else:
        # Remove me when 1756441 is fixed
        r = cli.expect(['Connection successfully activated', pexpect.TIMEOUT])
        if r != 0:
            raise Exception('Got an Error while connecting to network %s\n%s%s' % (vpn, cli.after, cli.buffer))
