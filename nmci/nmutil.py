import time

import nmci.dbus
import nmci.process
import nmci.util
import nmci.cext
import nmci.cleanup
import nmci.embed


class _NMUtil:

    DEFAULT_TIMEOUT = 10

    def get_metered(self):
        return nmci.dbus.get_property(
            bus_name="org.freedesktop.NetworkManager",
            object_path="/org/freedesktop/NetworkManager",
            interface_name="org.freedesktop.NetworkManager",
            property_name="Metered",
            reply_type=nmci.dbus.REPLY_TYPE_U,
        )

    def get_ethernet_devices(self):
        devs = nmci.process.nmcli("-g DEVICE,TYPE dev").strip().split("\n")
        ETHERNET = ":ethernet"
        eths = [d.replace(ETHERNET, "") for d in devs if d.endswith(ETHERNET)]
        return eths

    def nm_pid(self):
        pid = 0
        service_pid = nmci.process.systemctl(
            "show -pMainPID NetworkManager.service",
            embed_combine_tag=nmci.embed.NO_EMBED,
        )
        if service_pid.returncode == 0:
            pid = int(service_pid.stdout.split("=")[-1])
        if not pid:
            pgrep_pid = nmci.process.run("pgrep NetworkManager")
            if pgrep_pid.returncode == 0:
                pid = int(pgrep_pid.stdout)
        return pid

    def wait_for_nm_pid(self, timeout=DEFAULT_TIMEOUT, old_pid=0, do_assert=True):
        # If old_pid is non-zero, wait_for_nm_pid may exit wit 0
        timeout = nmci.util.start_timeout(timeout)
        pid = 0
        while timeout.loop_sleep(0.3):
            pid = self.nm_pid()
            if pid != old_pid:
                return pid
        if do_assert:
            if pid == old_pid:
                raise nmci.util.ExpectedException(
                    f"NetworkManager still running with old pid: {pid}"
                )
            else:
                raise nmci.util.ExpectedException(
                    f"NetworkManager not running in {timeout.elapsed_time()} seconds"
                )
        return pid

    def wait_for_nm_bus(self, timeout=DEFAULT_TIMEOUT, do_assert=True):
        busctl_argv = [
            "busctl",
            "call",
            "org.freedesktop.NetworkManager",
            "/org/freedesktop/NetworkManager",
            "org.freedesktop.NetworkManager",
            "GetAllDevices",
        ]
        timeout = nmci.util.start_timeout(timeout)
        while timeout.loop_sleep(0.1):
            if nmci.process.run_search_stdout(
                busctl_argv,
                "/org/freedesktop/NetworkManager",
                ignore_stderr=True,
                ignore_returncode=True,
                timeout=timeout.remaining_time(),
            ):
                return True
        if do_assert:
            raise nmci.util.ExpectedException(
                f"NetworkManager bus not running in {timeout.elapsed_time()} seconds"
            )
        return False

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
        nmci.process.run_stdout("pkill -HUP NetworkManager")
        timeout = nmci.util.start_timeout(self.DEFAULT_TIMEOUT)
        self.wait_for_nm_bus(timeout)

    def restart_NM_service(self, reset=True, timeout=15):
        print("restart NM service")
        timeout = nmci.util.start_timeout(timeout)
        if reset:
            nmci.process.systemctl("reset-failed NetworkManager.service")
        r = nmci.process.systemctl(
            "restart NetworkManager.service", timeout=timeout.remaining_time()
        )
        nmci.cext.context.nm_pid = self.wait_for_nm_pid(timeout)
        self.wait_for_nm_bus(timeout)
        return r.returncode == 0

    def start_NM_service(self, pid_wait=True, timeout=DEFAULT_TIMEOUT):
        print("start NM service")
        timeout = nmci.util.start_timeout(timeout)
        r = nmci.process.systemctl(
            "start NetworkManager.service", timeout=timeout.remaining_time()
        )
        if pid_wait:
            nmci.cext.context.nm_pid = self.wait_for_nm_pid(timeout)
            self.wait_for_nm_bus(timeout)
        return r.returncode == 0

    def stop_NM_service(self):
        print("stop NM service")
        nmci.cleanup.cleanup_add_NM_service(operation="start")
        r = nmci.process.systemctl("stop NetworkManager.service")
        nmci.cext.context.nm_pid = 0
        return r.returncode == 0

    def dbus_props_for_dev(
        self,
        dev_obj_path,
        interface_name="org.freedesktop.NetworkManager.Device",
    ):
        dev_obj_path = nmci.dbus.object_path_norm(
            dev_obj_path, "/org/freedesktop/NetworkManager/Devices"
        )
        if dev_obj_path is None:
            return None
        return nmci.dbus.get_all_properties(
            bus_name="org.freedesktop.NetworkManager",
            object_path=dev_obj_path,
            interface_name=interface_name,
        )

    def dbus_props_for_ac(
        self,
        ac_obj_path,
        interface_name="org.freedesktop.NetworkManager.Connection.Active",
    ):
        ac_obj_path = nmci.dbus.object_path_norm(
            ac_obj_path, "/org/freedesktop/NetworkManager/ActiveConnection"
        )
        if ac_obj_path is None:
            return None
        return nmci.dbus.get_all_properties(
            bus_name="org.freedesktop.NetworkManager",
            object_path=ac_obj_path,
            interface_name=interface_name,
        )

    def dbus_props_for_setting(
        self,
        settings_obj_path,
        interface_name="org.freedesktop.NetworkManager.Settings.Connection",
    ):
        settings_obj_path = nmci.dbus.object_path_norm(
            settings_obj_path, "/org/freedesktop/NetworkManager/Settings"
        )
        if settings_obj_path is None:
            return None
        return nmci.dbus.get_all_properties(
            bus_name="org.freedesktop.NetworkManager",
            object_path=settings_obj_path,
            interface_name=interface_name,
        )

    def dbus_get_settings(self, settings_obj_path):
        settings_obj_path = nmci.dbus.object_path_norm(
            settings_obj_path, "/org/freedesktop/NetworkManager/Settings"
        )
        if settings_obj_path is None:
            return None
        v = nmci.dbus.call(
            bus_name="org.freedesktop.NetworkManager",
            object_path=settings_obj_path,
            interface_name="org.freedesktop.NetworkManager.Settings.Connection",
            method_name="GetSettings",
            parameters=None,
            reply_type="(a{sa{sv}})",
        )
        v_con = v.get_child_value(0)

        settings = {}
        for k_con in v_con.keys():
            v_set = v_con.lookup_value(k_con)
            x_set = {}
            for k_set in v_set.keys():
                x_set[k_set] = v_set.lookup_value(k_set)
            settings[k_con] = x_set

        return settings

    def dbus_get_ip_config(self, dbus_path, addr_family=None):

        if isinstance(dbus_path, nmci.util.GLib.Variant):
            assert dbus_path.get_type_string() == "o"
            dbus_path = dbus_path.get_string()

        if dbus_path is None or dbus_path == "/":
            return None

        addr_family = nmci.ip.addr_family_norm(addr_family)
        af = nmci.ip.addr_family_num(addr_family, allow_none=True)

        try:
            dbus_path_as_num = int(dbus_path)
        except Exception:
            dbus_path_as_num = None

        if dbus_path_as_num is not None:
            if af is None:
                raise Exception(
                    f'Need to specify the address family when requesting unqualified IP config "{dbus_path}"'
                )
            p = f"/org/freedesktop/NetworkManager/IP{af}Config/{dbus_path_as_num}"
        else:
            if dbus_path.startswith(
                "/org/freedesktop/NetworkManager/IP4Config/"
            ) and af in [None, 4]:
                af = 4
                p = dbus_path
            elif dbus_path.startswith(
                "/org/freedesktop/NetworkManager/IP6Config/"
            ) and af in [None, 6]:
                af = 6
                p = dbus_path
            else:
                raise Exception(
                    f'Cannot detect the address family for D-Bus path "{dbus_path}"'
                )

        assert nmci.dbus.name_is_object_path(p, check=True)

        data = nmci.dbus.get_all_properties(
            bus_name="org.freedesktop.NetworkManager",
            object_path=p,
            interface_name=f"org.freedesktop.NetworkManager.IP{af}Config",
        )

        addr_family = nmci.ip.addr_family_norm(str(af))

        # Parse some of the fields and convert to a string, to make them easier
        # to handle.

        def _parse_addresses(v, addr_family):
            return nmci.ip.ipaddr_plen_norm(
                f"{v['address']}/{v['prefix']}", addr_family
            )

        data["_addresses"] = [
            _parse_addresses(v, addr_family) for v in data["AddressData"]
        ]

        def _parse_routes(v, addr_family):
            s = nmci.ip.ipaddr_plen_norm(f"{v['dest']}/{v['prefix']}", addr_family)
            if "next-hop" in v:
                s += " " + nmci.ip.ipaddr_norm(v["next-hop"], addr_family)
            s += " " + str(int(v["metric"]))
            if "table" in v:
                s += " table=" + str(int(v["table"]))
            return s

        data["_routes"] = [_parse_routes(v, addr_family) for v in data["RouteData"]]

        def _parse_nameservers(v, addr_family):
            return nmci.ip.ipaddr_norm(v["address"], addr_family)

        # "NameserverData" exists ~only~ since NetworkManager 1.14. We expect that to be there.
        # data["_nameservers"] = [
        #    _parse_nameservers(v, addr_family) for v in data["NameserverData"]
        # ]

        data["_searches"] = [str(v) for v in data["Searches"]]

        return data

    def _connection_show_1(
        self,
        only_active,
        without_active_externally,
        name,
        uuid,
        setting_type,
    ):
        argv = [
            "-g",
            "UUID,TYPE,TIMESTAMP,AUTOCONNECT,AUTOCONNECT-PRIORITY,READONLY,DBUS-PATH,ACTIVE,STATE,ACTIVE-PATH",
            "connection",
            "show",
        ]
        if only_active:
            argv += ["-a"]

        out = nmci.process.nmcli(argv, timeout=5)

        def _s_to_bool(s):
            if s == "yes":
                return True
            if s == "no":
                return False
            raise ValueError(f'Not a boolean value ("{s}")')

        def _parse_line(line):
            # all the fields we selected cannot have a ':'.
            # So the parsing below is expected to be mostly safe.
            #
            # It's horrible, nmcli has no output mode where we could safely parse the output
            # of free-text fields (or unknown fields). For example, such fields might have
            # a new line (boom) or they might contain colons (which "-g" will unhelpfully
            # escape as "\:".
            (
                x_uuid,
                x_type,
                x_timestamp,
                x_autoconnect,
                x_autoconnect_priority,
                x_readonly,
                x_dbus_path,
                x_active,
                x_state,
                x_active_path,
            ) = line.split(":")

            if not x_active_path:
                x_active_path = None
            if not x_state:
                x_state = None
            x_autoconnect = _s_to_bool(x_autoconnect)
            x_active = _s_to_bool(x_active)
            x_readonly = _s_to_bool(x_readonly)

            assert (
                not only_active or x_active
            ), f"expect only active connections with {line}"
            assert (x_active_path is not None) == x_active

            assert nmci.dbus.name_is_object_path(x_dbus_path)
            assert not x_active_path or nmci.dbus.name_is_object_path(x_active_path)

            return {
                "UUID": x_uuid,
                "name": None,
                "TYPE": x_type,
                "TIMESTAMP": int(x_timestamp),
                "timestamp-real": None,
                "AUTOCONNECT": x_autoconnect,
                "AUTOCONNECT-PRIORITY": x_autoconnect_priority,
                "READONLY": x_readonly,
                "DBUS-PATH": x_dbus_path,
                "ACTIVE": x_active,
                "STATE": x_state,
                "ACTIVE-PATH": x_active_path,
                "active-connection": None,
                "settings": None,
                "active-externally": False,
            }

        if out and out[-1] == "\n":
            out = out[:-1]

        result = [_parse_line(line) for line in out.split("\n")]

        if uuid is not None:
            result = [c for c in result if nmci.util.str_matches(c["UUID"], uuid)]
        if setting_type is not None:
            result = [
                c for c in result if nmci.util.str_matches(c["TYPE"], setting_type)
            ]

        # Fetch additional things that we could no safely parse from nmcli output above.
        # Doing this is racy, because we stitch together information that are fetched
        # at different times. Beware.
        for c in result:
            # nmcli prints also "TIMESTAMP-REAL", but we cannot safely parse that.
            # We also don't have easy access to the same locale/formatting. Hence,
            # the "timestamp-real" field won't be exactly the same as "TIMESTAMP-REAL"
            # from nmcli.
            c["timestamp-real"] = time.strftime("%c", time.localtime(c["TIMESTAMP"]))

            try:
                settings = self.dbus_get_settings(c["DBUS-PATH"])
                c["settings"] = settings
                c["name"] = settings["connection"]["id"].get_string()
            except Exception:
                raise nmci.misc.HitRaceException()

            if c["ACTIVE-PATH"] is not None:
                try:
                    ac = self.dbus_props_for_ac(c["ACTIVE-PATH"])
                except Exception:
                    raise nmci.misc.HitRaceException()
                c["active-connection"] = ac

                # check for NM_ACTIVATION_STATE_FLAG_EXTERNAL.
                if ac["StateFlags"].get_uint32() & 0x80:
                    c["active-externally"] = True

        if without_active_externally:
            result = [c for c in result if not c["active-externally"]]
        if name is not None:
            result = [c for c in result if nmci.util.str_matches(c["name"], name)]

        return result

    def connection_show(
        self,
        *,
        only_active=False,
        without_active_externally=False,
        name=None,
        uuid=None,
        setting_type=None,
    ):
        # Call `nmcli connection show` to get a list of profiles. It augments
        # the result with directly fetched data from D-Bus (the fetched data
        # is thus not in sync with the data fetched with the nmcli call).
        #
        # An alternative might be to use NMClient, which works hard to give
        # a consistent result from one moment (race-free). That is not done
        # here, but it also would be a different functionality.
        for i in range(100):
            # Fetching multiple parts together is racy. We retry when we
            # suspect a race.
            try:
                result1 = self._connection_show_1(
                    only_active,
                    without_active_externally,
                    name,
                    uuid,
                    setting_type,
                )
                result = self._connection_show_1(
                    only_active,
                    without_active_externally,
                    name,
                    uuid,
                    setting_type,
                )
                if result != result1:
                    raise nmci.misc.HitRaceException()
            except nmci.misc.HitRaceException:
                if i > 20:
                    raise
                continue
            break

        return result

    def _device_status_1(self, name, device_type, get_ipaddrs):
        argv = [
            "-g",
            "TYPE,STATE,IP4-CONNECTIVITY,IP6-CONNECTIVITY,DBUS-PATH,CON-UUID,CON-PATH",
            "device",
            "status",
        ]

        out = nmci.process.nmcli(argv, timeout=5)

        def _parse_line(line):
            # all the fields we selected cannot have a ':'.
            # So the parsing below is expected to be mostly safe.
            #
            # It's horrible, nmcli has no output mode where we could safely parse the output
            # of free-text fields (or unknown fields). For example, such fields might have
            # a new line (boom) or they might contain colons (which "-g" will unhelpfully
            # escape as "\:".
            (
                x_type,
                x_state,
                x_ip4_connectivity,
                x_ip6_connectivity,
                x_dbus_path,
                x_con_uuid,
                x_con_path,
            ) = line.split(":")

            if not x_con_uuid:
                x_con_uuid = None
            if not x_con_path:
                x_con_path = None
            if not x_state:
                x_state = None

            assert nmci.dbus.name_is_object_path(x_dbus_path)
            assert not x_con_path or nmci.dbus.name_is_object_path(x_con_path)

            return {
                "name": None,
                "TYPE": x_type,
                "STATE": x_state,
                "IP4-CONNECTIVITY": x_ip4_connectivity,
                "IP6-CONNECTIVITY": x_ip6_connectivity,
                "DBUS-PATH": x_dbus_path,
                "CON-UUID": x_con_uuid,
                "CON-PATH": x_con_path,
                "device": None,
                "active-connection": None,
            }

        if out and out[-1] == "\n":
            out = out[:-1]

        result = [_parse_line(line) for line in out.split("\n")]

        if device_type is not None:
            result = [
                d for d in result if nmci.util.str_matches(d["TYPE"], device_type)
            ]

        # Fetch additional things that we could no safely parse from nmcli output above.
        # Doing this is racy, because we stitch together information that are fetched
        # at different times. Beware.
        for d in result:
            try:
                device = self.dbus_props_for_dev(d["DBUS-PATH"])
                d["device"] = device
                d["name"] = device.get("Interface").get_string()
            except Exception:
                raise nmci.misc.HitRaceException()

            if d["CON-PATH"] is not None:
                try:
                    d["active-connection"] = self.dbus_props_for_ac(d["CON-PATH"])
                except Exception:
                    raise nmci.misc.HitRaceException()

        if name is not None:
            result = [d for d in result if nmci.util.str_matches(d["name"], name)]

        def _device_update_ipaddrs(device):
            ifname = device["name"]
            output = nmci.process.nmcli(
                ["-g", "IP4.ADDRESS,IP6.ADDRESS", "device", "show", ifname]
            )

            if output != "":
                lines = output.split("\n")
                assert len(lines) == 3, f'Unexpected output "{output}"'
                assert lines[2] == "", f'Unexpected output "{output}"'
                ip4, ip6, _ = lines
                ip4 = [a for a in ip4.split(" | ") if a]
                ip6 = [a.replace("\\:", ":") for a in ip6.split(" | ") if a]

                assert all(nmci.ip.ipaddr_plen_norm(s, "inet") == s for s in ip4)
                assert all(nmci.ip.ipaddr_plen_norm(s, "inet6") == s for s in ip6)
            else:
                ip4 = []
                ip6 = []

            device["ip4-addresses"] = ip4
            device["ip6-addresses"] = ip6

        if get_ipaddrs:
            for d in result:
                _device_update_ipaddrs(d)
            for d in result:
                d["ip4config"] = self.dbus_get_ip_config(
                    d["device"]["Ip4Config"], addr_family="4"
                )
                d["ip6config"] = self.dbus_get_ip_config(
                    d["device"]["Ip6Config"], addr_family="6"
                )

        return result

    def device_status(
        self,
        *,
        name=None,
        device_type=None,
        get_ipaddrs=False,
    ):
        # Call `nmcli device status` to get a list of profiles. It augments
        # the result with directly fetched data from D-Bus (the fetched data
        # is thus not in sync with the data fetched with the nmcli call).
        #
        # An alternative might be to use NMClient, which works hard to give
        # a consistent result from one moment (race-free). That is not done
        # here, but it also would be a different functionality.
        for i in range(100):
            # Fetching multiple parts together is racy. We retry when we
            # suspect a race.
            try:
                result1 = self._device_status_1(name, device_type, get_ipaddrs)
                result = self._device_status_1(name, device_type, get_ipaddrs)
                if result != result1:
                    raise nmci.misc.HitRaceException()
            except nmci.misc.HitRaceException:
                if i > 20:
                    raise
                continue
            break

        return result
