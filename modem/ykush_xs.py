# -*- coding: UTF-8 -*-
import os
from subprocess import check_output
import types
import re
from time import sleep

version = '1'

# A dictionary of GSM modems. It is used to search for such devices which are connected to a USB port of a system.
known_gsm_modems = {
    '0bdb:1926': 'Ericsson H5321 gw',
    '12d1:1003': 'Huawei E220',
    '12d1:1465': 'Huawei Technologies Co., Ltd. K3765 HSPA',
    '0421:0637': 'Nokia 21M-02',
    '05c6:6000': 'Qualcomm, Inc. Siemens SG75',
    '1199:a001': 'Sierra Wireless EM7345',
    '1c9e:f000': 'Zoom 4595',
    '19d2:0117': 'ZTE WCDMA Technologies MSM'
}


def is_usb_device_id(DEVICE_ID):
    """
    Check if this is a valid USB device ID.
    Yes - return True.
    No - return False.
    """
    try:
        device_id = str(DEVICE_ID)
    except:
        raise Exception('Invalid USB device ID.')

    device_id = device_id.lower()
    # Searching via regular expression.
    regex = '[A-Fa-f0-9]{4}:[A-Fa-f0-9]{4}'
    # Matches: '12d1:1465', '12D1:1465', but not '12d:1465', '12d1:465', '12d11465'.

    mo = re.search(regex, device_id)
    if isinstance(mo, types.NoneType) is True:
        # No match was found.
        return False
    else:
        # A USB device ID was detected. Success.
        return True


def is_net_device(DEVICE_NAME):
    """
    Check if a network device is present in the output of "nmcli device".
    Case sensitive.
    If found return True, else return False.
    """
    cmd = 'nmcli device'
    try:
        output = check_output(cmd, shell=True).strip()
    except:
        raise Exception('Cannot obtain the list of network devices from NetworkManager.')

    if output.find(DEVICE_NAME) >= 0:
        return True
    else:
        return False


def check_usb_dev(DEVICE_ID, TIMEOUT=60):
    """
    Wait for a USB device
    by checking for correspoding USB device ID to appear in the list of USB devices.
    This function is used for YKUSH module and GSM modems.
    """
    # DEVICE_ID = USB device ID
    # TIMEOUT = waiting period for the GSM modem to get activated.
    assert is_usb_device_id(DEVICE_ID) is True, 'Invalid USB device ID "{}".'.format(DEVICE_ID)

    isFound = False
    t = TIMEOUT
    cmd = 'lsusb | grep -q -i -w "{}"'.format(DEVICE_ID)
    # If the device is found the return code is 0.

    while (t > 0) and (isFound is False):
        RC = os.system(cmd)
        if RC == 0:
            isFound = True
            print('Device ID "{0}" was detected.'.format(DEVICE_ID, TIMEOUT))
        else:
            sleep(1)
            t -= 1

    assert isFound is True, 'Device ID "{0}" was not detected in {1} seconds.'.format(DEVICE_ID, TIMEOUT)


def check_gsm_dev(DEVICE_NAME, TIMEOUT=60):
    """
    Wait for a GSM modem to appear in the list of network devices
    until the timeout of 60 seconds is reached
    by checking via NetworkManager's CLI
    Expect a device name, as seen via nmcli. Case sensitive.
    """
    cmd = 'nmcli --terse -f DEVICE,TYPE,STATE device | grep -i -w gsm | grep -q -w "{}"'.format(DEVICE_NAME)
    # If the device is found the return code is 0.
    isFound = False
    t = TIMEOUT
    while (t > 0) and (isFound is False):
        RC = os.system(cmd)
        if RC == 0:
            # The GSM modem is a network device.
            isFound = True
            print('GSM modem "{}" was found.'.format(DEVICE_NAME))
        else:
            sleep(1)
            t -= 1

    assert isFound is True, \
      'GSM modem "{0}" did not appear in the list of network devices in {1} seconds.'.format(DEVICE_NAME, TIMEOUT)


