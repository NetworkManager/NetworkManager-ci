#!/usr/bin/python3
import gi
import subprocess
import sys
import uuid
gi.require_version('NM', '1.0')
from gi.repository import GLib,NM
from timeit import default_timer as timer

### Usage: ./activate.py <num-devices>

def create_profile(name):
    profile = NM.SimpleConnection.new()
    s_con = NM.SettingConnection.new()
    s_con.set_property(NM.SETTING_CONNECTION_ID, name)
    s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, name)
    s_con.set_property(NM.SETTING_CONNECTION_UUID, str(uuid.uuid4()))
    s_con.set_property(NM.SETTING_CONNECTION_TYPE, "802-3-ethernet")
    s_con.set_property(NM.SETTING_CONNECTION_AUTOCONNECT, False)

    s_wired = NM.SettingWired.new()

    s_ip4 = NM.SettingIP4Config.new()
    s_ip4.set_property(NM.SETTING_IP_CONFIG_METHOD, "auto")

    s_ip6 = NM.SettingIP6Config.new()
    s_ip6.set_property(NM.SETTING_IP_CONFIG_METHOD, "disabled")

    profile.add_setting(s_con)
    profile.add_setting(s_ip4)
    profile.add_setting(s_ip6)
    profile.add_setting(s_wired)

    return profile


def devices_states(client):
    states = {}
    devices = client.get_all_devices()
    for d in devices:
        if not d.get_iface().startswith("t-a"):
            continue
        state = d.get_state()
        states[state] = states.get(state, 0) + 1
    for s in sorted(states):
        print(" - {:>4} in {}".format(states[s], s))
    return states


def run():
    num_devices = 100
    if (len(sys.argv) >= 2):
        num_devices = int(sys.argv[1])

    print("### Number of devices: {}".format(num_devices))
    print("### Setup")
    subprocess.run(["./setup.sh", "{}".format(num_devices)])

    client = NM.Client.new(None)
    main_loop = GLib.MainLoop()

    print("### Delete existing connections")
    def delete_cb(con, result, data):
        nonlocal num_left
        try:
            con.delete_finish(result)
            print(" connection {} deleted".format(con.get_id()))
        except Exception as e:
            sys.stderr.write("Error deleting {}: {}\n".format(con.get_id(), e))
        num_left -= 1
        if num_left == 0:
            main_loop.quit()

    num_left = 0
    for con in client.get_connections():
        if con.get_id().startswith("t-a"):
            con.delete_async(None, delete_cb, con)
            num_left += 1

    if num_left > 0:
        main_loop.run()

    print("### Wait that all devices are disconnected")
    def check_state_cb(client):
        states = devices_states(client)
        print()
        if states.get(NM.DeviceState.DISCONNECTED, 0) == num_devices:
            main_loop.quit()
            return False
        else:
            return True

    GLib.timeout_add(1000, check_state_cb, client)
    main_loop.run()

    print("### Start logging")
    with open("/tmp/journal.txt","wb") as out:
        logger_pid = subprocess.Popen("journalctl -f -u NetworkManager", stdout=out, shell=True)

    print("### Create connections")
    def add_cb(client, result, con):
        nonlocal num_left
        try:
            client.add_connection_finish(result)
            print(" connection {} added".format(con.get_id()))
        except Exception as e:
            sys.stderr.write("Error adding {}: {}\n".format(con.get_id(), e))
        num_left -= 1
        if num_left == 0:
            main_loop.quit()

    num_left = 0
    for i in range(1, num_devices + 1):
        con = create_profile("t-a{}".format(i))
        client.add_connection_async(con, True, None, add_cb, con)
        num_left += 1

    main_loop.run()

    print("### Activate connections")
    def activate_cb(client, result, con):
        nonlocal num_left
        try:
            client.activate_connection_finish(result)
            print(" connection {} activation started".format(con.get_id()))
        except Exception as e:
            sys.stderr.write("Error activating {}: {}\n".format(con.get_id(), e))
        num_left -= 1
        if num_left == 0:
            main_loop.quit()

    num_left = 0
    for i in range(1, num_devices + 1):
        con = client.get_connection_by_id("t-a{}".format(i))
        client.activate_connection_async(con, None, None, None, activate_cb, con)
        num_left += 1

    main_loop.run()

    print("### Wait that all devices activate")
    start_time = timer()
    def check_state_cb(client):
        states = devices_states(client)
        print()
        if states.get(NM.DeviceState.ACTIVATED, 0) == num_devices:
            main_loop.quit()
            return False
        else:
            if (timer() - start_time) > 120:
                print("### Timeout")
                sys.exit(1)
            return True

    GLib.timeout_add(1000, check_state_cb, client)
    main_loop.run()
    logger_pid.terminate()

    print("### Completed in {:d} seconds".format(int(timer() - start_time)))


if __name__ == "__main__":
    run()
