from subprocess import check_output, Popen, PIPE
import types
import re


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
