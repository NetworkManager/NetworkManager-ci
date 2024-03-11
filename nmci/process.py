import collections
import json
import os
import re
import subprocess
import shlex

RunResult = collections.namedtuple("RunResult", ["returncode", "stdout", "stderr"])

IGNORE_RETURNCODE_ALL = object()
# Introduced for nmci docs, different systems produced different default
# either `re.DOTALL|re.MULTILINE` or `re.None`
DEFAULT_PATTERN_FLAGS = object()

import nmci
from nmci.embed import TRACE_COMBINE_TAG


def __getattr__(attr):
    return getattr(_module, attr)


class With:
    """
    Helper class to allow WithPrefix and WithNamespace to be used
    interchangeably with strings.
    """

    def __init__(self, cmd):
        self.cmd = cmd

    def get_argv(self):
        if isinstance(self.cmd, With):
            return self.cmd.get_argv()
        return self.cmd

    def get_shell(self):
        if isinstance(self.cmd, With):
            return self.cmd.get_shell()
        return False

    def is_cached(self):
        if isinstance(self.cmd, With):
            return self.cmd.is_cached()
        return False

    def _prepend_argv(self, prefix):
        argv = self.cmd
        if isinstance(argv, With):
            argv = argv.get_argv()
        if isinstance(argv, str):
            prefix_str = " ".join(shlex.quote(x) for x in prefix)
            argv = f"{prefix_str} {argv}"
        else:
            argv = [*prefix, *argv]
        return argv

    def __str__(self):
        argv = self.get_argv()
        if isinstance(argv, str):
            return argv
        return " ".join(shlex.quote(x) for x in argv)


class WithShell(With):
    """
    Helper class to allow WithShell to be used interchangeably with strings.
    """

    def __init__(self, cmd):
        self.cmd = cmd

    def get_shell(self):
        return True


class WithPrefix(With):
    """
    Helper class to allow WithPrefix to be used interchangeably with strings.
    """

    def __init__(self, prefix, cmd):
        self.cmd = cmd
        self.prefix = prefix

    def get_argv(self):
        return self._prepend_argv(self.prefix)


class WithCache(With):
    """
    Helper class to allow WithCache to be used interchangeably with strings.
    """

    def __init__(self, cmd):
        self.cmd = cmd

    def is_cached(self):
        return True


class WithNamespace(WithPrefix):
    """
    Helper class to allow WithNamespace to be used interchangeably with strings.
    """

    def __init__(self, namespace, cmd):
        super().__init__(["ip", "netns", "exec", namespace], cmd)


class PopenCollect:
    """
    Wrapper around :code:`subprocess.Popen` that collects stdout and stderr.
    """

    def __init__(self, proc, argv=None, argv_real=None, shell=None, use_cache=False):
        self.proc = proc
        self.argv = argv
        self.argv_real = argv_real
        self.shell = shell
        self.use_cache = use_cache
        self.returncode = None
        self.stdout = b""
        self.stderr = b""

    def read_and_poll(self):
        """
        Read stdout and stderr and poll for returncode.

        :returns: returncode or None if process is still running
        :rtype: int or None
        """

        cached_res = None
        if self.use_cache:
            cached_res = nmci.process.cache_load(self.argv_real)
            if cached_res is not None:
                self.returncode, self.stdout, self.stderr = cached_res

        if self.returncode is None:
            c = self.proc.poll()
            if self.proc.stdout is not None:
                self.stdout += self.proc.stdout.read()
            if self.proc.stderr is not None:
                self.stderr += self.proc.stderr.read()
            if c is None:
                return None
            self.returncode = c

        if self.use_cache and cached_res is None:
            nmci.process.cache_save(
                self.argv_real, self.returncode, self.stdout, self.stderr
            )
        return self.returncode

    def read_and_wait(self, timeout=None):
        """
        Read stdout and stderr and wait for returncode.

        :param timeout: timeout in seconds
        :type timeout: float
        :returns: returncode or None if process is still running
        :rtype: int or None
        """
        xtimeout = nmci.util.start_timeout(timeout)
        while True:
            c = self.read_and_poll()
            if c is not None:
                return c
            if xtimeout.expired():
                return None
            try:
                self.proc.wait(timeout=0.05)
            except subprocess.TimeoutExpired:
                pass

    def terminate_and_wait(self, timeout_before_kill=5):
        """
        Terminate process and wait for returncode.

        :param timeout_before_kill: timeout in seconds before sending SIGKILL
        :type timeout_before_kill: float
        :returns: returncode or None if process is still running
        :rtype: int or None
        """
        self.proc.terminate()
        if self.read_and_wait(timeout=timeout_before_kill) is not None:
            return
        self.proc.kill()
        self.read_and_wait()


