import collections
import os
import re
import sys
import time
import subprocess
import shutil
import html

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _Timeout:
    """
    Timeout. This is a helper class that can be used to implement timeouts. It is
    used by :code:`nmci.util.start_timeout()` to implement timeouts.
    """

    def __init__(self, timeout, name=None):
        if name:
            self.full_name = f"Timeout '{name}'"
        else:
            self.full_name = "Timeout"
        now = time.monotonic()
        if isinstance(timeout, _Timeout):
            timeout = timeout.remaining_time(now=now)
        elif isinstance(timeout, str):
            # for convenience, allow timeout as string. We often get the timeout
            # from behave steps, they are strings there...
            timeout = float(timeout)
        self._loop_sleep_called = False
        self._expired_called = False
        self.start_timestamp = now
        if timeout is None:
            self._expiry = None
            self._is_expired = False
        else:
            self._expiry = now + timeout
            self._is_expired = timeout <= 0

    def __enter__(self):
        return self

    def __exit__(self, *args):
        assert (
            not self.expired()
        ), f"{self.full_name} expired in {self.elapsed_time():.3f}s."

    def elapsed_time(self):
        """
        Get elapsed time.

        :return: elapsed time
        :rtype: float
        """
        return time.monotonic() - self.start_timestamp

    def _expired(self, now):
        self._expired_called = True
        if self._is_expired:
            return True
        if self._expiry is None or now < self._expiry:
            return False
        self._is_expired = True
        return True

    def expired(self):
        """
        Whether timeout is expired.

        :return: whether timeout is expired
        :rtype: bool
        """
        return self._expired(now=time.monotonic())

    @property
    def was_expired(self):
        """
        This returns True, iff :code:`self.expired()` ever returned True.
        Unlike :code:`self.expired()`, it does not re-evaluate the expiration
        based on the current timestamp.

        For that reason, it is a @property and not a function. Because,
        the result does not change if called twice in a row (without calling
        :code:`self.expired()` in between).

        :return: whether timeout was expired
        :rtype: bool
        """
        return self._expired_called and self._is_expired

    def remaining_time(self, now=None):
        """
        It makes sense to ask how many seconds remains (to be used as value for another timeout).

        :param now: current time, defaults to None
        :type now: float, optional
        :return: remaining time
        :rtype: float
        """
        if now is None:
            now = time.monotonic()
        if self._expiry is None:
            return None
        if self._expired(now):
            return 0
        return self._expiry - now

    def sleep(self, sleep_time):
        """
        Sleep for "sleep_time" seconds or until the timeout expires (whatever comes first).

        Returns False if self was already expired when calling and no sleeping was done.
        Otherwise, we slept some time and return True.

        :param sleep_time: sleep time
        :type sleep_time: float
        :return: whether timeout expired
        :rtype: bool
        """
        now = time.monotonic()
        if self._expired(now):
            return False
        if self._expiry is not None:
            sleep_time = min(sleep_time, (self._expiry - now))
        time.sleep(sleep_time)
        return True

    def loop_sleep(self, sleep_time=0.1, at_least_once=True):
        """
        Sleep for "sleep_time" seconds or until the timeout expires (whatever comes first).

        The very first call to sleep does not actually sleep. It always returns True and does nothing.

        The idea is that when used with a while loop, that the loop gets run at least once:

        .. code-block:: python
            timeout = nmci.util.start_timeout(0)
            while timeout.sleep(1):
                hi_there()

        :param sleep_time: sleep time, defaults to 0.1
        :type sleep_time: float, optional
        :param at_least_once: whether to run the loop at least once, defaults to True
        :type at_least_once: bool, optional
        :return: whether to run the loop again
        :rtype: bool
        """
        # The very first call to sleep does not actually sleep. It
        # Always returns True and does nothing.
        #
        # The idea is that when used with a while loop, that the
        # loop gets run at least once:
        #
        #     timeout = nmci.util.start_timeout(0)
        #     while timeout.sleep(1):
        #         hi_there()
        if not self._loop_sleep_called:
            self._loop_sleep_called = True
            if not at_least_once and self._expired(time.monotonic()):
                # the timer is already expired on the first iteration
                # and the caller wishes us to skip iteration altogether.
                return False
            return True
        return self.sleep(sleep_time)

    def is_none(self):
        """
        Whether timeout is None (infinity). It can be useful to ask :code:`self` whether
        timeout is disabled.

        :return: whether timeout is None (infinity)
        :rtype: bool
        """
        return self._expiry is None


