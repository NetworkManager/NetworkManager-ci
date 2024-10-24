# pylint: disable=function-redefined,no-name-in-module
# type: ignore [no-redef]
import time
from behave import step

import nmci


@step("Mock NetworkManager service")
def mock_nm(context):
    # fail if already mocked
    assert not getattr(context, "nm_version", False), "NM daemon is already mocked"

    nmci.cleanup.add_NM_service(operation="start")

    # cleanup kill mocker
    def _cleanup_mocker():
        context.nm_mocker.kill(15)
        context.nm_mocker.expect(nmci.pexpect.EOF)

    nmci.cleanup.add_callback(_cleanup_mocker, name="Stop mocked NM", priority=-40)

    # get NM version
    import dbus

    bus = dbus.SystemBus()
    nm_proxy = bus.get_object(
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
    )
    nm_props_iface = dbus.Interface(nm_proxy, "org.freedesktop.DBus.Properties")
    context.nm_version = nm_props_iface.Get("org.freedesktop.NetworkManager", "Version")

    # stop NM & start mocker
    nmci.nmutil.stop_NM_service()
    context.nm_mocker = nmci.pexpect.pexpect_service(
        "python3l -m dbusmock --system --template networkmanager"
    )

    # wait for mocker to appear on the bus
    nm_bus_owner = None
    while not nm_bus_owner:
        try:
            nm_bus_owner = bus.get_name_owner("org.freedesktop.NetworkManager")
        except dbus.exceptions.DBusException:
            time.sleep(0.01)
            continue


@step('Set version of the mocked NM to "{v}"')
def mock_nm_ver(context, v):
    assert getattr(
        context, "nm_version"
    ), "Version of actual NM daemon isn't in the context. Is NM mocked?"
    assert getattr(
        context, "nm_mocker"
    ), "pexpect service of NM mocker isn't in the context. Is NM mocked?"

    import dbus

    bus = dbus.SystemBus()
    nm_proxy = bus.get_object(
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
    )
    nm_props_iface = dbus.Interface(nm_proxy, "org.freedesktop.DBus.Properties")

    if v == "lower":
        success = False
        new_ver = context.nm_version.split(".")
        for i in reversed(range(len(new_ver))):
            try:
                new_ver_i = int(new_ver[i]) - 1
            except ValueError:
                continue
            if 0 > new_ver_i:
                continue
            new_ver[i] = str(new_ver_i)
            new_ver = ".".join(new_ver)
            success = True
            break
        assert (
            success
        ), "Couldn't find a numeric part of version number larger than 0 to decrement"
    elif v == "higher":
        success = False
        new_ver = context.nm_version.split(".")
        for i in reversed(range(len(new_ver))):
            try:
                new_ver_i = int(new_ver[i]) + 1
            except ValueError:
                continue
            new_ver[i] = str(new_ver_i)
            new_ver = ".".join(new_ver)
            success = True
            break
        assert success, "Couldn't find a numeric part of version number to increment"
    else:
        new_ver = v

    nm_props_iface.Set(
        "org.freedesktop.NetworkManager", "Version", dbus.String(new_ver)
    )
