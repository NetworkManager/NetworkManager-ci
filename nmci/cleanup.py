import os
import time
import re

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


UNIQ_TAG_DISTINCT = object()

PRIORITY_NM_SERVICE_START = -30
PRIORITY_CALLBACK_DEFAULT = 0
PRIORITY_TAG = 10
PRIORITY_CONNECTION = 20
PRIORITY_SYSCTL = 25
PRIORITY_NAMESPACE = 30
PRIORITY_IFACE_DELETE = 30
PRIORITY_MPTCP = 30
PRIORITY_IFACE_RESET = 31
PRIORITY_PEXPECT_SERVICE = 40
PRIORITY_NFT_DEFAULT = 40
PRIORITY_NFT_OTHER = 41
PRIORITY_UDEV_RULE = 50
PRIORITY_FILE = 70
PRIORITY_NM_SERVICE_RESTART = 200
PRIORITY_UDEV_UPDATE = 300


class _Cleanup:
    class Cleanup:
        UNIQ_TAG_DISTINCT = UNIQ_TAG_DISTINCT

        PRIORITY_NM_SERVICE_START = PRIORITY_NM_SERVICE_START
        PRIORITY_CALLBACK_DEFAULT = PRIORITY_CALLBACK_DEFAULT
        PRIORITY_TAG = PRIORITY_TAG
        PRIORITY_CONNECTION = PRIORITY_CONNECTION
        PRIORITY_SYSCTL = PRIORITY_SYSCTL
        PRIORITY_NAMESPACE = PRIORITY_NAMESPACE
        PRIORITY_IFACE_DELETE = PRIORITY_IFACE_DELETE
        PRIORITY_MPTCP = PRIORITY_MPTCP
        PRIORITY_IFACE_RESET = PRIORITY_IFACE_RESET
        PRIORITY_PEXPECT_SERVICE = PRIORITY_PEXPECT_SERVICE
        PRIORITY_NFT_DEFAULT = PRIORITY_NFT_DEFAULT
        PRIORITY_NFT_OTHER = PRIORITY_NFT_OTHER
        PRIORITY_UDEV_RULE = PRIORITY_UDEV_RULE
        PRIORITY_FILE = PRIORITY_FILE
        PRIORITY_NM_SERVICE_RESTART = PRIORITY_NM_SERVICE_RESTART
        PRIORITY_UDEV_UPDATE = PRIORITY_UDEV_UPDATE

        def __init__(
            self,
            callback=None,
            name=None,
            unique_tag=None,
            priority=PRIORITY_CALLBACK_DEFAULT,
            also_needs=None,
            args=None,
        ):
            """Generic cleanup

            :param callback: cleanup method to be called, defaults to None
            :type callback: callable, optional
            :param name: human readable description, defaults to None
            :type name: str, optional
            :param unique_tag: comparison key to merge duplicit cleanups, by default, all instances of Cleanup are considered distinct, all instances of descendant classes are considered equal
            :type unique_tag: object, optional
            :param priority: defines order in which the cleanups are executed, defaults to PRIORITY_CALLBACK_DEFAULT
            :type priority: int, optional
            :param also_needs: dependent cleanups, should be callable returning iterable of Cleanup objects, defaults to None
            :type also_needs: callable, optional
            :param args: arguments for callback
            :type args: dic, optional
            """
            self.name = name
            if unique_tag is UNIQ_TAG_DISTINCT or (
                unique_tag is None and type(self) is _Cleanup.Cleanup
            ):
                # This instance only compares equal to itself.
                self.unique_tag = (id(self),)
            elif unique_tag is None:
                self.unique_tag = (type(self),)
            else:
                self.unique_tag = ("arg", type(self), *unique_tag)
            self.args = args or {}
            self.priority = priority
            self._callback = callback
            self._also_needs = also_needs
            self._do_cleanup_called = False

            _module._cleanup_add(self)

        def also_needs(self):
            """Dependent cleanups, should return iterable of Cleanup instances.

            Those cleanups will be enqueued *after* the current one
            (however, self.priority will be still honored.

            :return: tuple of Cleanup
            :rtype: iterable
            """
            if self._also_needs is None:
                return ()
            return self._also_needs()

        def do_cleanup(self):
            """This is called automatically after scenario. Do not call at other places."""
            assert not self._do_cleanup_called
            self._do_cleanup_called = True
            t = time.monotonic()
            print(f"cleanup action {self.name} (priority {self.priority}) ...", end="")
            try:
                self._do_cleanup()
            except Exception as e:
                print(f" failed ({e}) in {(time.monotonic() - t):.3f}s")
                raise
            print(f" passed in {(time.monotonic() - t):.3f}s")

        def _do_cleanup(self):
            if self._callback is None:
                raise NotImplementedError("cleanup not implemented")
            self._callback(**self.args)

    class CleanupConnection(Cleanup):
        def __init__(self, con_name, qualifier=None, priority=PRIORITY_CONNECTION):
            """Cleanup NetworkManager connection

            :param con_name: name or UUID of the connection to cleanup
            :type con_name: str
            :param qualifier: optional qualifier ('id' or 'uuid'), defaults to None
            :type qualifier: str, optional
            :param priority: cleanup priority, defaults to PRIORITY_CONNECTION
            :type priority: int, optional
            """
            self.con_name = con_name
            self.qualifier = qualifier
            super().__init__(
                name=f"nmcli-connection-{con_name}",
                unique_tag=(con_name, qualifier),
                priority=priority,
            )

        def _do_cleanup(self):

            if self.qualifier is not None:
                args = [self.qualifier, self.con_name]
            else:
                args = [self.con_name]
            nmci.process.nmcli_force(["connection", "delete"] + args)

    class CleanupIface(Cleanup):
        def __init__(self, iface, op=None, priority=None):
            """Cleanup the network interafce

            :param iface: name of the interface
            :type iface: str or list of str
            :param op: operation, one of 'delete', 'ip-delete' or 'reset', defaults to 'reset' on eth0...eth10, 'delete' otherwise
            :type op: str, optional
            :param priority: cleanup priority, defaults to PRIORITY_IFACE_DELETE or PRIORITY_IFACE_RESET
            :type priority: int, optional
            """
            assert op in [None, "reset", "delete", "ip-delete"]
            if op is None:
                assert isinstance(iface, str)
                if re.match(r"^(eth[0-9]|eth10|lo)$", iface):
                    op = "reset"
                else:
                    op = "delete"
            if priority is None:
                if op == "reset":
                    priority = PRIORITY_IFACE_RESET
                else:
                    priority = PRIORITY_IFACE_DELETE

            if isinstance(iface, str):
                ifaces = [iface]
            else:
                ifaces = list(iface)

            if len(ifaces) == 1:
                name = f"iface-{op}-{ifaces[0]}"
            else:
                name = f"iface-{op}-{ifaces}"

            self.op = op
            self.ifaces = ifaces
            super().__init__(name=name, unique_tag=(self.ifaces, op), priority=priority)

        def _do_cleanup_one(self, iface):
            if self.op == "ip-delete":
                nmci.ip.link_delete(iface)
            elif self.op == "reset":
                nmci.veth.reset_hwaddr_nmcli(iface)
                # Why oh why was eth0 filtered out?
                # if iface != "eth0":
                nmci.process.run(["ip", "addr", "flush", iface])
                time.sleep(0.1)
            else:
                assert self.op == "delete", f'Unexpected cleanup op "{self.op}"'
                nmci.process.nmcli_force(["device", "delete", iface])

        def _do_cleanup(self):
            error = None
            for iface in self.ifaces:
                try:
                    self._do_cleanup_one(iface)
                except Exception as e:
                    if error is None:
                        error = e
            if error is not None:
                raise error

    class CleanupSysctls(Cleanup):
        def __init__(self, sysctls_pattern, namespace=None):
            """Sysctl cleanup - reset to original value.

            :param sysctls_pattern: sysctl pattern to save
            :type sysctls_pattern: str
            :param namespace: name of namespace, defaults to None
            :type namespace: str, optional
            """

            cmd = ["sysctl", "-a", "--pattern", sysctls_pattern]
            if namespace:
                self.namespace = namespace
                cmd = ["ip", "netns", "exec", namespace, *cmd]
            else:
                self.namespace = None

            self.sysctls = nmci.process.run_stdout(cmd)
            super().__init__(
                name=f"sysctls-pattern-{sysctls_pattern}",
                unique_tag=UNIQ_TAG_DISTINCT,
            )

        def _do_cleanup(self):

            if self.namespace is not None:
                if not os.path.isdir(f"/var/run/netns/{self.namespace}"):
                    return
                prefix = ["ip", "netns", "exec", self.namespace]
            else:
                prefix = []

            pexpect_cmd = " ".join([*prefix, "sysctl", "-p-"])
            sysctl_p = nmci.pexpect.pexpect_spawn(pexpect_cmd, check=True)
            sysctl_p.send(self.sysctls)
            sysctl_p.sendline("")
            sysctl_p.sendcontrol("d")
            sysctl_p.sendeof()

    class CleanupNamespace(Cleanup):
        """Namespace cleanup

        :param namespace: name of namespace
        :type namespace: str
        :param teardown: whether to do teardown testveth, defaults to True
        :type teardown: bool, optional
        :param priority: cleanup priority, defaults to PRIORITY_NAMESPACE
        :type priority: int, optional
        """

        def __init__(self, namespace, teardown=True, priority=PRIORITY_NAMESPACE):
            self.teardown = teardown
            self.namespace = namespace
            super().__init__(
                name=f"namespace-{namespace}-{'teardown' if teardown else ''}",
                unique_tag=(namespace, teardown),
                priority=priority,
            )

        def _do_cleanup(self):

            if self.teardown:
                nmci.veth.teardown_testveth(self.namespace)

            nmci.process.run(
                ["ip", "netns", "del", self.namespace],
                ignore_stderr=True,
            )

    class CleanupMptcpEndpoints(Cleanup):
        def __init__(self):
            """MPTCP endpoint cleanups"""

            # do not import by default, it takes non-trivial time to load
            from pyroute2 import (  # pylint: disable=import-outside-toplevel,no-name-in-module
                MPTCP,
            )

            mptcp = MPTCP()

            endpoints = [
                {k[19:].lower(): v for k, v in e["attrs"][0][1]["attrs"]}
                for e in mptcp.endpoint("show")
            ]
            # fields now have format accepted by endpoint("set") but we don't need all of them
            # include only fields we need to set
            self.mptcp_endpoints = [
                {
                    k: v
                    for k, v in endpoint.items()
                    if k in {"port", "id", "flags", "addr", "addr4", "addr6"}
                }
                for endpoint in endpoints
            ]

            super().__init__(name="MPTCP-endpoints", priority=PRIORITY_MPTCP)

        def _do_cleanup(self):
            # do not import by default, it takes non-trivial time to load
            from pyroute2 import (  # pylint: disable=import-outside-toplevel,no-name-in-module
                MPTCP,
            )

            mptcp = MPTCP()
            mptcp.endpoint("flush")
            for endpoint in self.mptcp_endpoints:
                mptcp.endpoint("add", **endpoint)

    class CleanupMptcpLimits(Cleanup):
        def __init__(self, namespace=None):
            """MPTCP limits cleanup

            :param namespace: name of namespace, defaults to None
            :type namespace: str, optional
            """
            self.namespace = namespace
            self.mptcp_limits = nmci.process.run_stdout(
                "ip mptcp limits", namespace=namespace
            )
            super().__init__(name="MPTCP-limits", priority=PRIORITY_MPTCP)

        def _do_cleanup(self):
            nmci.process.run(
                f"ip mptcp limits set {self.mptcp_limits}", namespace=self.namespace
            )

    class CleanupNft(Cleanup):
        def __init__(self, namespace=None, priority=None):
            """NFT rules cleanup

            :param namespace: name of namespace, defaults to None
            :type namespace: str, optional
            :param priority: cleanup priority, defaults to None
            :type priority: int, optional
            """
            if priority is None:
                if namespace is None:
                    priority = PRIORITY_NFT_DEFAULT
                else:
                    priority = PRIORITY_NFT_OTHER
            self.namespace = namespace
            super().__init__(
                name=f"nft-{'ns-'+namespace if namespace is not None else 'default'}",
                unique_tag=(namespace,),
                priority=priority,
            )

        def _do_cleanup(self):

            cmd = ["nft", "flush", "ruleset"]
            if self.namespace is not None:
                if not os.path.isdir(f"/var/run/netns/{self.namespace}"):
                    return
                cmd = ["ip", "netns", "exec", self.namespace] + cmd
            nmci.process.run(cmd)

    class CleanupUdevUpdate(Cleanup):
        def __init__(
            self,
            priority=PRIORITY_UDEV_UPDATE,
        ):
            """Udev update cleanup, calls updates and settles udev

            :param priority: cleanup priortiy, defaults to PRIORITY_UDEV_UPDATE
            :type priority: int, optional
            """
            super().__init__(name="udev-update", priority=priority)

        def _do_cleanup(self):

            nmci.util.update_udevadm()

    class CleanupFile(Cleanup):
        def __init__(
            self, *files, glob=None, priority=PRIORITY_FILE, name=None, unique_tag=None
        ):
            """File cleanup, removes file if exists.

            :param priority: cleanup priority, defaults to PRIORITY_FILE
            :type priority: int, optional
            :param name: description of cleanup, defaults to None
            :type name: str, optional
            :param glob: glob expression(s) of filenames
            :type glob: string or iterable of string, optional
            """
            self.files = list(files)

            if not glob:
                self.globs = []
            elif isinstance(glob, str):
                self.globs = [glob]
            else:
                self.globs = list(glob)

            if unique_tag is None:
                unique_tag = (self.files,)
            if name is None:
                if self.files and self.globs:
                    name = f"file-{self.files}-{self.globs}"
                elif self.globs:
                    name = f"file-globs-{self.globs}"
                else:
                    name = f"file-{self.files}"

            super().__init__(name=name, unique_tag=(files,), priority=priority)

        def _get_files(self):
            seen = set()
            for f in self.files:
                if f not in seen:
                    seen.add(f)
                    yield f
            if self.globs:
                import glob

                for g in self.globs:
                    for f in glob.glob(g):
                        if f not in seen:
                            seen.add(f)
                            yield f

        def _do_cleanup(self):
            error = None
            for f in self._get_files():
                try:
                    os.remove(f)
                except FileNotFoundError:
                    pass
                except Exception as e:
                    if error is None:
                        error = e
            if error is not None:
                raise error

    class CleanupUdevRule(CleanupFile):
        def __init__(self, rule, priority=PRIORITY_UDEV_RULE):
            """Udev rule file cleanup

            :param rule: name of file containing udev rule
            :type rule: str
            :param priority: cleanup priortiy, defaults to PRIORITY_UDEV_RULE
            :type priority: int, optional
            """
            super().__init__(rule, name=f"ude-rule-{rule}", priority=priority)

        def also_needs(self):
            return (_Cleanup.CleanupUdevUpdate(),)

    class CleanupNMService(Cleanup):
        def __init__(self, operation="restart", timeout=None, priority=None, name=None):
            """NetworkManager systemd service cleanup. Accepts start, restart, and reload.

            :param operation: operation on systemd service, one of 'start', 'restart' or 'reload'.
            :type operation: str
            :param priority: cleanup priortiy, defaults to None
            :type priority: int, optional
            """
            assert operation in ["start", "restart", "reload"]
            if priority is None:
                if operation == "start":
                    priority = PRIORITY_NM_SERVICE_START
                else:
                    priority = PRIORITY_NM_SERVICE_RESTART

            if name is None:
                name = f"NM-service-{operation}"

            self._operation = operation
            self._timeout = timeout
            super().__init__(
                name=name,
                priority=priority,
                unique_tag=(operation, timeout),
            )

        def _do_cleanup(self):
            nmci.nmutil.do_NM_service(operation=self._operation, timeout=self._timeout)

    class CleanupNMConfig(CleanupFile):
        def __init__(
            self,
            config_file,
            config_directory=None,
            priority=PRIORITY_FILE,
            schedule_nm_restart=True,
        ):
            """Cleanup NetworkManager config file and restart.

            :param config_file: NetworkManager config file name, either full path, or relative path accepted.
            :type config_file: str
            :param config_directory: NetworkManager config directory, one of 'etc', 'usr', 'run', defaults to 'etc'
            :type config_directory: str, optional
            :param priority: cleanup priority, defaults to PRIORITY_FILE
            :type priority: int, optional
            """
            if config_directory is not None:
                assert config_directory in _Cleanup.NM_CONF_DIRS
                config_file = _Cleanup.NM_CONF_DIRS[config_directory] + config_file
            elif not config_file.startswith("/"):
                config_file = _Cleanup.NM_CONF_DIRS["etc"] + config_file

            schedule_nm_restart = bool(schedule_nm_restart)
            self._schedule_nm_restart = schedule_nm_restart

            super().__init__(
                config_file,
                name=f"NM-config-{config_file}",
                priority=priority,
                unique_tag=(config_file, schedule_nm_restart),
            )

        def also_needs(self):
            if not self._schedule_nm_restart:
                return ()
            return (_Cleanup.CleanupNMService("restart"),)

    NM_CONF_DIRS = {
        "etc": "/etc/NetworkManager/conf.d/",
        "usr": "/usr/lib/NetworkManager/conf.d/",
        "run": "/var/run/NetworkManager/conf.d/",
    }

    # Aliases to remain compatible
    cleanup_add = Cleanup
    cleanup_add_connection = CleanupConnection
    cleanup_add_iface = CleanupIface
    cleanup_add_namespace = CleanupNamespace
    cleanup_add_nft = CleanupNft
    cleanup_add_ip_mptcp_limits = CleanupMptcpLimits
    cleanup_add_ip_mptcp_endpoints = CleanupMptcpEndpoints
    cleanup_add_sysctls = CleanupSysctls
    cleanup_file = CleanupFile
    cleanup_add_udev_rule = CleanupUdevRule
    cleanup_add_NM_service = CleanupNMService
    cleanup_nm_config = CleanupNMConfig

    def __init__(self):
        self._cleanup_lst = []
        self._cleanup_done = False

    def _cleanup_add(self, cleanup_action):
        """This is called during each Cleanup*.__init__ by default.

        :param cleanup_action: Cleanup instance object
        :type cleanup_action: Cleanup instance
        :raises Exception: raised if cleanups already done
        """
        if self._cleanup_done:
            raise Exception(
                "Cleanup already happend. Cannot schedule anew cleanup action"
            )

        newly_added = True

        # Find and delete duplicate (we will always prepend the
        # new action to the front (honoring the priority),
        # meaning that later added cleanups, will be executed
        # first.
        for i, a in enumerate(self._cleanup_lst):
            if a.unique_tag == cleanup_action.unique_tag:
                del self._cleanup_lst[i]
                newly_added = False
                break

        # Prepend, but still honor the priority.
        idx = 0
        for a in self._cleanup_lst:
            # Smaller priority number is preferred (and is
            # rolled back first).
            if a.priority >= cleanup_action.priority:
                # the cleanup actions are tracked in ascending priority
                # Once we found a >= priority we are done and have the
                # index found where to insert.
                break
            idx += 1
        self._cleanup_lst.insert(idx, cleanup_action)

        if newly_added:
            for c in cleanup_action.also_needs():
                self._cleanup_add(c)

    def process_cleanup(self):
        """Exectue the cleanups honoring its order.

        :return: list of Exceptions that hapenned during cleanups
        :rtype: list of Exception
        """
        ex = []

        for cleanup_action in nmci.util.consume_list(self._cleanup_lst):
            try:
                cleanup_action.do_cleanup()
            except Exception as e:
                ex.append(e)
        return ex


_module = _Cleanup()