class _Util:
    """
    Utility functions. This is a singleton class. Use :code:`nmci.util` to access
    the singleton instance.
    """

    # like time.CLOCK_BOOTTIME, which only exists since Python 3.7
    CLOCK_BOOTTIME = 7

    def __init__(self):
        self.dump_status_verbose = False
        self._is_verbose = False

    class ExpectedException(Exception):
        """Expected exception. We don't want to just catch blindly all "Exception" types
        but rather only those exceptions where an API is known that it might fail and fails
        with a particular exception type.

        Usually, we would thus add various Exception classes that carry specific information
        about the failure reason. However, that is sometimes just cumbersome.

        This exception type fills this purpose. It's not very specific but it's specific
        enough that we can catch it for functions that are known to have certain failures
        -- while not needing to swallow all exceptions.

        """

        pass

    @property
    def GLib(self):
        """
        Get GLib module.

        :return: GLib module
        :rtype: module
        """
        m = getattr(self, "_GLib", None)
        if m is None:
            from gi.repository import GLib

            m = GLib
            self._GLib = m
        return m

    @property
    def Gio(self):
        """
        Get Gio module.

        :return: Gio module
        :rtype: module
        """
        m = getattr(self, "_Gio", None)
        if m is None:
            from gi.repository import Gio

            m = Gio
            self._Gio = m
        return m

    @property
    def NM(self):
        """
        Get NM module.

        :return: NM module
        :rtype: module
        """
        m = getattr(self, "_NM", None)
        if m is None:
            import gi

            gi.require_version("NM", "1.0")
            from gi.repository import NM

            m = NM
            self._NM = m
        return m

    @property
    def JsonGLib(self):
        """
        Get JsonGLib module.

        :return: JsonGLib module
        :rtype: module
        """
        m = getattr(self, "_JsonGLib", None)
        if m is None:
            import gi

            gi.require_version("Json", "1.0")
            from gi.repository import Json

            m = Json
            self._JsonGLib = m
        return m

    def util_dir(self, *args):
        """
        Get util directory.

        :param args: additional path components
        :type args: list
        :return: util directory
        :rtype: str
        """
        if not hasattr(self, "_util_dir"):
            self._util_dir = os.path.dirname(
                os.path.realpath(os.path.abspath(__file__))
            )
        return os.path.join(self._util_dir, *args)

    @property
    def BASE_DIR(self):
        """
        Base directory of NM-ci.

        :return: base directory of NM-ci
        :rtype: str
        """
        if not hasattr(self, "_base_dir"):
            self._base_dir = os.path.realpath(self.util_dir(".."))
        return self._base_dir

    def base_dir(self, *args):
        """
        Base directory of NM-ci.

        :param args: additional path components
        :type args: list
        :return: base directory of NM-ci with additional path
        :rtype: str
        """
        return os.path.join(self.BASE_DIR, *args)

    def tmp_dir(self, *args, create_base_dir=True):
        """
        Temporary directory of NM-ci.

        :param args: additional path components
        :type args: list
        :param create_base_dir: whether NM-ci base directory should be created
        :type create_base_dir: bool
        :return: temporary directory of NM-ci with additional path
        :rtype: str
        """
        d = self.base_dir(".tmp")
        if create_base_dir and not os.path.isdir(d):
            os.mkdir(d)
        return os.path.join(d, *args)

    @property
    def DEBUG(self):
        """
        Whether NM-ci runs in debug mode.

        :return: whether NM-ci runs in debug mode
        :rtype: bool
        """
        # Whether "NMCI_DEBUG" environment is set. If yes, NM-ci runs
        # in debug mode.
        v = getattr(self, "_DEBUG", None)
        if v is None:
            v = os.environ.get("NMCI_DEBUG", "").lower() not in [
                "",
                "n",
                "no",
                "f",
                "false",
                "0",
            ]
            self._DEBUG = v
        return v

    def set_verbose(self, value=True):
        """
        Set verbose mode.

        :param value: whether to set verbose mode, defaults to True
        :type value: bool, optional
        """
        self._is_verbose = value

    def is_verbose(self):
        """
        Whether NM-ci runs in verbose mode.

        :return: whether NM-ci runs in verbose mode
        :rtype: bool
        """
        return self._is_verbose or self.DEBUG

    def gvariant_to_dict(self, variant):
        """
        Convert GVariant to dict.

        :param variant: GVariant
        :type variant: GLib.Variant
        :return: dict
        :rtype: dict
        """
        import json

        JsonGLib = self.JsonGLib
        j = JsonGLib.gvariant_serialize(variant)
        return json.loads(JsonGLib.to_string(j, 0))

    def consume_list(self, lst):
        """
        Consume list. This is a generator that consumes a list (removing all elements,
        from the beginning) and returns an iterator for the elements.

        :param lst: list
        :type lst: list
        :return: iterator for the elements
        :rtype: iterator
        """
        while True:
            # Popping at the beginning is probably O(n) so this
            # is not really efficient. Doesn't matter for our uses.
            try:
                v = lst.pop(0)
            except IndexError:
                break
            yield v

    def binary_to_str(self, b, binary=None):
        """
        Convert bytes to string. This is the same as bytes_to_str() but it
        also supports returning binary (if the caller accepts it).

        :param b: bytes
        :type b: bytes
        :param binary: whether to return binary, defaults to None
            - None (return string)
            - False (return string)
            - True (return binary)
        :type binary: bool, optional
        :return: string
        :rtype: str
        """
        assert binary is None or binary is False or binary is True
        if isinstance(b, bytes):
            if binary is True:
                # The caller requested binary. Just return it.
                return b
            try:
                return b.decode("utf-8", errors="strict")
            except UnicodeError:
                if binary is False:
                    # The caller requested a string. We fail.
                    raise

                # The caller accepts both. Return binary.
                return b
        raise ValueError("Expects bytes")

    def bytes_to_str(self, s, errors="strict"):
        """
        Convert bytes to string.

        :param s: bytes
        :type s: bytes
        :param errors: errors, defaults to "strict"
        :type errors: str, optional
        :return: string
        :rtype: str
        """
        if isinstance(s, bytes):
            return s.decode("utf-8", errors=errors)
        if isinstance(s, str):
            return s
        raise ValueError("Expects either a str or bytes")

    def str_to_bytes(self, s):
        """
        Convert string to bytes.

        :param s: string
        :type s: str
        :return: bytes
        :rtype: bytes
        """
        if isinstance(s, str):
            return s.encode("utf-8")
        if isinstance(s, bytes):
            return s
        raise ValueError("Expects either a str or bytes")

    def str_matches(self, string, pattern):
        """
        Matches "string" with "pattern".

        :param string: string
        :type string: str
        :param pattern: pattern
            - a plain string (compared with ==)
            - a re.Pattern instance (compared with re.Pattern.search())
            or re._pattern_type on python-=3.6
            - an interable/list of above.
        :type pattern: str or re.Pattern or list
        :return: whether string matches pattern
        :rtype: bool
        """
        # Matches "string" with "pattern".
        # Pattern can be:
        # - a plain string (compared with ==)
        # - a re.Pattern instance (compared with re.Pattern.search())
        #   - or re._pattern_type on python-=3.6
        # - an interable/list of above.
        if isinstance(pattern, str):
            return string == pattern
        if isinstance(pattern, self.re_Pattern):
            return bool(pattern.search(string))
        for p in pattern:
            if isinstance(p, str):
                if string == p:
                    return True
            elif isinstance(p, self.re_Pattern):
                if p.search(string):
                    return True
            else:
                raise TypeError()
        return False

    FileGetContentResult = collections.namedtuple(
        "FileGetContentResult", ["data", "full_file"]
    )

    def start_timeout(self, timeout=None, name=None):
        """
        Start timeout. This is useful for timeouts that are used in a :code:`with`
        statement. It returns a timeout object that can be used to check whether
        the timeout has expired. It also raises an exception if the timeout has expired
        when the with statement ends.

        :param timeout: timeout, defaults to None
            - _Timeout object (use remaining time)
            - None (infinity)
            - str or number (timeout in seconds)
        :type timeout: _Timeout or str or number, optional
        :param name: name of timeout, defaults to None
        :type name: str, optional
        :return: timeout object
        :rtype: _Timeout
        """
        # timeout might be:
        #   - _Timeout object (use remaining time)
        #   - None (infinity)
        #   - str or number (timeout in seconds)
        return _Timeout(timeout, name=name)

    def fd_get_content(
        self,
        file,
        max_size=None,
        warn_max_size=True,
    ):
        """
        Get content of file. This is a low-level function that reads the file and
        returns the content as bytes. It also returns a flag that indicates whether
        the file was read completely or whether the maximum size was reached.

        :param file: file
        :type file: file
        :param max_size: maximum size of file, defaults to None
        :type max_size: int, optional
        :param warn_max_size: warn if maximum size is reached, defaults to True
        :type warn_max_size: bool, optional
        :return: content of file
        :rtype: FileGetContentResult
        """
        if max_size is None:
            max_size = 50 * 1024 * 1024

        data = file.read(max_size)
        full_file = not file.read(1)

        if not full_file and warn_max_size:
            try:
                size = str(os.fstat(file.fileno()).st_size)
            except Exception:
                size = "???"
            m = f"\n\nWARNING: size limit reached after reading {max_size} of {size} bytes. Output is truncated"
            if isinstance(data, bytes):
                data += self.str_to_bytes(m)
            else:
                data += m

        return self.FileGetContentResult(data, full_file)

    def file_get_content(
        self,
        file_name,
        encoding="utf-8",
        errors="strict",
        max_size=None,
        warn_max_size=True,
    ):
        """Get content of file.

        :param file_name: file name
        :type file_name: str
        :param encoding: encoding, defaults to "utf-8"
        :type encoding: str, optional
        :param errors: errors, defaults to "strict"
        :type errors: str, optional
        :param max_size: maximum size of file, defaults to None
        :type max_size: int, optional
        :param warn_max_size: warn if maximum size is reached, defaults to True
        :type warn_max_size: bool, optional
        :return: content of file
        :rtype: FileGetContentResult
        """
        # Set "encoding" to None to get bytes.
        if encoding is None:
            file = open(file_name, mode="rb")
        else:
            file = open(file_name, mode="r", encoding=encoding, errors=errors)
        with file:
            return self.fd_get_content(
                file, max_size=max_size, warn_max_size=warn_max_size
            )

    def file_get_content_simple(self, file_name, as_bytes=False):
        """
        Get content of file. This is a simplified version of file_get_content() that
        returns the content as string or bytes (depending on :code:`as_bytes`) and does not
        return the :code:`full_file` flag. It also does not support :code:`max_size` and
        :code:`warn_max_size`.

        :param file_name: file name
        :type file_name: str
        :param as_bytes: return bytes instead of str, defaults to False
        :type as_bytes: bool, optional
        :return: content of file
        :rtype: str or bytes
        """
        if as_bytes:
            encoding = None
        else:
            encoding = "utf-8"
        return self.file_get_content(
            file_name, encoding=encoding, errors="replace"
        ).data

    def file_set_content(self, file_name, data=""):
        """Set content of file.

        :param file_name: file name
        :type file_name: str
        :param data: data to write, accepts string, bytes or list of lines, defaults to ""
        :type data: str or bytes or list[str] or list[bytes], optional
        """
        if isinstance(data, str):
            data = data.encode("utf-8")
        elif isinstance(data, bytes):
            pass
        else:
            # append [""] to add "\n" after last line, note the number of added "\n" is len(data)
            data = b"\n".join((self.str_to_bytes(line) for line in list(data) + [""]))

        try:
            data_str = self.bytes_to_str(data)
            nmci.embed.embed_data(
                f"write {file_name}",
                data_str,
                fail_only=True,
            )
        except UnicodeDecodeError:
            pass

        with open(file_name, "wb") as f:
            f.write(data)

    def file_remove(self, file_name, do_assert=False):
        """
        Remove file, ignore if it does not exist.

        :param file_name: file name
        :type file_name: str
        :param do_assert: raise exception if file does not exist, defaults to False
        :type do_assert: bool, optional
        """
        try:
            os.remove(file_name)
        except FileNotFoundError:
            if do_assert:
                raise

    def directory_remove(self, dir_name, recursive=False, do_assert=False):
        """
        Remove directory, ignore if it does not exist.

        :param dir_name: directory name
        :type dir_name: str
        :param recursive: remove recursively, defaults to False
        :type recursive: bool, optional
        :param do_assert: raise exception if directory does not exist, defaults to False
        :type do_assert: bool, optional
        """
        try:
            # Both function might raise FileNotFoundError (ignore if not do_assert).
            # Other Errors (permissions) are not ignnored, they are severe.
            if recursive:
                shutil.rmtree(dir_name)
            else:
                os.rmdir(dir_name)
        except FileNotFoundError:
            if do_assert:
                raise

    def update_udevadm(self):
        """
        Update udevadm rules and wait for udev to settle. This is useful when
        udev rules are changed and the changes should be applied immediately.

        :raises nmci.util.ExpectedException: if udevadm failed
        """
        # Just wait a bit to have all files correctly written

        time.sleep(0.2)
        nmci.process.run_stdout(
            "udevadm control --reload-rules",
            timeout=45,
            ignore_stderr=True,
        )
        nmci.process.run_stdout(
            "udevadm settle --timeout=15",
            timeout=20,
            ignore_stderr=True,
        )
        time.sleep(0.8)

    def dump_status(self, when, prefix="Status"):
        """
        Dump status of the system to the log. This is useful for debugging
        purposes. It dumps the status of NetworkManager, systemd-resolved,
        the vethsetup network namespace and the other named network namespaces. It
        also dumps the routing tables and the firewall rules. It's a lot of
        information, so it's only dumped when the test fails. It can be
        enabled for all tests by setting the :code:`NMCI_DUMP_STATUS` environment
        variable to "1".

        :param when: when to dump the status
        :type when: str
        """

        class Echo:
            def __init__(self, args, html_tag=None, escape=True):
                self.args = args
                self.html_tag = html_tag
                self.escape = escape

            # Do not overwrite `self`, we need it for `bytes_to_str()`
            def __str__(me):  # py__iterlint: disable=no-self-argument,invalid-name
                if isinstance(me.args, nmci.process.With):
                    args_s = str(me.args)
                elif isinstance(me.args, (str, bytes)):
                    args_s = self.bytes_to_str(me.args)
                elif hasattr(me.args, "__iter__"):
                    args_s = " ".join(me.args)
                else:
                    raise Exception(
                        f"Unexpected argument type in Echo: {type(me.args)}"
                    )
                if me.escape:
                    args_s = html.escape(args_s)
                if me.html_tag:
                    return f"<{me.html_tag}>{args_s}</{me.html_tag}>"
                else:
                    return f"{args_s}"

        verbose_ip_args = []
        if self.dump_status_verbose:
            verbose_ip_args = ["-d"]

        timeout = nmci.util.start_timeout(20)

        nm_running = nmci.nmutil.nm_pid() != 0

        nm_cmds = [Echo("!!! NM is not running !!!", "h1")]
        if nm_running:
            nm_cmds = [
                "NetworkManager --print-config",
                "nmcli -f ALL g",
                "nmcli -f ALL d",
                "nmcli -f ALL c",
                "nmcli -f ALL d w l",
                "cat /etc/resolv.conf",
            ]
            if (
                nmci.process.systemctl(
                    "is-active systemd-resolved", embed_combine_tag=nmci.embed.NO_EMBED
                ).returncode
                == 0
            ):
                nm_cmds.append("resolvectl --no-pager")
        veth_cmds = []
        if nm_running and os.path.isfile("/tmp/nm_veth_configured"):
            verbose_cmds = []
            if self.dump_status_verbose:
                verbose_cmds.extend(
                    [
                        ["ip", "-n", "vethsetup", "mptcp", "limits"],
                        ["ip", "-n", "vethsetup", "mptcp", "endpoint"],
                        [
                            "ip",
                            "netns",
                            "exec",
                            "vethsetup",
                            "sysctl",
                            "-a",
                            "--pattern",
                            r"net\.mptcp\.enabled|\.rp_filter",
                        ],
                    ]
                )
            veth_cmds = [
                Echo("Veth setup network namespace and DHCP server state:", "h3"),
                ["ip", "-n", "vethsetup", *verbose_ip_args, "addr"],
                ["ip", "-n", "vethsetup", *verbose_ip_args, "-4", "route"],
                ["ip", "-n", "vethsetup", *verbose_ip_args, "-6", "route"],
                *verbose_cmds,
                "ip netns exec vethsetup nft list ruleset",
            ]

        named_nss = nmci.ip.netns_list(verbose=False)

        # vethsetup is handled separately
        named_nss = [n for n in named_nss if n != "vethsetup"]
        named_nss_cmds = []

        if len(named_nss) > 0:
            named_nss_cmds = [Echo("Status of other named network namespaces:", "h3")]
            for ns in sorted(named_nss):
                verbose_cmds = []
                if self.dump_status_verbose:
                    verbose_cmds.extend(
                        [
                            ["ip", "-n", ns, "mptcp", "limits"],
                            ["ip", "-n", ns, "mptcp", "endpoint"],
                            [
                                "ip",
                                "netns",
                                "exec",
                                ns,
                                "sysctl",
                                "-a",
                                "--pattern",
                                r"net\.mptcp\.enabled|\.rp_filter",
                            ],
                        ]
                    )
                named_nss_cmds += [
                    Echo(f"network namespace {ns}:", "h3"),
                    ["ip", "-n", ns, *verbose_ip_args, "a"],
                    ["ip", "-n", ns, *verbose_ip_args, "-4", "r"],
                    ["ip", "-n", ns, *verbose_ip_args, "-6", "r"],
                    *verbose_cmds,
                    f"ip netns exec {ns} nft list ruleset",
                ]

        verbose_cmds = []
        if self.dump_status_verbose:
            verbose_cmds.extend(
                [
                    ["ip", "mptcp", "limits"],
                    ["ip", "mptcp", "endpoint"],
                    ["sysctl", "-a", "--pattern", r"net\.mptcp\.enabled|\.rp_filter"],
                ]
            )
        cmds = [
            "date '+%Y%m%d-%H%M%S.%N (%s)'",
            nmci.process.WithShell("get_rhel_compose"),
            nmci.process.WithShell("hostnamectl 2>&1"),
            "free -mt",
            "df -m",
            "NetworkManager --version",
            ["ls", "-lZ", "/etc/NetworkManager/system-connections/"],
            ["ls", "-lZ", "/etc/sysconfig/network-scripts/"],
            ["ls", "-lZ", "/tmp/testeth0"],
            *nm_cmds,
            ["ip", *verbose_ip_args, "addr"],
            ["ip", *verbose_ip_args, "-4", "route"],
            ["ip", *verbose_ip_args, "-6", "route"],
            *verbose_cmds,
            *veth_cmds,
            *named_nss_cmds,
            "ps aux",
            "nft list ruleset",
        ]

        procs = []
        for cmd in cmds:
            if isinstance(cmd, Echo):
                procs.append(cmd)
            else:
                procs.append(nmci.process.Popen(cmd, stderr=subprocess.DEVNULL))

        while timeout.loop_sleep(0.05):
            any_pending = False
            for proc in procs:
                if isinstance(proc, Echo):
                    continue
                if proc.read_and_poll() is None:
                    if timeout.was_expired:
                        proc.terminate_and_wait(timeout_before_kill=3)
                    else:
                        any_pending = True
            if not any_pending or timeout.was_expired:
                break

        memory = self.dump_memory_stats()
        procs.append(Echo(memory, escape=False))

        duration = nmci.misc.format_duration(timeout.elapsed_time())
        procs.append(Echo(f"<b>Status duration:</b> {duration}", escape=False))

        procs.append(
            Echo(
                f"<b>NMCI_RANDOM_SEED={nmci.util.nmci_random_seed()}</b>", escape=False
            )
        )

        procs.append(
            Echo(
                f"<b>Detected version:</b> {nmci.misc.nm_version_detect()} on {nmci.misc.distro_detect()}",
                escape=False,
            )
        )

        msg = []
        for proc in procs:
            if isinstance(proc, Echo):
                msg.append(f"\n{proc}")
                continue
            msg.append(f"\n{Echo(proc.argv, 'h4')}")
            output = proc.stdout.decode("utf-8", errors="replace")
            msg.append(f"{Echo(output)}")
        if timeout.was_expired:
            msg.append(
                "\nWARNING: timeout expired waiting for processes. Processes were terminated."
            )

        nmci.embed.embed_data(
            f"{prefix} " + when, "\n".join(msg), mime_type="text/html"
        )

    def dump_memory_stats(self):
        """
        Dump memory stats. This is useful for debugging purposes. It dumps
        the memory consumption of NetworkManager and the memory consumption of
        the NetworkManager process itself (if it's running under valgrind).

        :return: a string with memory stats
        :rtype: str
        """
        if nmci.cext.context.nm_pid is not None:
            try:
                kb = nmci.nmutil.nm_size_kb()
            except nmci.util.ExpectedException as e:
                msg = f"<b>Daemon memory consumption:</b> unknown ({e})\n"
            else:
                msg = f"<b>Daemon memory consumption:</b> {kb} KiB\n"
            service_file = "/etc/systemd/system/NetworkManager.service"
            if os.path.isfile(service_file):
                if "valgrind" in self.file_get_content(service_file):
                    result = nmci.process.run(
                        "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                        " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                        shell=True,
                        embed_combine_tag=nmci.embed.NO_EMBED,
                    )
                    msg += result.stdout
            return msg
        else:
            return (
                "<b>Daemon memory consumption:</b> unknown (NetworkManager not running)"
            )

    def gvariant_type(self, s):
        """
        Convert a string to a GVariantType.

        :param s: the string to convert
        :type s: str or GLib.VariantType
        :return: the GVariantType
        :rtype: GLib.VariantType
        """
        if s is None:
            return None

        if isinstance(s, str):
            return self.GLib.VariantType(s)

        if isinstance(s, self.GLib.VariantType):
            return s

        raise ValueError("cannot get the GVariantType for %r" % (s))

    @property
    def re_Pattern(self):
        """
        Get re.Pattern.

        :return: re.Pattern
        :rtype: re.Pattern
        """
        if hasattr(re, "Pattern"):
            return re.Pattern
        return re._pattern_type  # pylint: disable=no-member,protected-access

    def str_whitespace_join(self, args):
        """
        Join a list of strings at whitespace, but support backslash escaping
        to prevent splitting.

        This basically allows to express a string list in one string,
        separated by space. It only supports a minimum of extra escaping,
        to allow a space not be treated as separator. Most backslash
        is treated verbatim.

        This allows to write expressions, that themselves might be backslash
        escaped, without requiring additional backslash escaping.
        For example, regexes: :code:`["^.$", "^ \\\\["]` gives the string :code:`"^.$ ^\\\\ \\\\["`

        :param args: the list of strings to join
            The empty list joins to None and not to "".
            That's because [""] already joins to "", but we want a unique
            result for every join (so that it can be reverted). That's why we
            don't return a string for the empty list.
        :type args: list
        :return: the joined string
        :rtype: str
        """
        args = list(args)
        if not args:
            return None
        return " ".join(a.replace("\\", "\\\\").replace(" ", "\\ ") for a in args)

    def str_whitespace_split(self, text, remove_empty=True):
        """
        Split a string at whitespace, but support backslash escaping
        to prevent splitting.

        This basically allows to express a string list in one string,
        separated by space. It only supports a minimum of extra escaping,
        to allow a space not be treated as separator. Most backslash
        is treated verbatim.

        This allows to write expressions, that themselves might be backslash
        escaped, without requiring additional backslash escaping.
        For example, regexes: :code:`"^.$ ^\\\\ \\\\["` gives the two regexes :code:`["^.$", "^ \\\\["]`

        This will:
        - None gives the empty list [] (so that every input strlist can be joined and split again).
        - take double backslash :code:`"\\\\\\\\"` as a single backslash :code:`"\\\\"`
        - take escaped space :code:`"\\\\ "` as a single space
        - take a single whitespace to split the string (the whitespace is removed).
        - any other escaped backslash is taken literally.

        :param text: the string to split
        :type text: str
        :param remove_empty: if True, empty tokens are dropped from the result.
            With :code:`remove_empty=False`, :code:`split(join(strlist))` gives :code:`strlist`.
        :type remove_empty: bool
        :return: the list of strings
        :rtype: list
        """
        if text is None:
            # None is valid and splits to the empty list. That's a special case
            # so that every strlist can be uniquely joined and split.
            return []

        assert isinstance(text, str)

        result = []
        i = 0
        l = len(text)
        word = ""
        while i < l:
            c = text[i]
            i += 1
            if c == " ":
                result.append(word)
                word = ""
                continue
            if c == "\\" and i < l:
                c2 = text[i]
                i += 1
                if c2 == "\\":
                    word += "\\"
                elif c2 == " ":
                    word += " "
                else:
                    word += f"\\{c2}"
            else:
                word += c

        result.append(word)

        if remove_empty:
            result = [s for s in result if s]

        return result

    def compare_strv_list(
        self,
        expected,
        strv,
        match_mode="auto",
        ignore_extra_strv=True,
        ignore_order=True,
    ):
        """
        Compare the :code:`strv` list of strings with :code:`expected`. If the list differs,
        a ValueError gets raised. Otherwise it return True.

        :param expected: the list of expected items. It can be a plain string,
            or a regex string (see :code:`match_mode`).
        :type expected: list or str
        :param strv: the string list that we check.
        :type strv: list
        :param match_mode: how the elements in :code:`expected` are compared against :code:`strv`
            - "plain": direct string comparison. The default is "plain" if no prefix is given
            - "regex": regular expression using re.search(e, s)
            - "auto": each element can encode whether to be an optional match (starting
            with '?'), and whether to use regex/plain mode ('/' vs. '=').
        :type match_mode: str
        :param ignore_extra_strv: if True, extra non-matched elementes in strv are silently accepted
        :type ignore_extra_strv: bool
        :param ignore_order: if True, the order is not checked. Otherwise, the
            elements in :code:`expected` must match in the right order.
            For example, with :code:`match_mode='regex'`, :code:`expected=['a', '.']`,
            :code:`strv=['b', 'a']`, this matches when ignoring the order,
            but fails to match otherwise.
            An element in :code:`expected` only can match exactly once.
        :type ignore_order: bool
        """
        if isinstance(expected, str):
            # For convenience, allow "expected" to be a space separated string.
            expected = self.str_whitespace_split(expected)
        else:
            expected = list(expected)
        strv = list(strv)

        expected_match_idxes = []
        strv_matched = [False for s in strv]
        expected_required = [True for s in expected]
        for i, e in enumerate(expected):
            e0 = e
            idxes = []

            # With "match_mode=auto", we detect the match mode based on the string.
            #
            # If the string starts with '?', it means that the element is
            # optional. That means it may match not at all or once.
            # The leading "?" gets stripped first.
            if match_mode == "auto" and e[0] == "?":
                e = e[1:]
                expected_required[i] = False

            # With "match_mode=auto", if the string starts with a '/' it
            # is a regex (the '/' gets stripped).
            # With "match_mode=auto", if the string starts with a '=' it
            # is a plain string (the '=' gets stripped). "plain" is also
            # the default otherwise (the '=' is only to escape strings).
            if match_mode == "auto" and e[0] == "/":
                f_match = lambda s: bool(re.search(e[1:], s))
            elif match_mode == "auto" and e[0] == "=":
                f_match = lambda s: (s == e[1:])
            elif match_mode in ["auto", "plain"]:
                f_match = lambda s: (s == e)
            else:
                assert match_mode == "regex"
                f_match = lambda s: bool(re.search(e, s))

            for j, s in enumerate(strv):
                if f_match(s):
                    strv_matched[j] = True
                    idxes.append(j)

            if not idxes:
                if expected_required[i]:
                    raise ValueError(
                        f'Could not find #{i} "{e0}" in list {str(strv)} (expected {str(expected)})'
                    )
            expected_match_idxes.append(idxes)

        if not ignore_extra_strv:
            for j, s in enumerate(strv):
                if not strv_matched[j]:
                    raise ValueError(
                        f'List {str(strv)} contains non expected element #{j} "{s}" (expected {str(expected)})'
                    )

        # We now have a mapping of `expected_match_idxes[i]` where each element at position `i` contains
        # a list of indexes for `strv` which matched. Note that this list of indexes might be
        # empty (with `not expected_required[i]`) or contain multiple indexes (with regular
        # expression that can match multiple strings.
        #
        # Depending on `ignore_order`, we need to find a combination of matches that
        # satisfies the requirement. E.g. every `expected[i]` must match zero or
        # one time (depending on `expected_required[i]`). With `not ignore_order`,
        # the matches must all have indexes in ascending order.
        def _has_unique_permuation(lst, base_idx, seen_idx):
            if base_idx >= len(lst):
                return True

            if not expected_required[base_idx]:
                # Try without a match first.
                good = _has_unique_permuation(lst, base_idx + 1, seen_idx)
                if good:
                    return True

            for i in lst[base_idx]:
                if i in seen_idx:
                    # already visited
                    continue
                if not ignore_order and seen_idx and i < max(seen_idx):
                    # the increasing order (of indexes) would be violated.
                    continue
                seen_idx.add(i)
                good = _has_unique_permuation(lst, base_idx + 1, seen_idx)
                seen_idx.remove(i)
                if good:
                    return True
            return False

        rl = sys.getrecursionlimit()
        sys.setrecursionlimit(rl + len(expected))
        try:
            has = _has_unique_permuation(
                [idxes for idxes in expected_match_idxes if idxes], 0, set()
            )
        finally:
            sys.setrecursionlimit(rl)

        if not has:
            raise ValueError(
                f"List {str(strv)} unexpectedly could not match expected list in a unique way {'ignoring' if ignore_order else 'requiring'} the order (expected {str(expected)})"
            )

        return True

    def wait_for(
        self,
        callback,
        timeout=5,
        poll_sleep_time=0.2,
        handle_result=None,
        handle_exception=None,
        handle_timeout=None,
        op_name=None,
    ):
        """
        Waits for up to "timeout" seconds, with a poll-interval of "poll_sleep_time".

        The main mode of operation is simply that the "callback" raises an exception
        if the thing that we wait for is not yet reached. In that mode,
        - the function retries until timeout or until "callback" does not raise
        - on success, the return value of "callback" is returned.
        - on timeout, the last_exception is re-raised.

        You can also pass "handle_result", "handle_exception" and "handle_timeout"
        callbacks, to modify the behavior.

        :param callback: the callback to call.
        :type callback: callable
        :param timeout: the timeout in seconds.
        :type timeout: float
        :param poll_sleep_time: the poll sleep time in seconds.
        :type poll_sleep_time: float
        :param handle_result: a callback that is called with the result of the callback.
        :type handle_result: callable
        :param handle_exception: a callback that is called with the exception raised by the callback.
        :type handle_exception: callable
        :param handle_timeout: a callback that is called with the last exception raised by the callback.
        :type handle_timeout: callable
        :param op_name: the name of the operation.
        :type op_name: str
        :return: the result of the callback.
        :rtype: any
        """
        timeout = nmci.util.start_timeout(timeout)

        if handle_result is None:
            # The default implementation returns done=True and result=res.
            handle_result = lambda res: (True, res)

        if handle_exception is None:
            # The default implementation accepts and exception and swallows
            # is (by returning True, that the exception was handled).
            # The effect is, that we retry as long as there is an exception.
            handle_exception = lambda e: True

        if handle_timeout is None:
            # The default implementation either re-raises the
            # last exception or (if none) raises a TimeoutError.
            def h(last_exception):
                if last_exception is not None:
                    raise last_exception
                raise TimeoutError(f"timeout waiting for operation '{op_name}'")

            handle_timeout = h

        while timeout.loop_sleep(sleep_time=poll_sleep_time):
            last_exception = None

            try:
                res = callback()
            except Exception as e:
                # handle_exception() can:
                # - return True to swallow the exception and continue
                # - return False, to re-raise the exception (and abort)
                # - raise an exception.
                last_exception = e
                if not handle_exception(e):
                    raise
                continue

            # handle_result() must return a tuple with (done, result)
            # where "done" is a boolean that determines whether we are done,
            # and "result" is the result that we will return.
            done, result = handle_result(res)
            if done:
                return result

        # handle_timeout can:
        # - re-raise the "last_exception" (if any)
        # - raise its own exception, like a TimeoutError
        # - return a value that is returned by the function.
        return handle_timeout(last_exception)

    def nmci_random_seed(self):
        """
        Return the global random seed. The seed is read from the environment.

        :return: the global random seed.
        :rtype: int
        """
        seed = getattr(self, "_random_seed", None)
        if seed is None:
            s = os.environ.get("NMCI_RANDOM_SEED", None)
            if s:
                seed = int(s)
            else:
                file = nmci.util.tmp_dir("nmci-random-seed")
                try:
                    s = nmci.util.file_get_content_simple(file)
                except FileNotFoundError:
                    pass
                else:
                    seed = int(s)

                if seed is None:
                    import random

                    seed = random.randint(1, 2**32)
                    nmci.util.file_set_content(file, str(seed))

            self._random_seed = seed
        return seed

    def random_generator(self, seed):
        """
        Return a random.Random instance. The instance is seeded with the
        global seed and the given seed. The global seed is read from the
        environment variable NMCI_RANDOM_SEED. If the variable is not set, a
        random seed is generated and stored in a file in the .tmp directory.

        :param seed: the seed to use for the random.Random instance.
        :type seed: str
        :return: a random.Random instance.
        :rtype: random.Random
        """
        import random

        context = nmci.cext.context
        if context is None or "DummyContext" in context.__class__.__name__:
            context = ""
        else:
            context = f"/[{context.scenario}/{context.current_step.name}/{context.current_step.location}]"

        global_seed = self.nmci_random_seed()
        rseed = f"{global_seed}{context}/{seed}"
        return random.Random(rseed)

    def random_float(self, seed, minval=0.0, maxval=1.0):
        """
        Return a random float in the range [minval, maxval).

        :param seed: the seed to use for the random.Random instance.
        :type seed: str
        :param minval: the minimum value of the random float.
        :type minval: float
        :param maxval: the maximum value of the random float.
        :type maxval: float
        :return: a random float in the range [minval, maxval).
        :rtype: float
        """
        r = self.random_generator(seed)
        if minval == 0.0 and maxval == 1.0:
            return r.random()
        return r.uniform(minval, maxval)

    def random_int(self, seed, minval=0, maxval=(2**32 - 1)):
        """
        Return a random integer in the range [minval, maxval].

        :param seed: the seed to use for the random.Random instance.
        :type seed: str
        :param minval: the minimum value of the random integer.
        :type minval: int
        :param maxval: the maximum value of the random integer.
        :type maxval: int
        :return: a random integer in the range [minval, maxval].
        :rtype: int
        """
        return self.random_generator(seed).randint(minval, maxval)

    def random_bool(self, seed):
        """
        Return a random boolean value.

        :param seed: the seed to use for the random.Random instance.
        :type seed: str
        :return: a random boolean value.
        :rtype: bool
        """
        return bool(self.random_int(seed, 0, 1))

    def random_iter_int(self, seed, minval=0, maxval=(2**32 - 1)):
        """
        Return an iterator that yields random integers in the range [minval, maxval].

        :param seed: the seed to use for the random.Random instance.
        :type seed: str
        :param minval: the minimum value of the random integer.
        :type minval: int
        :param maxval: the maximum value of the random integer.
        :type maxval: int
        :return: an iterator that yields random integers in the range [minval, maxval].
        :rtype: Iterator[int]
        """
        r = self.random_generator(seed)
        while True:
            yield r.randint(minval, maxval)


_module = _Util()