def check_connection(CONNECTION, TIMEOUT=60):
    """
    Wait for a network connection to become active
    until the timeout of 60 seconds is reached
    by checking its name or UUID in the list of active connections via NetworkManager's CLI.
    """
    # TODO: validate parameters.

    cmd = 'nmcli connection show --active | grep -q -w "{}"'.format(CONNECTION)
    # The the connection is found and active, the return code is 0.
    isFound = False
    t = TIMEOUT

    while (t > 0) and (isFound is False):
        RC = os.system(cmd)
        if RC == 0:
            isFound = True
            print('Network connection "{}" is active.'.format(CONNECTION))
        else:
            sleep(1)
            t -= 1

    assert isFound is True, 'Network connection "{0}" was NOT activated in {1} sec.'.format(CONNECTION, TIMEOUT)


def check_serial_interface(TIMEOUT=30):
    """
    Check the serial interface of a GSM modem, after it was recognized as network device
    until the timeout of 30 seconds is reached
    by checking for "ppp" via command "ip link".
    """
    assert isinstance(TIMEOUT, types.IntType) is True, 'Invalid value for timeout "{}".'.format(TIMEOUT)
    assert TIMEOUT > 0,  'Timeout must have a positive value.'.format(TIMEOUT)

    cmd  = 'ip link | grep -q -m1 -w ppp[0-9]*'
    # When a serial interface is found, the return code is 0. Works for a single modem per system only.
    cmd2 = 'ip link | grep -m1 -w ppp[0-9]* | awk -F: \'{gsub(" |\t",""); print $2}\''
    # Obtain the name of the serial interface.
    t = TIMEOUT
    isFound = False
    while (t > 0) and (isFound is False):
        RC = os.system(cmd)
        if RC == 0:
            output = check_output(cmd2, shell=True).strip()
            print('Serial interface was detected:\n{}'.format(output))
            isFound = True
        else:
            sleep(1)
            t -= 1

    assert isFound is True, 'Serial interface was NOT detected.'


def manage_ykush(ACTION):
    """
    Manage YKUSH XS module via its CLI "ykushcmd".
    One such module per system is supported.
    Only root can perform operations with the module.
    """
    action = ACTION.lower()
    assert action in ['connect', 'disconnect'], \
      'Unsupported operation for YKUSH module.\nPossible operations include "connect", "disconnect".'
    # 1. Disconnect the downstream port:
    #   ykushcmd ykushxs -d
    # 2. Connect the downstream port:
    #   ykushcmd ykushxs -u

    # Relation: action - command
    ykush_actions = {
        'disconnect': 'ykushcmd ykushxs -d',
        'connect': 'ykushcmd ykushxs -u',
    }

    cmd = 'sudo ' + ykush_actions[action]
    # Execute the command and check the exit code.
    RC = os.system(cmd)
    if RC == 0:
        print('Action "{}" was successfully performed on YKUSH module.'.format(action))
    else:
        raise Exception('Failed to perform action "{}" on YKUSH module.'.format(action))


def get_status_ykush():
    """
    Get the status of module YKUSH XS via its CLI "ykushcmd".
    One such module per system is supported.
    Only root can perform actions on the module. Other users receive wrong status.
    Downstream port is [OFF|ON].
    """
    cmd = 'sudo ykushcmd ykushxs -g'
    try:
        output = check_output(cmd, shell=True).strip()
    except:
        raise Exception('Failed to get the status of module YKUSH XS.')

    # Search for module status with regular expression.
    regex = 'Downstream port is [OFF|ON]'
    mo = re.search(regex, output)
    if isinstance(mo, types.NoneType) is True:
        raise Exception('Unexpected module status:\n{}.'.format(output))
    return output


def create_gsm_connection(CON_NAME, GSM_DEV, APN, PIN=''):
    """
    Create a new network connection
    by using a GSM modem
    by specifying APN, PIN if required.
    """
    assert is_net_device(GSM_DEV) is True, 'The device "{}" is not available to NetworkManager.'.format(GSM_DEV)
    assert isinstance(APN, types.StringType) is True, 'Invalid APN "{}". Example: internet.t-mobile.cz'.format(APN)
    assert isinstance(PIN, types.StringType) is True, 'PIN should be passed as string. Example: \'1234\''
    # Is PIN specfied for a SIM card in a GSM modem?
    if PIN == '':
        cmd = 'nmcli connection add con-name "{0}"  type gsm  ifname {1}  gsm.apn "{2}"'.format(CON_NAME, GSM_DEV, APN)
    else:
        try:
            tmp_pin = int(PIN)
        except:
            raise Exception('Invalid PIN code "{}".'.format(PIN))
        cmd = 'nmcli connection add con-name "{0}"  type gsm  ifname {1}  gsm.apn "{2}"  gsm.pin {3}'.format(CON_NAME, GSM_DEV, APN, PIN)

    RC = os.system(cmd)
    assert RC == 0, 'Failed to create GSM connection "{}".'.format(CON_NAME)


