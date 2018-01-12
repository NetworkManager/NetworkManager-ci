from subprocess import check_output, Popen, PIPE
import types
import re

# Get the modem's index by provided manufacturer's name and model.
# Return and positive integer value if found. Otherwise return -1.
# Example
"""

Found 3 modems:
/org/freedesktop/ModemManager1/Modem/0 [Ericsson MBM] MBIM [0BDB:193E]
/org/freedesktop/ModemManager1/Modem/1 [Nokia Corporation] Nokia USB Modem 21M-02
/org/freedesktop/ModemManager1/Modem/2 [Zoom Inc.] Zoom 4595

"""

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
