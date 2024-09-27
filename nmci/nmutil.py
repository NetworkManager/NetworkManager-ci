import time

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _NMUtil:
    DEFAULT_TIMEOUT = 10

    def get_metered(self):
        """
        Retrieves metered property from NetworkManager.

        :return: metered property
        :rtype: int
        """
        return nmci.dbus.get_property(
            bus_name="org.freedesktop.NetworkManager",
            object_path="/org/freedesktop/NetworkManager",
            interface_name="org.freedesktop.NetworkManager",
            property_name="Metered",
            reply_type=nmci.dbus.REPLY_TYPE_U,
        )

    def get_ethernet_devices(self):
        """
        List all ethernet devices that are available in NetworkManager.

        :return: list of all available ethernet devices
        :rtype: list[str]
        """
        devs = nmci.process.nmcli("-g DEVICE,TYPE dev").strip().split("\n")
        ETHERNET = ":ethernet"
        eths = [d.replace(ETHERNET, "") for d in devs if d.endswith(ETHERNET)]
        return eths

    def nm_pid(self):
        """
        Retrieves NM process ID from system.

        :return: process id of NetworkManager
        :rtype: int
        """
        pid = 0
        service_pid = nmci.process.systemctl(
            "show -pMainPID NetworkManager.service",
            embed_combine_tag=nmci.embed.NO_EMBED,
        )
        if service_pid.returncode == 0:
            pid = int(service_pid.stdout.split("=")[-1])
        if not pid and not self.context_get_nm_stopped():
            pgrep_pid = nmci.process.run("pgrep NetworkManager")
            if pgrep_pid.returncode == 0:
                pid = int(pgrep_pid.stdout)
        return pid

    def wait_for_nm_pid(self, timeout=DEFAULT_TIMEOUT, old_pid=0, do_assert=True):
        """
        Waits for NetworkManager process to start and return its PID.

        :param timeout: maximum wait time, defaults to DEFAULT_TIMEOUT
        :type timeout: int, optional
        :param old_pid: old PID of NetworkManager process, defaults to 0
        :type old_pid: int, optional
        :param do_assert: if True, method will raise an exception if NM is not running, defaults to True
        :type do_assert: bool, optional
        :raises nmci.util.ExpectedException: NetworkManager is still running with old PID
        :raises nmci.util.ExpectedException: NetworkManager is not running in "timeout" seconds
        :return: PID of NetworkManager process
        :rtype: int
        """
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
        """
        Waits for NetworkManager bus to start.

        :param timeout: maximum wait time, defaults to DEFAULT_TIMEOUT
        :type timeout: int, optional
        :param do_assert: if True, method will raise an exception if NM bus is not running, defaults to True
        :type do_assert: bool, optional
        :raises nmci.util.ExpectedException: NetworkManager bus is not running in "timeout" seconds
        :return: True, if NM bus is running
        :rtype: bool
        """
        busctl_argv = [
            "busctl",
            "call",
            "org.freedesktop.NetworkManager",
            "/org/freedesktop/NetworkManager",
            "org.freedesktop.NetworkManager",
            "GetAllDevices",
        ]
        timeout = nmci.util.start_timeout(timeout)
        _, nm_ver = nmci.misc.nm_version_detect()
        ready_at_first_check = do_assert and nm_ver >= [1, 43, 5]
        nm_ver_str = ".".join(f"{i}" for i in nm_ver)
        while timeout.loop_sleep(0.1):
            if nmci.process.run_search_stdout(
                busctl_argv,
                "/org/freedesktop/NetworkManager",
                ignore_stderr=True,
                ignore_returncode=True,
                timeout=max(20, timeout.remaining_time() or 20),
            ):
                return True
            # We know first check was unsuccessful here, because of return above.
            if ready_at_first_check:
                raise nmci.util.ExpectedException(
                    "Bus was not ready on the first check on NM "
                    f"{nm_ver_str}, as it should be since NM 1.43.5"
                )
        if do_assert:
            raise nmci.util.ExpectedException(
                f"NetworkManager bus not running in {timeout.elapsed_time()} seconds"
            )
        return False

    def nm_size_kb(self):
        """
        Get the memory size of NetworkManager process in KB.

        :return: memory size of NetworkManager process in KB
        :rtype: int
        """
        valgrind = getattr(nmci.cext.context, "nm_valgrind_proc", None)
        if valgrind is not None:
            try:
                return nmci.cext.context.nm_valgrind_mem_size(valgrind.pid)
            except Exception as e:
                raise nmci.util.ExpectedException(
                    f"unable to get mem usage for NetworkManager in valgrind: {e}"
                )
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

    def context_set_nm_restarted(self, context=None, reset=False):
        """
        Set context.nm_restarted, which indicates that NetworkManager
        service was restarted during the test.

        Note that this parameter is currently not used anywhere,
        but it might be useful for detecting whether a PID change
        was expected or not (crash).

        :param context: behave context, defaults to None
        :type context: behave.runner.Context, optional
        :param reset: reset the context.nm_restarted flag, defaults to False
        :type reset: bool, optional
        """
        if context is None:
            context = nmci.cext.context
        if context is not None:
            if reset:
                context.nm_restarted = False
            else:
                context.nm_restarted = True

    def context_set_nm_stopped(self, context=None, reset=False):
        """
        Set context.nm_stopped, which indicates that NetworkManager
        service was stopped during the test.

        :param context: behave context, defaults to None
        :type context: behave.runner.Context, optional
        :param reset: reset the context.nm_stopped flag, defaults to False
        :type reset: bool, optional
        """
        if context is None:
            context = nmci.cext.context
        if context is not None:
            if reset:
                context.nm_stopped = False
            else:
                context.nm_stopped = True

    def context_get_nm_stopped(self, context=None):
        """
        Gets context.nm_stopped, which indicates that NetworkManager
        service was stopped during the test.

        :param context: behave context, defaults to None
        :type context: behave.runner.Context, optional
        :return: context.nm_stopped flag
        :rtype reset: bool
        """
        if context is None:
            context = nmci.cext.context
        if hasattr(context, "nm_stopped") and context.nm_stopped:
            ret = True
        else:
            ret = False
        return ret

    def add_NM_config(
        self,
        conf_value,
        conf_file,
        cleanup_priority=nmci.Cleanup.PRIORITY_FILE,
        op="restart",
    ):
        """
        Create NM configuration file, and properly clean it after scenario.

        :param conf_value: content of the config file
        :type conf_value: str or list(str)
        :param conf_file: path to the config file
        :type conf_file: str
        :param cleanup_priority: priority of the cleanup, defaults to PRIORITY_FILE
        :type cleanup_priority: int
        :param op: operation over NM service, can be 'restart', 'reload' or callable, defaults to 'restart'
        :type op: str or callable
        """
        if op == "restart":
            do_op = self.restart_NM_service
            nmci.cleanup.add_NM_config(
                conf_file,
                priority=cleanup_priority,
                schedule_nm_restart=True,
                schedule_nm_reload=False,
            )
        elif op == "reload":
            do_op = self.reload_NM_service
            nmci.cleanup.add_NM_config(
                conf_file,
                priority=cleanup_priority,
                schedule_nm_restart=False,
                schedule_nm_reload=True,
            )
        elif type(op) is type(lambda: True):
            do_op = op
            nmci.cleanup.add_callback(
                do_op, name="NM-config-additional-cleanup", priority=cleanup_priority
            )
            nmci.cleanup.add_NM_config(
                conf_file,
                priority=cleanup_priority,
                schedule_nm_restart=False,
                schedule_nm_reload=False,
            )
        else:
            assert False, "Operation must be `restart`, `reload` or callable function"

        nmci.util.file_set_content(conf_file, conf_value)
        do_op()

    def reload_NM_connections(self):
        """
        Wrapper around :code:`nmcli con reload`.
        """
        print("reload NM connections")
        nmci.process.nmcli("con reload")

    def reload_NM_service(self, synchronous=False):
        """
        Reloads the running NM service.

        :param synchronous: If True, method will wait for NM to finish reloading, defaults to False
        :type synchronous: bool, optional
        """
        print("reload NM service")
        if synchronous:
            # ExecReload= uses busctl and waits for a response.
            r = nmci.process.systemctl("reload NetworkManager.service")
            assert r.returncode == 0, f"systemctl reload NetworkManager failed with {r}"
            return
        # Send an async SIGHUP signal.
        nmci.process.run_stdout("pkill -HUP NetworkManager")
        self.wait_for_nm_bus(0)

    def restart_NM_service(self, reset=True, timeout=None):
        """
        Restarts the running NM service, or resets NM from failed state if `reset=True` is passed.

        :param reset: If True, NM will be restarted from failed state, defaults to True
        :type reset: bool, optional
        :param timeout: Maximum wait time for restart to happen, defaults to 15
        :type timeout: int, optional
        :return: True, if NM restarted successfully
        :rtype: bool
        """
        print("restart NM service")
        self.context_set_nm_restarted()
        self.context_set_nm_stopped(reset=True)
        if timeout is None:
            timeout = 15
        timeout = nmci.util.start_timeout(timeout)
        if reset:
            nmci.process.systemctl("reset-failed NetworkManager.service")
        r = nmci.process.systemctl("restart NetworkManager.service", timeout=timeout)
        nmci.cext.context.nm_pid = self.wait_for_nm_pid(timeout)
        self.wait_for_nm_bus(timeout)
        assert r.returncode == 0, f"systemctl start NetworkManager failed with {r}"

    def start_NM_service(self, pid_wait=True, reset=True, timeout=None):
        """
        Starts the NM service.

        :param pid_wait: If True, method will wait for NM to finish starting, defaults to True
        :type pid_wait: bool, optional
        :param reset: If True, NM will be started from failed state, defaults to True
        :type reset: bool, optional
        :param timeout: Max. wait-time for NM to start, defaults to DEFAULT_TIMEOUT
        :type timeout: int, optional
        :return: True, if NM started successfully
        :rtype: bool
        """
        print("start NM service")
        self.context_set_nm_restarted()
        if timeout is None:
            timeout = _NMUtil.DEFAULT_TIMEOUT
        timeout = nmci.util.start_timeout(timeout)
        if reset:
            nmci.process.systemctl("reset-failed NetworkManager.service")
        r = nmci.process.systemctl("start NetworkManager.service", timeout=timeout)
        assert r.returncode == 0, f"systemctl start NetworkManager failed with {r}"
        if pid_wait:
            nmci.cext.context.nm_pid = self.wait_for_nm_pid(timeout)
            self.wait_for_nm_bus(timeout)

    def stop_NM_service(self, timeout=60):
        """
        Stops the NM service.

        :param timeout: timeout for process to finish, defaults to 60
        :type timeout: int, optional
        :return: True, if NM stopped successfully
        :rtype: bool
        """
        print("stop NM service")
        self.context_set_nm_restarted()
        self.context_set_nm_stopped()
        nmci.cleanup.add_NM_service(operation="start")
        r = nmci.process.systemctl("stop NetworkManager.service", timeout=timeout)
        nmci.cext.context.nm_pid = 0
        assert r.returncode == 0, f"systemctl stop NetworkManager failed with {r}"

    def reboot_NM_service(self, timeout=None):
        """
        Reboots the NM service.

        :param timeout: Max. wait-time for NM to start, defaults to DEFAULT_TIMEOUT
        :type timeout: int, optional
        :return: True, if NM rebooted successfully
        :rtype: bool
        """
        timeout = nmci.util.start_timeout(timeout)

        self.stop_NM_service(timeout=timeout)

        links = nmci.ip.link_show_all()
        link_ifnames = [li["ifname"] for li in links]

        ifnames_to_delete = [
            "nm-bond",
            "nm-team",
            "nm-bridge",
            "team7",
            "bridge7",
            "bond-bridge",
            "dummy0",
            # for nmtui
            "bond0",
            "team0",
            # for vrf devices
            "vrf0",
            "vrf1",
            # for veths
            "veth11",
            "veth12",
            # for macsec
            "macsec0",
            "macsec_veth.42",
            # for vlan
            "ipvlan0",
        ]

        ifnames_to_down = [
            *[f"eth{i}" for i in range(1, 12)],
            "em1",
            # for sriov
            "p4p1",
            "sriov_device"
            # for loopback
            "lo",
        ]

        ifnames_to_flush = [
            *[f"eth{i}" for i in range(1, 12)],
            "em1",
            # for sriov
            "p4p1",
            "sriov_device",
            # for pppoe
            "test11",
            # for loopback
            "lo",
        ]

        for ifname in ifnames_to_delete:
            nmci.ip.link_delete(ifname=ifname, accept_nodev=True)

        # Delete everything but ovsbr0 (as that is used as external only)
        nmci.process.run(
            "for br in $(ovs-vsctl list-br |grep -v ovsbr0); do \
             ovs-vsctl del-br $br; \
             systemctl restart openvswitch; \
             sleep 3; done",
            ignore_stderr=True,
            shell=True,
            timeout=10,
        )

        for ifname in ifnames_to_down:
            if ifname in link_ifnames:
                nmci.ip.link_set(ifname=ifname, up=False)
                # We need to clean DNS records when shutting down devices
                if nmci.process.systemctl("is-active systemd-resolved").returncode == 0:
                    nmci.process.run(f"resolvectl revert {ifname}", ignore_stderr=True)

        for ifname in ifnames_to_flush:
            if ifname in link_ifnames:
                nmci.ip.address_flush(ifname=ifname)

        nmci.util.directory_remove("/var/run/NetworkManager/", recursive=True)

        # Bring back lo addresses
        nmci.process.run(
            ["ip", "addr", "add", "127.0.0.1/8", "dev", "lo"],
            ignore_stderr=True,
        )
        nmci.process.run(
            ["ip", "addr", "add", "::1/128", "dev", "lo"],
            ignore_stderr=True,
        )

        self.start_NM_service(timeout=timeout)

    def do_NM_service(self, operation, timeout=None):
        """
        Executes a given operation on the NM service.

        :param operation: operation to execute
        :type operation: str
        :param timeout: Max. wait-time for NM to start, defaults to DEFAULT_TIMEOUT
        :type timeout: int, optional
        :raises AssertionError: invalid operation
        """
        if operation == "reload":
            assert timeout is None
            self.reload_NM_service(synchronous=True)
        elif operation == "start":
            self.start_NM_service(timeout=timeout)
        elif operation == "restart":
            self.restart_NM_service(timeout=timeout)
        elif operation == "stop":
            self.stop_NM_service(timeout=timeout)
        elif operation == "reboot":
            self.reboot_NM_service(timeout=timeout)
        else:
            assert False, f"invalid operation do_NM_service({operation})"

    def dbus_props_for_dev(
        self,
        dev_obj_path,
        interface_name="org.freedesktop.NetworkManager.Device",
    ):
        """
        Retrieve all properties for a given device from dbus.

        :param dev_obj_path: device path
        :type dev_obj_path: str
        :param interface_name: name of the bus interface,
            defaults to "org.freedesktop.NetworkManager.Device"
        :type interface_name: str, optional
        :return: all properties of the device in dbus
        :rtype: Glib.Variant
        """
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
        """
        Retrieve all properties for a given active connection from dbus.

        :param ac_obj_path: path to the active connection
        :type ac_obj_path: str
        :param interface_name: name of the bus interface,
            defaults to "org.freedesktop.NetworkManager.Connection.Active"
        :type interface_name: str, optional
        :return: all properties of the connection from dbus
        :rtype: Glib.Variant
        """
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
        """
        Retrieves all properties of a given connection setting from dbus.

        :param settings_obj_path: path to the connection setting
        :type settings_obj_path: str
        :param interface_name: name of the bus interface,
            defaults to "org.freedesktop.NetworkManager.Settings.Connection"
        :type interface_name: str, optional
        :return: all properties of the specific connection setting from dbus
        :rtype: Glib.Variant
        """
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
        """
        Retrieves all settings of a given connection setting from dbus.

        :param settings_obj_path: path to the connection setting
        :type settings_obj_path: str
        :return: all settings of the specific connection setting from dbus
        :rtype: Glib.Variant
        """
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
        """
        Retrieves all IP configuration of a given connection setting from dbus.

        :param dbus_path: path to the connection setting
        :type dbus_path: str
        :param addr_family: address family, defaults to None
        :type addr_family: str, optional
        :raises Exception: address family not specified
        :raises Exception: address family not detected
        :return: all IP configuration of the specific connection setting from dbus
        :rtype: Glib.Variant
        """
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
                "filename": None,
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

            try:
                props = self.dbus_props_for_setting(c["DBUS-PATH"])
                c["filename"] = props["Filename"].get_string()
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
        """
        Call :code:`nmcli connection show` to get a list of profiles. It augments
        the result with directly fetched data from D-Bus (the fetched data
        is thus not in sync with the data fetched with the nmcli call).

        An alternative might be to use NMClient, which works hard to give
        a consistent result from one moment (race-free). That is not done
        here, but it also would be a different functionality.

        :param only_active: only show active connections, defaults to False
        :type only_active: bool, optional
        :param without_active_externally: only show active connections that are not activated externally, defaults to False
        :type without_active_externally: bool, optional
        :param name: only show connections with this name, defaults to None
        :type name: str, optional
        :param uuid: only show connections with this UUID, defaults to None
        :type uuid: str, optional
        :param setting_type: only show connections with this type, defaults to None
        :type setting_type: str, optional
        :return: list of connections
        :rtype: list
        """
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

        if name is not None:
            result = [d for d in result if nmci.util.str_matches(d["name"], name)]

        for d in result:
            try:
                d["active-connection"] = self.dbus_props_for_ac(d["CON-PATH"])
            except Exception:
                raise nmci.misc.HitRaceException()

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
        """
        Call :code:`nmcli device status` to get a list of profiles. It augments
        the result with directly fetched data from D-Bus (the fetched data
        is thus not in sync with the data fetched with the nmcli call).

        An alternative might be to use NMClient, which works hard to give
        a consistent result from one moment (race-free). That is not done
        here, but it also would be a different functionality.

        :param name: only show devices with this name, defaults to None
        :type name: str, optional
        :param device_type: only show devices with this type, defaults to None
        :type device_type: str, optional
        :param get_ipaddrs: fetch IP addresses for devices, defaults to False
        :type get_ipaddrs: bool, optional
        :return: list of devices
        :rtype: list
        """
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

    # TCP port used for mocking HTTP service with nm-cloud-setup tests
    # ("contrib/cloud/test-cloud-meta-mock.py")
    NMCS_MOCK_PORT = 19080
    NMCI_MOCK_BASE_URL = f"http://127.0.0.1:{NMCS_MOCK_PORT}"
    NMCI_MOCK_BASE_URL_NOWHERE = f"http://127.0.0.1:10404"

    NMCS_PROVIDERS = {
        "azure": {
            "env_enable": "NM_CLOUD_SETUP_AZURE",
            "env_mock": "NM_CLOUD_SETUP_AZURE_HOST",
        },
        "aliyun": {
            "env_enable": "NM_CLOUD_SETUP_ALIYUN",
            "env_mock": "NM_CLOUD_SETUP_ALIYUN_HOST",
        },
        "ec2": {
            "env_enable": "NM_CLOUD_SETUP_EC2",
            "env_mock": "NM_CLOUD_SETUP_EC2_HOST",
        },
        "gcp": {
            "env_enable": "NM_CLOUD_SETUP_GCP",
            "env_mock": "NM_CLOUD_SETUP_GCP_HOST",
        },
    }


_module = _NMUtil()