def clean_up(CONNECTION):
    """
    Clean up after a GSM connection
    when no connections are to be established with a GSM modem
    by deleting its correspoding connection via NetworkManager
    by enabling the power of its USB port via YKUSH XS module.
    """
    cmd = 'nmcli --terse -f NAME,UUID connection show'
    try:
        output = check_output(cmd, shell=True).strip()
    except:
        raise Exception('Cannot get the list of network connections via nmcli.')

    assert output.find(CONNECTION) >= 0, 'Connection "{}" was not found via nmcli.'.format(CONNECTION)

    cmd = 'sudo nmcli connection delete "{}"'.format(CONNECTION)
    # The connection can be a name or UUID, the same as seen via "nmcli connection show".
    RC = os.system(cmd)
    assert RC == 0, 'Failed to delete connection "{}".'.format(CONNECTION)

    # Leave the module YKUSH XS in enabled state, Thus, turn on the power of USB port.
    manage_ykush('connect')


# A GSM modem can be managed via NetworkManager via its primary port.
# The primary port is contained in the output of "mmcli --modem=[index]"
# TODO: How to match a modem's name to its device in the list of nmcli?

"""
Example of a GSM modem.
$ mmcli --modem=1

/org/freedesktop/ModemManager1/Modem/1 (device id '8d4232b89bdda67c0a2a6ab565c5231998c4feb8')
  -------------------------
  Hardware |   manufacturer: 'huawei'
           |          model: 'K3765'
           |       revision: '11.126.03.06.00'
           |      supported: 'gsm-umts'
           |        current: 'gsm-umts'
           |   equipment id: '353054034463505'
  -------------------------
  System   |         device: '/sys/devices/pci0000:00/0000:00:14.0/usb3/3-6/3-6.1'
           |        drivers: 'option1, cdc_ether'
           |         plugin: 'Huawei'
           |   primary port: 'ttyUSB2'
           |          ports: 'ttyUSB0 (at), ttyUSB1 (qcdm), ttyUSB2 (at), wwp0s20u6u1i1 (net)'
  -------------------------
  Numbers  |           own : 'unknown'
  -------------------------
  Status   |           lock: 'sim-pin'
           | unlock retries: 'sim-pin (3), sim-pin2 (3), sim-puk (10), sim-puk2 (10)'
           |          state: 'locked'
           |    power state: 'on'
           |    access tech: 'unknown'
           | signal quality: '0' (cached)
  -------------------------
  Modes    |      supported: 'allowed: 2g, 3g; preferred: none
           |                  allowed: 2g, 3g; preferred: 2g
           |                  allowed: 2g, 3g; preferred: 3g
           |                  allowed: 2g; preferred: none
           |                  allowed: 3g; preferred: none'
           |        current: 'allowed: 2g, 3g; preferred: none'
  -------------------------
  Bands    |      supported: 'unknown'
           |        current: 'unknown'
  -------------------------
  IP       |      supported: 'none'
  -------------------------
  SIM      |           path: '/org/freedesktop/ModemManager1/SIM/0'

  -------------------------
  Bearers  |          paths: 'none'

"""


"""
Example for a USB modem.
$ lsusb

Bus 003 Device 017: ID 12d1:1465 Huawei Technologies Co., Ltd. K3765 HSPA
Device Descriptor:
  bLength                18
  bDescriptorType         1
  bcdUSB               2.00
  bDeviceClass          239 Miscellaneous Device
  bDeviceSubClass         2 ?
  bDeviceProtocol         1 Interface Association
  bMaxPacketSize0        64
  idVendor           0x12d1 Huawei Technologies Co., Ltd.
  idProduct          0x1465 K3765 HSPA
  bcdDevice            0.00
  iManufacturer           4 HUAWEI Technology
  iProduct                3 HUAWEI Mobile
  iSerial                 0
  bNumConfigurations      1
"""
