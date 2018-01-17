# -*- coding: UTF-8 -*-
import os
from subprocess import check_output
import types
import re
from time import sleep

version = '1'

def get_modem_index(modem_model):
    """
    Get the index of a known GSM modem
    when the modem's name is present in the list
    by using ModemManager's CLI.
    Return an integer value.
    """
    assert isinstance(modem_model, types.StringType is True), 'Invalid modem model "{}".'.format(modem_model)

    cmd = 'mmcli -L'
    try:
        cmd_output = check_output(cmd, shell=True)
    except:
        raise Exception('Error when searching for a modem with: {}.'.format(cmd))

    regex = '(/org/freedesktop/ModemManager1/Modem/[0-9]+) (.*)'
    mo = re.search(regex, cmd_output)
    if isinstance(mo, types.NoneType) is True:
        raise Exception('Searching with for modems with regex:\n{}\ndid not found any match.'.found(regex))

    # Modem index should be here.
    modem_index = mo.group(1).strip().split('/')[5]
    # Modem manufacturer and model should be here.
    modem_info = mo.group(2).strip()

    if modem_info.find(modem_model) < 0:
        raise Exception('Modem model was not found.')

    # Modem model was found.
    # Verify that this is a valid integer value.
    try:
        mi = int(modem_index)
    except:
        raise Exception('Invalid modem index: {}. Should be a positive integer.'.format(modem_index))

    return mi  # integer


def get_1st_modem_index():
    """
    Get the index of the 1st available modem from the list of 'mmcli -L'.
    Note: Taht index can increase from 0 to N. This happens when the modem reinitializes.
    It can happen that 1st modem from the list has index > 0.
    Return an integer value.
    Example
    Found 2 modems:
        /org/freedesktop/ModemManager1/Modem/1 [huawei] K3765
        /org/freedesktop/ModemManager1/Modem/0 [Ericsson MBM] MBIM [0BDB:193E]
    The 1st modem from the list is [huawei] K3765, index = 1
    """
    cmd = 'mmcli -L'
    cmd_output = check_output(cmd, shell=True)
    regex = '(/org/freedesktop/ModemManager1/Modem/[0-9]+) (.*)'
    mo = re.search(regex, cmd_output)
    if isinstance(mo, types.NoneType) is True:
        raise Exception('Searching for modems with regex:\n{}\ndid not found any match.'.format(regex))

    # Modem index should be here.
    modem_index = mo.group(1).strip().split('/')[5]

    # Verify that this is a valid integer value.
    try:
        mi = int(modem_index)
    except:
        raise Exception('Invalid modem index: {}. Should be a positive integer.'.format(modem_index))

    return mi  # integer


def get_sim_index(modem_index):
    """
    Find the index of the SIM card of a modem.
    Return an integer value.
    Example:
    mmcli --modem=$modem_index
    ...
       SIM      |           path: '/org/freedesktop/ModemManager1/SIM/$sim_index'
    ...
    """
    assert isinstance(modem_index, types.IntType) is True, 'Invalid modem index "{}".'.format(modem_index)
    assert modem_index >= 0, 'Invalid modem index "{}". Should be a positive integer.'.format(modem_index)

    regex = 'SIM .*(path:.*/org/freedesktop/ModemManager1/SIM/[0-9]+)'
    cmd = 'mmcli --modem={}'.format(modem_index)
    try:
        cmd_output = check_output(cmd, shell=True)
    except:
        raise Exception('Error when searching by modem index with:\n{}.'.format(cmd))

    mo = re.search(regex, cmd_output)
    if isinstance(mo, types.NoneType) is True:
        raise Exception('No SIM card found by using regex:\n{}'.format(regex))

    sim_index = mo.group(1).strip().split('/')[5]
    # Verify that sim_index is a valid integer.
    try:
        si = int(sim_index)
    except:
        raise Exception('Invalid SIM card index: {}. Should be a positive integer.'.format(sim_index))

    assert si >= 0, 'Invalid SIM card index "{}". Should be a positive integer.'.format(si)

    return si  # integer


