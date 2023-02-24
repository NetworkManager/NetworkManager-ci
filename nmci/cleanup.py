import os
import time
import re

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class Cleanup:
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

    def __init__(
        self,
        callback=None,
        name=None,
        unique_tag=None,
        priority=PRIORITY_CALLBACK_DEFAULT,
        also_needs=None,
        args=None,
    ):
        self.name = name
        if unique_tag is Cleanup.UNIQ_TAG_DISTINCT or (
            unique_tag is None and type(self) is Cleanup
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

    def also_needs(self):
        # Whether this cleanup requires additional cleanups.
        # Those cleanups will be enqueued *after* the current one
        # (however, self.priority will be still honored.
        if self._also_needs is None:
            return ()
        return self._also_needs()

    def do_cleanup(self):
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
    def __init__(self, con_name, qualifier=None, priority=Cleanup.PRIORITY_CONNECTION):
        self.con_name = con_name
        self.qualifier = qualifier
        Cleanup.__init__(
            self,
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
    def __init__(
        self,
        iface,
        op=None,
        priority=None,
    ):
        if op is None:
            if re.match(r"^(eth[0-9]|eth10|lo)$", iface):
                op = "reset"
            else:
                op = "delete"
        if priority is None:
            if op == "delete":
                priority = Cleanup.PRIORITY_IFACE_DELETE
            else:
                priority = Cleanup.PRIORITY_IFACE_RESET

        self.op = op
        self.iface = iface
        Cleanup.__init__(
            self,
            name=f"iface-{op}-{iface}",
            unique_tag=(iface, op),
            priority=priority,
        )

    def _do_cleanup(self):
        if self.op == "reset":
            nmci.veth.reset_hwaddr_nmcli(self.iface)
            if self.iface != "eth0":
                nmci.process.run(["ip", "addr", "flush", self.iface])
            return
        if self.op == "delete":
            nmci.process.nmcli_force(["device", "delete", self.iface])
            return
        raise Exception(f'Unexpected cleanup op "{self.op}"')


class CleanupSysctls(Cleanup):
    """
    The __init__() function accepts a single pattern passed to:
        sysctl -a --pattern PATTERN
    in order to avoid any processing of these values within NM CI
    """

    def __init__(self, sysctls_pattern, namespace=None):
        cmd = ["sysctl", "-a", "--pattern", sysctls_pattern]
        if namespace:
            self.namespace = namespace
            cmd = ["ip", "netns", "exec", namespace, *cmd]
        else:
            self.namespace = None

        self.sysctls = nmci.process.run_stdout(cmd)
        Cleanup.__init__(
            self,
            name=f"sysctls-pattern-{sysctls_pattern}",
            unique_tag=Cleanup.UNIQ_TAG_DISTINCT,
        )

    def _do_cleanup(self):
        if self.namespace is not None:
            if not os.path.isdir(f"/var/run/netns/{self.namespace}"):
                return
            prefix = ["ip", "netns", "exec", self.namespace]
        else:
            prefix = []

        pexpect_cmd = " ".join([*prefix, "sysctl", f"-p-"])
        sysctl_p = nmci.pexpect.pexpect_spawn(pexpect_cmd, check=True)
        sysctl_p.send(self.sysctls)
        sysctl_p.sendline("")
        sysctl_p.sendcontrol("d")
        sysctl_p.sendeof()


class CleanupNamespace(Cleanup):
    def __init__(
        self,
        namespace,
        teardown=True,
        priority=Cleanup.PRIORITY_NAMESPACE,
    ):
        self.teardown = teardown
        self.namespace = namespace
        Cleanup.__init__(
            self,
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
        from pyroute2 import MPTCP

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

        super().__init__(self, name="MPTCP-endpoints", priority=Cleanup.PRIORITY_MPTCP)

    def _do_cleanup(self):
        from pyroute2 import MPTCP

        mptcp = MPTCP()
        mptcp.endpoint("flush")
        for endpoint in self.mptcp_endpoints:
            mptcp.endpoint("add", **endpoint)


class CleanupMptcpLimits(Cleanup):
    def __init__(self, namespace=None):
        self.namespace = namespace
        self.mptcp_limits = nmci.process.run_stdout(
            "ip mptcp limits", namespace=namespace
        )
        super().__init__(self, name="MPTCP-limits", priority=Cleanup.PRIORITY_MPTCP)

    def _do_cleanup(self):
        nmci.process.run(
            f"ip mptcp limits set {self.mptcp_limits}", namespace=self.namespace
        )


class CleanupNft(Cleanup):
    def __init__(self, namespace=None, priority=None):
        if priority is None:
            if namespace is None:
                priority = Cleanup.PRIORITY_NFT_DEFAULT
            else:
                priority = Cleanup.PRIORITY_NFT_OTHER
        self.namespace = namespace
        Cleanup.__init__(
            self,
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
        priority=Cleanup.PRIORITY_UDEV_UPDATE,
    ):
        Cleanup.__init__(
            self,
            name="udev-update",
            priority=priority,
        )

    def _do_cleanup(self):
        nmci.util.update_udevadm()


class CleanupFile(Cleanup):
    def __init__(
        self,
        *files,
        name=None,
        priority=Cleanup.PRIORITY_FILE,
    ):
        self.files = tuple(files)
        if name is None:
            name = f"file-{self.files}"
        Cleanup.__init__(
            self,
            name=name,
            unique_tag=(files,),
            priority=priority,
        )

    def _do_cleanup(self):
        for f in self.files:
            try:
                os.remove(f)
            except FileNotFoundError:
                pass


class CleanupUdevRule(CleanupFile):
    def __init__(
        self,
        rule,
        priority=Cleanup.PRIORITY_UDEV_RULE,
    ):
        CleanupFile.__init__(
            self,
            rule,
            name=f"udev-rule-{rule}",
            unique_tag=(rule,),
            priority=priority,
        )

    def also_needs(self):
        return (CleanupUdevUpdate(),)


class CleanupNMService(Cleanup):
    def __init__(self, operation, priority=None):
        assert operation in ["start", "restart", "reload"]
        if priority is None:
            if operation == "start":
                priority = Cleanup.PRIORITY_NM_SERVICE_START
            else:
                priority = Cleanup.PRIORITY_NM_SERVICE_RESTART
        self._operation = operation
        Cleanup.__init__(
            self,
            name=f"NM-service-{operation}",
            priority=priority,
            unique_tag=(operation,),
        )

    def _do_cleanup(self):
        if self._operation == "start":
            r = nmci.nmutil.start_NM_service()
        elif self._operation == "restart":
            r = nmci.nmutil.restart_NM_service()
        else:
            assert self._operation == "reload"
            nmci.nmutil.reload_NM_service()
            r = True
        assert r


class _Cleanup:
    def __init__(self):
        self._cleanup_lst = []
        self._cleanup_done = False

        self.Cleanup = Cleanup
        self.CleanupConnection = CleanupConnection
        self.CleanupIface = CleanupIface
        self.CleanupNamespace = CleanupNamespace
        self.CleanupNft = CleanupNft
        self.CleanupUdevRule = CleanupUdevRule
        self.CleanupNMService = CleanupNMService

    def _cleanup_add(self, cleanup_action):
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

    def cleanup_add(self, *a, **kw):
        self._cleanup_add(Cleanup(*a, **kw))

    def cleanup_add_connection(self, *a, **kw):
        self._cleanup_add(CleanupConnection(*a, **kw))

    def cleanup_add_iface(self, *a, **kw):
        self._cleanup_add(CleanupIface(*a, **kw))

    def cleanup_add_sysctls(self, *a, **kw):
        self._cleanup_add(CleanupSysctls(*a, **kw))

    def cleanup_add_namespace(self, *a, **kw):
        self._cleanup_add(CleanupNamespace(*a, **kw))

    def cleanup_add_ip_mptcp_endpoints(self, *a, **kw):
        self._cleanup_add(CleanupMptcpEndpoints(*a, **kw))

    def cleanup_add_ip_mptcp_limits(self, *a, **kw):
        self._cleanup_add(CleanupMptcpLimits(*a, **kw))

    def cleanup_add_nft(self, *a, **kw):
        self._cleanup_add(CleanupNft(*a, **kw))

    def cleanup_add_udev_rule(self, *a, **kw):
        self._cleanup_add(CleanupUdevRule(*a, **kw))

    def cleanup_add_NM_service(self, *a, **kw):
        self._cleanup_add(CleanupNMService(*a, **kw))

    def cleanup_file(self, *a, **kw):
        self._cleanup_add(CleanupFile(*a, **kw))

    def process_cleanup(self):
        ex = []

        for cleanup_action in nmci.util.consume_list(self._cleanup_lst):
            try:
                cleanup_action.do_cleanup()
            except Exception as e:
                ex.append(e)
        return ex


_module = _Cleanup()
