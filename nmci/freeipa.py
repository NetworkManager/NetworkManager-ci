# mypy: disable-error-code="no-redef,var-annotated"
import os
import shutil
import time

import nmci
from nmci.embed import TRACE_COMBINE_TAG

try:
    from functools import cached_property
except ImportError:
    _NOT_FOUND = object()

    class cached_property:
        def __init__(self, func):
            self.func = func
            self.attrname = None
            self.__doc__ = func.__doc__
            self.__module__ = func.__module__

        def __set_name__(self, owner, name):
            if self.attrname is None:
                self.attrname = name
            elif name != self.attrname:
                raise TypeError(
                    "Cannot assign the same cached_property to two different names "
                    f"({self.attrname!r} and {name!r})."
                )

        def __get__(self, instance, owner=None):
            if instance is None:
                return self
            if self.attrname is None:
                raise TypeError(
                    "Cannot use cached_property instance without calling __set_name__ on it."
                )
            try:
                cache = instance.__dict__
            except AttributeError:  # not all objects have __dict__ (e.g. class defines slots)
                msg = (
                    f"No '__dict__' attribute on {type(instance).__name__!r} "
                    f"instance to cache {self.attrname!r} property."
                )
                raise TypeError(msg) from None
            val = cache.get(self.attrname, _NOT_FOUND)
            if val is _NOT_FOUND:
                val = self.func(instance)
                try:
                    cache[self.attrname] = val
                except TypeError:
                    msg = (
                        f"The '__dict__' attribute on {type(instance).__name__!r} instance "
                        f"does not support item assignment for caching {self.attrname!r} property."
                    )
                    raise TypeError(msg) from None
            return val


"""
issues:
* is podman presence universal?
    --> it is, we install it in envsetup
* ipa server install time (is it?)
    * how to check from outside of the container?
    --> checking the log
* DNS
    * use integrated dns
    * set up static IP
    * set up local resolver to search nmci.test at IPA's IP
* podman networking
    * freeipa-container runs with default 'podman' network
    * can it be automated to auto-join vethsetup, and/or for vethsetup to include it?
    * IP range
* podman networking (TODO)
    * define custom network, set fixed IP range
    * podman veth:
        * unmanage?
        * set it in NM with dns search?
        --> somehow works with default network without issues?
    * dns search: requires local resolver --> run with systemd-resolved
* installation
    * use unattended installation
        * `podman pull` a base image
        * `podman create` a container based off of a freeipa-container image
            podman create -ti -h ipa.nmci.test --read-only -v /var/lib/ipa-data:/data:Z quay.io/freeipa/freeipa-server:centos-9-stream exit-on-finished $(< ipa-server-options )
        * `podman start` the container
        * wait for `/var/lib/ipa-data/var/log/ipaserver-install.log` log file to appear
        * wait until there's `The ipa-server-install command was` string in the log file
        * kill the container. Now the container can be started
    --> done
* client installation
    * we need just certmonger. For certmonger, we need:
        - /etc/krb5.keytab
        - /etc/krb5.conf.d/nmci.conf
        - /etc/ipa/default.conf
        - /etc/ipa/ca.crt
    --> done

future issues:
* (re)use vethsetup NS
    * maybe the "easiest": containerize vethsetup, run freeipa and vethsetup in the same pod --> same podman network
* time to install

TODO now:
    * document exposed methods
"""


def __getattr__(attr):
    return getattr(_module, attr)