class _Process:
    """
    Helper class to run commands and check their output.
    """

    def __init__(self):
        self.With = With
        self.WithShell = WithShell
        self.WithNamespace = WithNamespace
        self.WithPrefix = WithPrefix
        self.WithCache = WithCache
        self.PopenCollect = PopenCollect
        self.RunResult = RunResult
        self.IGNORE_RETURNCODE_ALL = IGNORE_RETURNCODE_ALL
        self.DEFAULT_PATTERN_FLAGS = DEFAULT_PATTERN_FLAGS

        self.exec = _Exec(self)
        self._cache_file = nmci.util.tmp_dir("nmci_process_cache")
        if os.path.isfile(self._cache_file):
            self._cache = json.loads(
                nmci.util.file_get_content_simple(self._cache_file)
            )
        else:
            self._cache = {}

    def _run_prepare_args(self, argv, shell, env, env_extra, namespace):
        if namespace:
            argv = WithNamespace(namespace, argv)

        argv_real = argv

        use_cache = False

        if isinstance(argv_real, With):
            shell = shell or argv_real.get_shell()
            if argv_real.is_cached():
                use_cache = True
            argv_real = argv_real.get_argv()

        if isinstance(argv_real, str):
            # For convenience, we allow argv as string.
            if shell:
                argv_real = [argv_real]
            else:
                argv_real = shlex.split(argv_real)

        if env_extra:
            if env is None:
                env = dict(os.environ)
            else:
                env = dict(env)
            env.update(env_extra)

        return argv, argv_real, shell, env, use_cache

    def Popen(
        self,
        argv,
        *,
        shell=False,
        cwd=None,
        env=None,
        env_extra=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        namespace=None,
    ):
        """
        Run a command and return a PopenCollect object. The PopenCollect object
        can be used to read stdout and stderr and to wait for the process to
        finish.

        :param argv: command to run
        :type argv: str or list
        :param shell: run command in shell, defaults to False
        :type shell: bool, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param stdout: stdout for the command, defaults to subprocess.PIPE
        :type stdout: file, optional
        :param stderr: stderr for the command, defaults to subprocess.PIPE
        :type stderr: file, optional
        :param namespace: namespace for the command, defaults to None
        :type namespace: str, optional
        :returns: PopenCollect object
        :rtype: PopenCollect
        """
        argv, argv_real, shell, env, use_cache = self._run_prepare_args(
            argv, shell, env, env_extra, namespace
        )

        if cwd is None:
            cwd = nmci.util.BASE_DIR

        proc = None
        if not use_cache or self.cache_load(argv_real) is None:
            proc = subprocess.Popen(
                argv_real,
                shell=shell,
                stdout=stdout,
                stderr=stderr,
                cwd=cwd,
                env=env,
            )

        return PopenCollect(
            proc, argv=argv, argv_real=argv_real, shell=shell, use_cache=use_cache
        )

    def raise_results(self, argv, header, result, exc_type=Exception):
        """
        Helper function to raise an exception containing output of the command.

        :param argv: command to run
        :type argv: str or list
        :param header: header for the exception
        :type header: str
        :param result: result of the command
        :type result: RunResult
        :param exc_type: Exception class to raise, default :code:`Exception`
        :type exc_type: class
        :raises Exception: exception containing output of the command
        """
        argv_real = self._run_prepare_args(argv, False, None, None, None)[1]

        argv_str = " ".join(
            [nmci.util.bytes_to_str(s, errors="replace") for s in argv_real]
        )

        msg = f"`{argv_str}` {header}"
        r_stderr = (
            "\nSTDERR:\n" + nmci.util.bytes_to_str(result.stderr, "replace")
            if result.stderr
            else ""
        )
        r_stdout = (
            "\nSTDOUT:\n" + nmci.util.bytes_to_str(result.stdout, "replace")
            if result.stdout
            else ""
        )

        msg += f"{r_stdout}{r_stderr}"
        raise exc_type(msg)

    def cache_load(self, argv):
        """
        Load cahed call

        :param argv: command line arguments
        :type argv: list of str
        :return: tuple of returncode, stdout, stderr, or None if not found
        :rtype: tuple
        """
        argv = " # ".join(argv)
        res = self._cache.get(argv, None)
        if res is None:
            return None
        return (res[0], res[1].encode("utf-8"), res[2].encode("utf-8"))

    def cache_save(self, argv, returncode, stdout, stderr):
        """
        Save command call into the cache

        :param argv: command line arguments
        :type argv: list of str
        :param returncode: returncode of the process
        :type returncode: int
        :param stdout: stdout of the process
        :type stdout: bytes
        :param stderr: stderr of the process
        :type stderr: bytes
        """
        argv = " # ".join(argv)
        self._cache[argv] = [returncode, stdout.decode("utf-8"), stderr.decode("utf-8")]
        nmci.util.file_set_content(self._cache_file, json.dumps(self._cache))

    def _run(
        self,
        argv,
        *,
        shell,
        as_bytes,
        timeout,
        cwd,
        env,
        env_extra,
        ignore_stderr,
        ignore_returncode,
        stdout,
        stderr,
        embed_combine_tag=TRACE_COMBINE_TAG,
        namespace=None,
    ):
        timeout = nmci.util.start_timeout(timeout)
        time_measure = nmci.util.start_timeout()

        argv, argv_real, shell, env, _ = self._run_prepare_args(
            argv, shell, env, env_extra, namespace
        )

        if cwd is None:
            cwd = nmci.util.BASE_DIR

        proc = None
        try:
            proc = subprocess.run(
                argv_real,
                shell=shell,
                stdout=stdout,
                stderr=stderr,
                timeout=timeout.remaining_time(),
                cwd=cwd,
                env=env,
            )
        except subprocess.TimeoutExpired as e:
            self.raise_results(
                argv_real,
                f"timed out in {e.timeout:.3f} seconds",
                RunResult(-1, e.stdout, e.stderr),
                exc_type=TimeoutError,
            )

        (returncode, r_stdout, r_stderr) = (proc.returncode, proc.stdout, proc.stderr)

        if r_stdout is None:
            r_stdout = b""
        if r_stderr is None:
            r_stderr = b""

        nmci.embed.embed_run(
            argv_real,
            shell,
            returncode,
            r_stdout,
            r_stderr,
            combine_tag=embed_combine_tag,
            elapsed_time=time_measure.elapsed_time(),
        )

        results = RunResult(returncode, r_stdout, r_stderr)

        # Depending on ignore_returncode we accept non-zero output. But
        # even then we want to fail for return codes that indicate a crash
        # (e.g. 134 for SIGABRT). If you really want to accept *any* return code,
        # set ignore_returncode=nmci.process.IGNORE_RETURNCODE_ALL.
        if (
            returncode == 0
            or (ignore_returncode is IGNORE_RETURNCODE_ALL)
            or (ignore_returncode and returncode > 0 and returncode <= 127)
        ):
            pass
        else:
            self.raise_results(argv_real, f"exited with {returncode}", results)

        if not ignore_stderr and r_stderr:
            # if anything was printed to stderr, we consider that a fail.
            self.raise_results(argv_real, "printed something to stderr", results)

        if not as_bytes:
            try:
                r_stdout = r_stdout.decode("utf-8", errors="strict")
            except UnicodeDecodeError as e:
                self.raise_results(argv_real, "printed non-utf-8 to stdout", results)

            try:
                r_stderr = r_stderr.decode("utf-8", errors="strict")
            except UnicodeDecodeError as e:
                self.raise_results(argv_real, "printed non-utf-8 to stderr", results)

        # Create new RunResult, r_stdout and r_stderr should be decoded here.
        return RunResult(returncode, r_stdout, r_stderr)

    def run(
        self,
        argv,
        *,
        shell=False,
        as_bytes=False,
        timeout=5,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=True,
        ignore_stderr=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        embed_combine_tag=TRACE_COMBINE_TAG,
        namespace=None,
    ):
        """
        Run a command and check its output. If the command fails, or
        prints anything to stderr, an exception is raised. Otherwise, a RunResult
        object is returned.

        :param argv: command to run
        :type argv: str or list
        :param shell: run command in shell, defaults to False
        :type shell: bool, optional
        :param as_bytes: return stdout and stderr as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 5
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to True
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to False
        :type ignore_stderr: bool, optional
        :param stdout: stdout for the command, defaults to subprocess.PIPE
        :type stdout: file, optional
        :param stderr: stderr for the command, defaults to subprocess.PIPE
        :type stderr: file, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :param namespace: namespace for the command, defaults to None
        :type namespace: str, optional
        :returns: RunResult object
        :rtype: RunResult
        """
        return self._run(
            argv,
            shell=shell,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=stdout,
            stderr=stderr,
            embed_combine_tag=embed_combine_tag,
            namespace=namespace,
        )

    def run_stdout(
        self,
        argv,
        *,
        shell=False,
        as_bytes=False,
        timeout=5,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=False,
        ignore_stderr=False,
        stderr=subprocess.PIPE,
        embed_combine_tag=TRACE_COMBINE_TAG,
        namespace=None,
    ):
        """
        Run a command and return its stdout. If the command fails, or prints
        anything to stderr, an exception is raised.

        :param argv: command to run
        :type argv: str or list
        :param shell: run command in shell, defaults to False
        :type shell: bool, optional
        :param as_bytes: return stdout as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 5
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to False
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to False
        :type ignore_stderr: bool, optional
        :param stderr: stderr for the command, defaults to subprocess.PIPE
        :type stderr: file, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :param namespace: namespace for the command, defaults to None
        :type namespace: str, optional
        :returns: stdout of the command
        :rtype: str or bytes
        """
        return self._run(
            argv,
            shell=shell,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=stderr,
            embed_combine_tag=embed_combine_tag,
            namespace=namespace,
        ).stdout

    def run_code(
        self,
        argv,
        *,
        shell=False,
        as_bytes=False,
        timeout=5,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=True,
        ignore_stderr=False,
        embed_combine_tag=TRACE_COMBINE_TAG,
        namespace=None,
    ):
        """
        Run a command and return its returncode. If the command fails, or prints
        anything to stderr, an exception is raised.

        :param argv: command to run
        :type argv: str or list
        :param shell: run command in shell, defaults to False
        :type shell: bool, optional
        :param as_bytes: return stdout and stderr as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 5
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to True
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to False
        :type ignore_stderr: bool, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :param namespace: namespace for the command, defaults to None
        :type namespace: str, optional
        :returns: returncode of the command
        :rtype: int
        """
        return self._run(
            argv,
            shell=shell,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            embed_combine_tag=embed_combine_tag,
            namespace=namespace,
        ).returncode

    def run_search_stdout(
        self,
        argv,
        pattern,
        *,
        shell=False,
        timeout=5,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=False,
        ignore_stderr=False,
        stderr=subprocess.PIPE,
        pattern_flags=DEFAULT_PATTERN_FLAGS,
        embed_combine_tag=TRACE_COMBINE_TAG,
        namespace=None,
    ):
        """
        Run a command and search its stdout for a pattern. If the command fails, or
        prints anything to stderr, an exception is raised. Otherwise, a re.Match
        object is returned.

        :param argv: command to run
        :type argv: str or list
        :param pattern: pattern to search for
        :type pattern: str or bytes or re.Pattern
        :param shell: run command in shell, defaults to False
        :type shell: bool, optional
        :param timeout: timeout for the command, defaults to 5
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to False
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to False
        :type ignore_stderr: bool, optional
        :param stderr: stderr for the command, defaults to subprocess.PIPE
        :type stderr: file, optional
        :param pattern_flags: pattern_flags for the command, defaults to re.DOTALL | re.MULTILINE
        :type pattern_flags: int, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :param namespace: namespace for the command, defaults to None
        :type namespace: str, optional
        :returns: re.Match object
        :rtype: re.Match
        """
        # autodetect based on the pattern
        if pattern_flags is DEFAULT_PATTERN_FLAGS:
            pattern_flags = re.DOTALL | re.MULTILINE
        if isinstance(pattern, bytes):
            as_bytes = True
        elif isinstance(pattern, str):
            as_bytes = False
        else:
            as_bytes = isinstance(pattern.pattern, bytes)
        result = self._run(
            argv,
            shell=shell,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=stderr,
            embed_combine_tag=embed_combine_tag,
            namespace=namespace,
        )
        return re.search(pattern, result.stdout, flags=pattern_flags)

    def nmcli(
        self,
        argv,
        *,
        as_bytes=False,
        timeout=60,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=False,
        ignore_stderr=False,
        ignore_stdout_error=False,
        embed_combine_tag=TRACE_COMBINE_TAG,
    ):
        """
        Run :code:`nmcli` command and check its output. If the command fails, or prints
        anything to stderr, an exception is raised. Otherwise, a RunResult
        object is returned.

        :param argv: nmcli arguments added to the command's execution
        :type argv: str or list
        :param as_bytes: return stdout and stderr as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 60
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to False
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to False
        :type ignore_stderr: bool, optional
        :param ignore_stdout_error: ignore stdout error of the command, defaults to False
        :type ignore_stdout_error: bool, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :returns: RunResult object
        :rtype: RunResult
        """
        nmcli_argv = WithPrefix(["nmcli"], argv)

        result = self._run(
            nmcli_argv,
            shell=False,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            embed_combine_tag=embed_combine_tag,
        )

        if not ignore_stdout_error:
            error = re.search(
                r"error.*",
                result.stdout,
                flags=re.IGNORECASE | re.DOTALL | re.MULTILINE,
            )
            if error is not None:
                self.raise_results(argv, "printed 'Error' on stdout", result)
            # do not re.IGNORECASE with Timeout, as timeout is used in `nmcli c show id ...`
            time_out = re.search(
                r"Timeout.*", result.stdout, flags=re.DOTALL | re.MULTILINE
            )
            if time_out is not None:
                self.raise_results(argv, "printed 'Timeout' on stdout", result)

        return result.stdout

    def nmcli_force(
        self,
        argv,
        *,
        as_bytes=False,
        timeout=60,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=True,
        ignore_stderr=True,
        embed_combine_tag=TRACE_COMBINE_TAG,
    ):
        """
        Run :code:`nmcli` command and check its output. If the command fails, or prints
        anything to stderr, an exception is raised. Otherwise, a RunResult object is returned.
        This function is used for commands that are expected to fail, but we want to check
        the output anyway.

        :param argv: nmcli arguments added to the command's execution
        :type argv: str or list
        :param as_bytes: return stdout and stderr as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 60
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to True
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to True
        :type ignore_stderr: bool, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :returns: RunResult object
        :rtype: RunResult
        """
        nmcli_argv = WithPrefix(["nmcli"], argv)

        return self._run(
            nmcli_argv,
            shell=False,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            embed_combine_tag=embed_combine_tag,
        )

    def systemctl(
        self,
        argv,
        *,
        as_bytes=False,
        timeout=60,
        cwd=None,
        env=None,
        env_extra=None,
        ignore_returncode=True,
        ignore_stderr=True,
        embed_combine_tag=TRACE_COMBINE_TAG,
    ):
        """
        Run :code:`systemctl` command and check its output. If the command fails, or prints
        anything to stderr, an exception is raised. Otherwise, a RunResult object is returned.

        :param argv: systemctl arguments added to the command's execution
        :type argv: str or list
        :param as_bytes: return stdout and stderr as bytes, defaults to False
        :type as_bytes: bool, optional
        :param timeout: timeout for the command, defaults to 60
        :type timeout: int, optional
        :param cwd: cwd for the command, None replaced by nmci.util.BASE_DIR, defaults to None
        :type cwd: str, optional
        :param env: env for the command, defaults to None
        :type env: dict, optional
        :param env_extra: env_extra for the command, defaults to None
        :type env_extra: dict, optional
        :param ignore_returncode: ignore returncode of the command, defaults to True
        :type ignore_returncode: bool, optional
        :param ignore_stderr: ignore stderr of the command, defaults to True
        :type ignore_stderr: bool, optional
        :param embed_combine_tag: embed_combine_tag for the command, defaults to TRACE_COMBINE_TAG
        :type embed_combine_tag: str, optional
        :returns: RunResult object
        :rtype: RunResult
        """
        s_argv = WithPrefix(["systemctl"], argv)

        return self._run(
            s_argv,
            shell=False,
            as_bytes=as_bytes,
            timeout=timeout,
            cwd=cwd,
            env=env,
            env_extra=env_extra,
            ignore_stderr=ignore_stderr,
            ignore_returncode=ignore_returncode,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            embed_combine_tag=embed_combine_tag,
        )


class _Exec:
    def __init__(self, process):
        self._process = process

    def chmod(self, mode, *files):
        self._process.run_stdout(["chmod", mode, *files])
        return


_module = _Process()