def get_sim_id(modem_index):
    """
    Get the ID and IMSI of a SIM card
    when a mobile broadband modem is connected to a system
    when the modem is properly recognized as communivation device
    by specifying the modem index via ModemManager CLI.
    Return a tuple of strings.
    Example:
    SIM '/org/freedesktop/ModemManager1/SIM/0'
      -------------------------
      Properties |          imsi : 'unknown'
                 |            id : '8942001260338777877'
                 |   operator id : 'unknown'
                 | operator name : 'T-Mobile CZ'
    """
    assert isinstance(modem_index, types.IntType) is True, 'Invalid modem index "{}".'.format(modem_index)
    assert modem_index >= 0, 'Invalid modem index "{}". Should be a positive integer.'.format(modem_index)

    sim_index = get_sim_index(modem_index)  # integer value
    cmd = 'mmcli --sim={}'.format(sim_index)
    try:
        output = check_output(cmd, shell=True)
    except:
        raise Exception('Cannot get info about SIM[{}].'.format(sim_index))

    # Seach for IMSI and ID by using regular expression.
    regex = 'imsi : \'(\w+)\'\n.* id : \'(\w+)\''
    mo = re.search(regex, output)
    if isinstance(mo, types.NoneType) is True:
        raise Exception('Cannot find IMSI and ID of SIM[{}].'.format(sim_index))

    sim_imsi = mo.group(1)
    sim_id = mo.group(2)
    return sim_imsi, sim_id  # a tuple of strings


def enable_pin(sim_index, PIN):
    """
    Enable a new PIN on the SIM card of a GSM modem
    when the SIM card is not in locked state
    by using MomdemManager's CLI.
    """
    assert isinstance(sim_index, types.IntType) is True, 'Invalid SIM index "{}".'.format(sim_index)
    assert sim_index >= 0, 'Invalid SIM index "{}". Should be a positive integer.'.format(sim_index)
    assert isinstance(PIN, types.StringType) is True, 'PIN should be passed as string. Example: \'1234\''

    try:
        tmp_pin = int(PIN)
    except:
        raise Exception('Invalid PIN code "{}".'.format(PIN))

    cmd = 'mmcli --sim={} --enable-pin --pin={}'.format(sim_index, PIN)
    try:
        result = check_output(cmd, shell=True)
    except:
        raise Exception('Failed to set new PIN "{0}" on SIM[{1}]'.format(PIN, sim_index))
    print('New PIN "{0}" has been set on SIM[{1}]'.format(PIN, sim_index))


def disable_pin(sim_index, PIN):
    """
    Disable the PIN on the SIM card of a GSM modem
    when the SIM card is not in locked state
    by using MomdemManager's CLI.
    """
    assert isinstance(sim_index, types.IntType) is True, 'Invalid SIM index "{}".'.format(sim_index)
    assert sim_index >= 0, 'Invalid SIM index "{}". Should be a positive integer.'.format(sim_index)
    assert isinstance(PIN, types.StringType) is True, 'PIN should be passed as string. Example: \'1234\''

    try:
        tmp_pin = int(PIN)
    except:
        raise Exception('Invalid PIN code "{}".'.format(PIN))

    cmd = 'mmcli --sim={} --disable-pin --pin={}'.format(sim_index, PIN)
    try:
        result = check_output(cmd, shell=True)
    except:
        raise Exception('Failed to remove PIN "{0}" on SIM[{1}]'.format(PIN, sim_index))
    print('PIN "{0}" has been removed on SIM[{1}]'.format(PIN, sim_index))


def send_pin(sim_index, PIN):
    # FIXME: correct the sending of PIN.
    assert isinstance(sim_index, types.IntType) is True, 'Invalid SIM index "{}".'.format(sim_index)
    assert sim_index >= 0, 'Invalid SIM index "{}". Should be a positive integer.'.format(sim_index)
    assert isinstance(PIN, types.StringType) is True, 'PIN should be passed as string. Example: \'1234\''

    cmd = 'mmcli --sim={} --pin={}'.format(sim_index, PIN)
    try:
        result = check_output(cmd, shell=True)
    except:
        # Failure
        print('Error when sending PIN code')
        return -1
    else:
        # Success
        print(result)
        return 0
    # Wait 15 sec before performing other actions with the modem.