class _FreeIPA:
    def __init__(self):
        self._BASE_IMAGE = "quay.io/freeipa/freeipa-server:centos-9-stream"
        # no custom domains are effectively supported in netavark/aardvark
        # ... but maybe one they <cont>.<network name> will be resolvable?
        self.PODMAN_NETWORK = "nmci.test"
        self._NMCI_NETWORK = {
            "name": self.PODMAN_NETWORK,
            "dns_enabled": True,
            "subnets": [
                {
                    "gateway": "192.168.110.1",
                    "subnet": "192.168.110.0/24",
                    "lease_range": {
                        "start_ip": "192.168.110.10",
                        "end_ip": "192.168.110.254",
                    },
                }
            ],
        }
        self.NMCI_IP = self._NMCI_NETWORK["subnets"][0]["gateway"]
        self.IPA_SERVER_IP = "192.168.110.2"
        self.PODMAN_NETWORK_DNS = self.NMCI_IP
        self.IPA_REALM = self.PODMAN_NETWORK.upper()
        self.IPA_BASE_DN = ",".join(["dc=" + i for i in self.PODMAN_NETWORK.split(".")])
        self.CONT_NAME = "freeipa"
        self.IPA_NAME = self.CONT_NAME + "." + self.PODMAN_NETWORK
        self.NMCI_NAME_ORIG = nmci.process.run_stdout("hostname").strip()
        self.NMCI_NAME = nmci.process.run_stdout("hostname --short").strip()
        self.NMCI_FQDN = self.NMCI_NAME + "." + self.PODMAN_NETWORK
        self._IPA_DATADIR = "/var/lib/ipa-data"
        self._IPA_PASSWORD = "ipa_password"
        self._time_cont_started = None
        self._CONT_OPTS = [
            "--hostname",
            self.IPA_NAME,
            "--network",
            self.PODMAN_NETWORK,
            "--ip",
            self.IPA_SERVER_IP,
            "--read-only",
            "--volume",
            ":".join([self._IPA_DATADIR, "/data", "Z"]),
        ]

    @cached_property
    def _pc(self):
        from podman import PodmanClient

        return PodmanClient(base_url="unix:///run/podman/podman.sock")

    def _podman_network_setup(self):
        # * arrange aardvark search domain, if the wrapper isn't ready (and already used), we need:
        #   * aardvark must not be running
        #   * write the wrapper in /usr/local
        wrapper_file = "/usr/local/libexec/podman/aardvark-dns"
        wrapper_lines = [
            "#!/bin/sh",
            "export RUST_LOG=trace",
            f'exec /usr/libexec/podman/aardvark-dns -f {self.PODMAN_NETWORK} "${{@}}"',
        ]
        wrapper = "\n".join(wrapper_lines)
        if (
            not os.path.isfile(wrapper_file)
            or nmci.util.file_get_content_simple(wrapper_file) != wrapper
        ):
            os.makedirs(os.path.dirname(wrapper_file), exist_ok=True)
            aardvark_scope = os.path.basename(
                nmci.process.run_stdout(
                    "grep -rl aardvark /run/systemd/transient/",
                    ignore_returncode=True,
                    ignore_stderr=True,
                ).strip()
            )
            nmci.process.systemctl(["stop", aardvark_scope])
            nmci.util.file_set_content(wrapper_file, wrapper)
            nmci.process.run(["chmod", "+x", wrapper_file])
        # * add host entry to the network config, spec: https://github.com/containers/aardvark-dns/blob/main/config.md
        aardvark_config_file = os.path.join(
            "/run/containers/networks/aardvark-dns", self.PODMAN_NETWORK
        )
        aardvark_config_header = self.NMCI_IP
        aardvark_host_line = [
            "deadbeafcafecedebabefacedadafadedeadbeafcafecedebabefacedadafade",
            self.NMCI_IP,
            "",
            f"host,{self.NMCI_NAME}",
        ]
        aardvark_host_line = " ".join(aardvark_host_line)
        if os.path.isfile(aardvark_config_file):
            config_lines = nmci.util.file_get_content_simple(aardvark_config_file)
            if aardvark_host_line not in config_lines:
                config_lines.insert(1, aardvark_host_line)
                nmci.util.file_set_content(aardvark_config_file, config_lines)
        else:
            os.makedirs(os.path.dirname(aardvark_config_file), exist_ok=True)
            config_lines = [aardvark_config_header, aardvark_host_line]
            nmci.util.file_set_content(aardvark_config_file, config_lines)

        if not self._pc.networks.exists(self.PODMAN_NETWORK):
            self._pc.networks.create(**self._NMCI_NETWORK)

    def _cont_create(self):
        c = self._get_cont()
        if c:
            if c.image == self._pc.images.get(self._BASE_IMAGE):
                return
            # container exists but based off of a different image --> remove
            c.remove(force=True)
        nmci.process.run(
            [
                "podman",
                "create",
                *self._CONT_OPTS,
                "--name",
                self.CONT_NAME,
                self._BASE_IMAGE,
            ]
        )

    def _get_cont(self):
        c = None
        if self._pc.containers.exists(self.CONT_NAME):
            c = self._pc.containers.get(self.CONT_NAME)
        return c

    def _cont_start(self):
        cont = self._get_cont()
        if cont.status != "running":
            cont.start()

    def _cont_stop(self):
        cont = self._get_cont()
        if cont is not None and cont.status == "running":
            cont.stop()

    def _cont_remove(self):
        if self._pc.containers.exists(self.CONT_NAME):
            self._pc.containers.remove(self.CONT_NAME)

    def ipa_is_installed(self, req_success=True):
        try:
            conffirst_file = os.path.join(
                self._IPA_DATADIR, "var/log/ipa-server-configure-first.log"
            )
            conffirst_log = nmci.util.file_get_content_simple(conffirst_file)
            isi_file = os.path.join(self._IPA_DATADIR, "var/log/ipaserver-install.log")
            isi_log = nmci.util.file_get_content_simple(isi_file)
        except FileNotFoundError:
            return False
        if "FreeIPA server configured." in conffirst_log:
            return True
        elif not req_success and "The ipa-server-install command failed" in log:
            return True
        return False

    def _assert_ipa_install_finished(self):
        assert self.ipa_is_installed(req_success=False), "IPA not yet installed"

    def freeipa_exec_run(
        self, cmd, ignore_stderr=True, ignore_returncode=False, shell=True, **kw
    ):
        c = self._get_cont()
        time_measure = nmci.util.start_timeout()
        res = c.exec_run(cmd, demux=True, **kw)
        rc, r_stdout, r_stderr = res[0], res[1][0].decode(), res[1][1].decode()
        nmci.embed.embed_run(
            cmd,
            shell,
            rc,
            r_stdout,
            r_stderr,
            combine_tag=TRACE_COMBINE_TAG,
            elapsed_time=time_measure.elapsed_time(),
        )
        err_msg = [
            "",
            "STDOUT:",
            r_stdout,
            "",
            "STDERR:",
            r_stderr,
        ]
        assert not rc or ignore_returncode, "\n".join(
            [f"IPA {cmd} exited with non-zero returncode: {rc}", *err_msg]
        )
        assert not r_stderr or ignore_stderr, "\n".join(
            [f"IPA {cmd} wrote sth on stderr:", *err_msg]
        )
        return rc, r_stdout, r_stderr

    def freeipa_exec_run_code(self, cmd, **kw):
        kw["ignore_returncode"] = True
        res = self.freeipa_exec_run(cmd, **kw)
        return res[0]

    def freeipa_kinit_admin(self):
        kinit = nmci.pexpect.pexpect_spawn(
            f"podman exec -i '{self.CONT_NAME}' kinit admin"
        )
        kinit.expect("Password for admin@NMCI.TEST: ")
        kinit.sendline(self._IPA_PASSWORD)
        kinit.wait()
        return kinit

    def freeipa_run_ipa(self, cmd, kinit=True, **kw):
        if kinit:
            self.freeipa_kinit_admin()
        if isinstance(cmd, str):
            cmd = "ipa " + cmd
        elif isinstance(cmd, list):
            cmd = ["ipa", *cmd]
        else:
            raise TypeError(f"cmd needs to be of list or str types, was: {type(cmd)}")
        return self.freeipa_exec_run(cmd, **kw)

    def freeipa_run_ipa_code(self, cmd, kinit=True, **kw):
        kw["ignore_returncode"] = True
        kw["kinit"] = kinit
        res = self.freeipa_run_ipa(cmd, **kw)
        return res[0]

    def assert_ipa_services_running(self):
        assert self._get_cont() is not None, f"Container '{self.CONT_NAME}' not running"
        ipactl_status = self.freeipa_exec_run(["ipactl", "status"])[1]
        services = {
            k.strip(): v.strip()
            for (k, v) in [i.split(":") for i in ipactl_status.splitlines()]
        }
        not_running = {k: v for (k, v) in services.items() if v != "RUNNING"}
        assert not not_running, f"IPA services not running: {not_running}"
        return not not_running

    def ipa_container_exists(self):
        return self._pc.containers.exists(self.CONT_NAME)

    def _embed_ipa_server_install_logs(self, last_exception=None):
        for f in ["ipaserver-install.log", "ipaclient-install.log"]:
            m = f"IPA cont: {f}"
            p = os.path.join(self._IPA_DATADIR, "var/log", f)
            nmci.embed.embed_file_if_exists(m, p, fail_only=True)
        if last_exception:
            raise last_exception

    def install_ipa_server(self, reinstall=False):
        ipa_server_install_opts = [
            "--realm=" + self.IPA_REALM,
            "--ds-password=" + self._IPA_PASSWORD,
            "--admin-password=" + self._IPA_PASSWORD,
            "--no-ntp",
            "--unattended",
        ]
        tmp_cont_id = "ipa_install"
        if not reinstall and self.ipa_is_installed():
            return "Already installed"
        try:
            shutil.rmtree(self._IPA_DATADIR)
        except FileNotFoundError:
            pass
        os.makedirs(self._IPA_DATADIR, exist_ok=True)
        self._cont_remove()
        if self._pc.containers.exists(tmp_cont_id):
            c = self._pc.containers.get(tmp_cont_id)
            c.stop()
        # workarounds needed:
        #   - cli used because API couldn't work out the mounts/volumes correctly
        nmci.process.run(
            [
                "podman",
                "run",
                "--rm",
                "--name",
                tmp_cont_id,
                *self._CONT_OPTS,
                self._BASE_IMAGE,
                "exit-on-finished",
                *ipa_server_install_opts,
            ],
            timeout=360,
        )
        self._embed_ipa_server_install_logs()
        assert self.ipa_is_installed(), "IPA server not installed or install failed"

    def install_client(self, reinstall=False):
        OBJ_DIR = "nmci"
        KT_INSIDE = "/".join(["/data", OBJ_DIR, "host.keytab"])
        KT_FROM_HOST = "/".join([self._IPA_DATADIR, OBJ_DIR, "host.keytab"])
        krb5_conf = [
            "[libdefaults]",
            f" default_realm = {self.IPA_REALM}",
            " dns_lookup_realm = false",
            " dns_lookup_kdc = true",
            " rdns = false",
            " ticket_lifetime = 24h",
            " forwardable = true",
            " udp_preference_limit = 0",
            "",
            "[realms]",
            " NMCI.TEST = {",
            f"  kdc = {self.IPA_NAME}:88",
            f"  master_kdc = {self.IPA_NAME}:88",
            f"  kpasswd_server = {self.IPA_NAME}:464",
            f"  admin_server = {self.IPA_NAME}:749",
            "  default_domain = nmci.test",
            "}",
        ]
        ipa_conf = [
            "[global]",
            f"basedn = {self.IPA_BASE_DN}",
            f"realm = {self.IPA_REALM}",
            f"server = {self.IPA_NAME}",
            f"host = {self.NMCI_FQDN}",
            f"xmlrpc_uri = https://{self.IPA_NAME}/ipa/xml",
        ]
        if (
            not reinstall
            and os.path.isfile("/etc/ipa/ca.crt")
            and (
                nmci.util.file_get_content_simple("/etc/ipa/ca.crt")
                == nmci.util.file_get_content_simple(
                    self._IPA_DATADIR + "/etc/ipa/ca.crt"
                )
            )
            and os.path.isfile("/etc/ipa/default.conf")
            and os.path.isfile("/etc/krb5.keytab")
            and os.path.isfile("/etc/krb5.conf.d/nmci.conf")
            and self.freeipa_run_ipa_code(["user-find", "idm_user"]) == 0
        ):
            return

        os.makedirs("/".join([self._IPA_DATADIR, OBJ_DIR]), exist_ok=True)
        nmci.util.wait_for(
            self.assert_ipa_services_running, timeout=30, poll_sleep_time=5
        )
        self.freeipa_kinit_admin()
        self.freeipa_exec_run("klist")
        if self.freeipa_run_ipa_code(["host-find", self.NMCI_NAME]) == 0:
            self.freeipa_run_ipa(["host-del", self.NMCI_NAME])
        dnsrecord_find = ["dnsrecord-find", "nmci.test", f"--a-rec={self.NMCI_IP}"]
        if self.freeipa_run_ipa_code(dnsrecord_find) == 0:
            records = [
                i.split()[-1]
                for i in self.freeipa_run_ipa(dnsrecord_find)[1].splitlines()
                if "Record name:" in i
            ]
            for r in records:
                self.freeipa_run_ipa(
                    ["dnsrecord-del", self.PODMAN_NETWORK, r, "--del-all"],
                )
        self.freeipa_run_ipa(
            ["host-add", self.NMCI_FQDN, "--ip=" + self.NMCI_IP, "--no-reverse"]
        )
        for f in ["/etc/krb5.keytab", KT_FROM_HOST]:
            if os.path.exists(f):
                os.remove(f)
        get_kt_cmd = [
            "ipa-getkeytab",
            "--principal=host/" + self.NMCI_FQDN,
            "-k",
            KT_INSIDE,
        ]
        get_kt = self.freeipa_exec_run(get_kt_cmd)
        assert get_kt[0] == 0, "\n".join([get_kt_cmd, get_kt])
        shutil.copy(KT_FROM_HOST, "/etc/krb5.keytab")
        nmci.util.file_set_content("/etc/krb5.conf.d/nmci.conf", krb5_conf)
        os.makedirs("/etc/ipa", exist_ok=True)
        nmci.util.file_set_content("/etc/ipa/default.conf", ipa_conf)
        shutil.copy(f"{self._IPA_DATADIR}/etc/ipa/ca.crt", "/etc/ipa/ca.crt")
        # just for 8021x_hostapd_freeradius_doc_procedure but is similar to host stuff
        if self.freeipa_run_ipa_code(["user-find", "idm_user"]) != 0:
            self.freeipa_exec_run(
                [
                    "bash",
                    "-c",
                    "echo 'idm_user_password' | ipa user-add --first 'Test' --last 'User' idm_user --password",
                ]
            )

    def start(self):
        assert nmci.process.systemctl("is-active systemd-resolved")
        assert nmci.process.systemctl("is-active podman.socket")
        nmci.process.run(["hostnamectl", "set-hostname", self.NMCI_FQDN])
        if not self._pc.images.exists(self._BASE_IMAGE):
            self._pc.images.pull(self._BASE_IMAGE)

        self._podman_network_setup()
        self.install_ipa_server()
        self._cont_create()
        self._time_cont_started = time.time()
        self._cont_start()
        self.PODMAN_IFACE = self._pc.networks.get(self.PODMAN_NETWORK).attrs[
            "network_interface"
        ]
        nmci.ip.address_expect(
            [self.NMCI_IP], ifname=self.PODMAN_IFACE, wait_for_address=10
        )
        nmci.process.run(
            [
                "systemd-resolve",
                "--interface",
                self.PODMAN_IFACE,
                "--set-dns",
                self.PODMAN_NETWORK_DNS,
                "--set-domain",
                self.PODMAN_NETWORK,
                "--set-dnssec",
                "no",
            ]
        )
        cert_ca_trust = "/etc/pki/ca-trust/source/anchors/nmci-ipa.crt"
        try:
            os.remove(cert_ca_trust)
        except FileNotFoundError:
            pass
        shutil.copy(f"{self._IPA_DATADIR}/etc/ipa/ca.crt", cert_ca_trust)
        nmci.process.run("update-ca-trust")
        nmci.util.wait_for(self.assert_ipa_services_running, timeout=30)
        host_cmd = ["host", "-tA", self.IPA_NAME]
        assert self.IPA_SERVER_IP in nmci.process.run_stdout(host_cmd)
        assert self.IPA_SERVER_IP in self.freeipa_exec_run(host_cmd)[1]
        self.install_client()
        assert nmci.process.run(["host", self.IPA_NAME])

    def stop(self):
        self._cont_stop()
        nmci.process.run(["hostnamectl", "set-hostname", self.NMCI_NAME_ORIG])

    def clean_image(self):
        if self._pc.images.exists(self._BASE_IMAGE):
            self._pc.images.remove(self._BASE_IMAGE, force=True)

    def clean_container(self):
        if self._pc.containers.exists(self.CONT_NAME):
            self._pc.containers(self.CONT_NAME, force=True)


_module = _FreeIPA()
