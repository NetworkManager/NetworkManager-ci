from nmci import dbus
from nmci import process
from nmci import util


class _NMUtil:
    def get_metered(self):
        return dbus.get_property(
            bus_name="org.freedesktop.NetworkManager",
            object_path="/org/freedesktop/NetworkManager",
            interface_name="org.freedesktop.NetworkManager",
            property_name="Metered",
            reply_type=dbus.REPLY_TYPE_U,
        )

    def nm_pid(self):
        pid = 0
        service_pid = process.systemctl("show -pMainPID NetworkManager.service")
        if service_pid.returncode == 0:
            pid = int(service_pid.stdout.split("=")[-1])
        if not pid:
            pgrep_pid = process.run("pgrep NetworkManager")
            if pgrep_pid.returncode == 0:
                pid = int(pgrep_pid.stdout)
        return pid

    def wait_for_nm_pid(self, seconds=10):
        timeout = util.start_timeout(seconds)
        while timeout.loop_sleep(0.3):
            pid = self.nm_pid()
            if pid:
                return pid
        raise util.ExpectedException(f"NetworkManager not running in {seconds} seconds")

    def nm_size_kb(self):
        pid = self.nm_pid()
        if not pid:
            raise util.ExpectedException(
                "unable to get mem usage, NetworkManager is not running!"
            )
        try:
            smaps = util.file_get_content(f"/proc/{pid}/smaps")
        except Exception as e:
            raise util.ExpectedException(
                f"unable to get mem usage for NetworkManager with pid {pid}: {e}"
            )
        memsize = 0
        for line in smaps.data.strip("\n").split("\n"):
            fields = line.split()
            if not fields[0] in ("Private_Dirty:", "Swap:"):
                continue
            memsize += int(fields[1])
        return memsize
