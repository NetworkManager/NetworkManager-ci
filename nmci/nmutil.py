import time

import nmci.dbus
import nmci.process
import nmci.util
import nmci.cext
import nmci.cleanup


class _NMUtil:
    def get_metered(self):
        return nmci.dbus.get_property(
            bus_name="org.freedesktop.NetworkManager",
            object_path="/org/freedesktop/NetworkManager",
            interface_name="org.freedesktop.NetworkManager",
            property_name="Metered",
            reply_type=nmci.dbus.REPLY_TYPE_U,
        )

    def nm_pid(self):
        pid = 0
        service_pid = nmci.process.systemctl(
            "show -pMainPID NetworkManager.service", do_embed=False
        )
        if service_pid.returncode == 0:
            pid = int(service_pid.stdout.split("=")[-1])
        if not pid:
            pgrep_pid = nmci.process.run("pgrep NetworkManager")
            if pgrep_pid.returncode == 0:
                pid = int(pgrep_pid.stdout)
        return pid

    def wait_for_nm_pid(self, seconds=10):
        timeout = nmci.util.start_timeout(seconds)
        while timeout.loop_sleep(0.3):
            pid = self.nm_pid()
            if pid:
                return pid
        raise nmci.util.ExpectedException(
            f"NetworkManager not running in {seconds} seconds"
        )

    def nm_size_kb(self):
        pid = self.nm_pid()
        if not pid:
            raise nmci.util.ExpectedException(
                "unable to get mem usage, NetworkManager is not running!"
            )
        try:
            smaps = nmci.util.file_get_content(f"/proc/{pid}/smaps")
        except Exception as e:
            raise nmci.util.ExpectedException(
                f"unable to get mem usage for NetworkManager with pid {pid}: {e}"
            )
        memsize = 0
        for line in smaps.data.strip("\n").split("\n"):
            fields = line.split()
            if not fields[0] in ("Private_Dirty:", "Swap:"):
                continue
            memsize += int(fields[1])
        return memsize

    def reload_NM_connections(self):
        print("reload NM connections")
        nmci.process.nmcli("con reload")

    def reload_NM_service(self):
        print("reload NM service")
        time.sleep(0.5)
        nmci.process.run_stdout("pkill -HUP NetworkManager")
        time.sleep(1)

    def restart_NM_service(self, reset=True, timeout=10):
        print("restart NM service")
        if reset:
            nmci.process.systemctl("reset-failed NetworkManager.service")
        r = nmci.process.systemctl("restart NetworkManager.service", timeout=timeout)
        nmci.cext.context.nm_pid = self.wait_for_nm_pid(10)
        return r.returncode == 0

    def start_NM_service(self, pid_wait=True, timeout=10):
        print("start NM service")
        r = nmci.process.systemctl("start NetworkManager.service", timeout=timeout)
        if pid_wait:
            nmci.cext.context.nm_pid = self.wait_for_nm_pid(10)
        return r.returncode == 0

    def stop_NM_service(self):
        print("stop NM service")
        nmci.cleanup.cleanup_add_NM_service(operation="start")
        r = nmci.process.systemctl("stop NetworkManager.service")
        nmci.cext.context.nm_pid = 0
        return r.returncode == 0
