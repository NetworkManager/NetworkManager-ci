import os
from subprocess import check_output, Popen, PIPE
import types
import re
from time import sleep


def get_modem_index(modem_model):
    regex = '(/org/freedesktop/ModemManager1/Modem/[0-9]+) (.*)'
    cmd = 'mmcli -L'
    try:
        cmd_output = check_output(cmd, shell=True)
    except:
        print('Error when searching for a modem with: {}.'.format(cmd))
        return -1

    mo = re.search(regex, cmd_output)
    if type(mo.group(1)) == types.NoneType or type(mo.group(2)) == types.NoneType:
        print('Searching with for modems with regex:\n{}\ndid not found any match.'.found(regex))
        return -1
    # Modem index should be here.
    modem_index = mo.group(1).strip().split('/')[5]
    # Modem manufacturer and model should be here.
    modem_info = mo.group(2).strip()

    if modem_info.find(modem_model) < 0:
        print('Modem model was not found.')
        return -1
    # Modem model was found.
    # Verify that this is a valid integer value.
    try:
        modem_index = int(modem_index)
    except:
        print('Invalid modem_index.')
        modem_index = -1

    return modem_index


def get_1st_modem_index():
    # Get the index of the 1st available modem from the list of 'mmcli -L'.
    # Note: Taht index can increase from 0 to N. This happens when the modem reinitializes.
    # It can happen that 1st modem has index > 0.
    """

    Found 1 modem:
    /org/freedesktop/ModemManager1/Modem/1 [Ericsson MBM] MBIM [0BDB:193E]

    """
    cmd = 'mmcli -L'
    cmd_output = check_output(cmd, shell=True)
    regex = '(/org/freedesktop/ModemManager1/Modem/[0-9]+) (.*)'
    mo = re.search(regex, cmd_output)
    if type(mo.group(1)) == types.NoneType:
        print('Searching with for modems with regex:\n{}\ndid not found any match.'.found(regex))
        return -1
    # Modem index should be here.
    modem_index = mo.group(1).strip().split('/')[5]

    # Verify that this is a valid integer value.
    try:
        modem_index = int(modem_index)
    except:
        print('Invalid modem_index.')
        modem_index = -1

    return modem_index


def get_sim_index(modem_index):
    # Find the index the SIM card of a modem.
    # On failure condition return -1 as SIM index, otherwise a positive interger.
    """
    Example:
    mmcli --modem $modem_index
    ...
       SIM      |           path: '/org/freedesktop/ModemManager1/SIM/$sim_index'
    ...
    """
    regex = 'SIM .*(path:.*/org/freedesktop/ModemManager1/SIM/[0-9]+)'
    cmd = 'mmcli --modem %s' % modem_index
    try:
        cmd_output = check_output(cmd, shell=True)
    except:
        print('Error when searching by modem index with:\n{}.'.format(cmd))
        return -1

    mo = re.search(regex, cmd_output)
    if type(mo.group(1)) == types.NoneType:
        print('No SIM card found by using regex:\n{}'.format(regex))
        return -1

    sim_index = mo.group(1).strip().split('/')[5]
    # Verify that sim_index is a valid interger.
    try:
        sim_index = int(sim_index)
    except:
        sim_index = -1

    return sim_index

def enable_pin(modem_index, sim_index, PIN):
    cmd = 'mmcli --modem {} --sim={} --enable-pin --pin={}'.format(modem_index, sim_index, PIN)
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


def send_pin(modem_index, sim_index, PIN):
    cmd = 'mmcli --modem {} --sim={} --pin={}'.format(modem_index, sim_index, PIN)
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