def is_modem_connected(modem_index):
    """
    Check if a mobile broadband modem is connected to a mobile network
    when the service ModemManager is running
    by checking the modem's status via mmcli. Expected status: "state: 'registered'"
    Return True/False.
    """
    assert isinstance(modem_index, types.IntType) is True, 'Invalid modem index "{}".'.format(modem_index)
    assert modem_index >= 0, 'Invalid modem index "{}". Should be a positive integer.'.format(modem_index)

    try:
        mi = int(modem_index)
    except:
        raise Exception('Invalid modem index "{}". Should be a positive integer.'.format(modem_index))

    assert mi >= 0, 'Invalid modem index "{}". Should be a positive integer.'.format(mi)

    # Check if ModemManager running.
    RC = os.system('systemctl -q is-active ModemManager')
    if RC == 0:
        print('The service "ModemManager" is active. OK.')
    else:
        print('The service "ModemManager" is NOT active. Failure.')
        return False

    # Wait for the modem to connect.
    # Crtiteria for successful connection to the mobile network.
    t = 30  # sec
    isConnected = False
    cmd = 'mmcli --modem={} --simple-status'.format(mi)

    while (t > 0) and (isConnected is False):
        try:
            status = check_output(cmd, shell=True)
            # This statement throws an exception when a modem is not ready to accept commands.
        except:
            # The modem is unable to accept commands.
            sleep(1)
            t -= 1
            # Go to next loop, disregard the code below
            continue

        if status.find("state: 'registered'") >= 0:
            isConnected = True
        else:
            sleep(1)
            t -= 1

    return isConnected


def reset_modem(modem_index, delay=15):
    """
    Reset a modem
    when this operation in available for the modem's model
    by using option "--reset" via ModemManager's CLI.
    Modem index increases by 1 after every reset, but it can be hold at 0
    by restarting ModemManager's service.
    """
    assert isinstance(modem_index, types.IntType) is True, 'Invalid modem index "{}".'.format(modem_index)
    assert modem_index >= 0, 'Invalid modem index "{}". Should be a positive integer.'.format(modem_index)
    assert isinstance(delay, types.IntType) is True, 'Invalid delay "{}".'.format(delay)

    cmd = 'mmcli --modem={} --reset'.format(modem_index)
    os.system(cmd)
    sleep(delay)
    cmd = 'sudo systemctl restart ModemManager'
    os.system(cmd)

    # Do not perform further actions unless the service ModemManager is active.
    t = delay  # sec
    isActive = False
    while (t > 0) and (isActive is False):
        if os.system('systemctl -q is-active ModemManager') == 0:
            isActive = True
        else:
            sleep(1)
            t -= 1

    assert isActive is True, \
      'Service "ModemManager" has been restarted, but it is still unactive after \"{}\" seconds.'.format(delay)

    # Not all modems support reset operation. See: man mmcli.
    # The operation is supported on:
    #   Dell Wireless D5510
    #
    # The operation CANNOT be performed on:
    #   HSPA USB MODEM,       USB ID: unknown,      equipment id: '358061030025688'
    #   Samsung SGH-Z810,     USB ID: 04e8:6601,    equipment id: '354326020570702'


# Play a game with resetting the modem and entering the PIN.
def test_modem():
    for i in range(1,4):
        mi = get_1st_modem_index()  # integer value
        si = get_sim_index(mi)  # integer value
        print('Modem index: {}'.format(mi))
        print('SIM card index: {}'.format(si))
        enable_pin(si, '1234')
        print('Reset modem with index: {}'.format(mi))
        reset_modem(mi, 15)
        sleep(30)  # delay after reset
        # We assume that PIN code is expected.
        send_pin(sim_index=si, PIN='1234')

        result = is_modem_connected(mi)
        if result is True:
            print('The modem is connected to the mobile broadband network.OK.')
            disable_pin(si, '1234')
        else:
            disable_pin(si, '1234')
            raise Exception('The modem is not connected to the mobile broadband network.FAIL.')


# When a SIM card is locked, you can see in the system journal:
# 'SIM PUK required'
