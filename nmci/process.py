import collections
import os
import re
import subprocess
import sys
import time

from . import util


RunResult = collections.namedtuple("RunResult", ["returncode", "stdout", "stderr"])


IGNORE_RETURNCODE_ALL = object()

SHELL_AUTO = object()


class WithShell:
    def __init__(self, cmd):
        assert isinstance(cmd, str)
        self.cmd = cmd

    def __str__(self):
        return self.cmd


def _run_prepare_args(argv, shell, env, env_extra):

    if shell is SHELL_AUTO:
        # Autodetect whether to use a shell.
        if isinstance(argv, WithShell):
            argv = argv.cmd
            shell = True
        else:
            shell = False
    else:
        shell = True if shell else False

    argv_real = argv

    if isinstance(argv_real, str):
        # For convenience, we allow argv as string.
        if shell:
            argv_real = [argv_real]
        else:
            import shlex

            argv_real = shlex.split(argv_real)

    if env_extra:
        if env is None:
            env = dict(os.environ)
        else:
            env = dict(env)
        env.update(env_extra)

    return argv, argv_real, shell, env


class PopenCollect:
    def __init__(self, proc, argv=None, argv_real=None, shell=None):
        self.proc = proc
        self.argv = argv
        self.argv_real = argv_real
        self.shell = shell
        self.returncode = None
        self.stdout = b""
        self.stderr = b""

    def read_and_poll(self):

        if self.returncode is None:
            c = self.proc.poll()
            if self.proc.stdout is not None:
                self.stdout += self.proc.stdout.read()
            if self.proc.stderr is not None:
                self.stderr += self.proc.stderr.read()
            if c is None:
                return None
            self.returncode = c

        return self.returncode

    def read_and_wait(self, timeout=None):
        if timeout is None:
            pass
        elif timeout == 0 or timeout == 0.0:
            timeout = 0
        else:
            expiry = time.monotonic() + timeout
        while True:
            c = self.read_and_poll()
            if c is not None:
                return c
            if timeout is not None:
                if timeout == 0:
                    return None
                if time.monotonic() >= expiry:
                    return None
            try:
                self.proc.wait(timeout=0.05)
            except subprocess.TimeoutExpired:
                pass

    def terminate_and_wait(self, timeout_before_kill=5):
        self.proc.terminate()
        if self.read_and_wait(timeout=timeout_before_kill) is not None:
            return
        self.proc.kill()
        self.read_and_wait()


def Popen(
    argv,
    *,
    shell=SHELL_AUTO,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    context_hook=None,
):

    argv, argv_real, shell, env = _run_prepare_args(argv, shell, env, env_extra)

    if context_hook is not None:
        context_hook("popen-call", argv_real, shell)

    proc = subprocess.Popen(
        argv_real,
        shell=shell,
        stdout=stdout,
        stderr=stderr,
        cwd=cwd,
        env=env,
    )

    return PopenCollect(proc, argv=argv, argv_real=argv_real, shell=shell)


def _run(
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
    context_hook,
):

    argv, argv_real, shell, env = _run_prepare_args(argv, shell, env, env_extra)

    if context_hook is not None:
        context_hook("call", argv_real, shell, timeout)

    proc = subprocess.run(
        argv_real,
        shell=shell,
        stdout=stdout,
        stderr=stderr,
        timeout=timeout,
        cwd=cwd,
        env=env,
    )

    (returncode, r_stdout, r_stderr) = (proc.returncode, proc.stdout, proc.stderr)

    if r_stdout is None:
        r_stdout = b""
    if r_stderr is None:
        r_stderr = b""

    if context_hook is not None:
        context_hook("result", argv_real, shell, returncode, r_stdout, r_stderr)

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
        raise Exception(
            "`%s` returned exit code %s\nSTDOUT:\n%s\nSTDERR:\n%s"
            % (
                " ".join([util.bytes_to_str(s, errors="replace") for s in argv_real]),
                returncode,
                r_stdout.decode("utf-8", errors="replace"),
                r_stderr.decode("utf-8", errors="replace"),
            )
        )

    if not ignore_stderr and r_stderr:
        # if anything was printed to stderr, we consider that a fail.
        raise Exception(
            "`%s` printed something on stderr: %s"
            % (
                " ".join([util.bytes_to_str(s, errors="replace") for s in argv_real]),
                r_stderr.decode("utf-8", errors="replace"),
            )
        )

    if not as_bytes:
        r_stdout = r_stdout.decode("utf-8", errors="strict")
        r_stderr = r_stderr.decode("utf-8", errors="strict")

    return RunResult(returncode, r_stdout, r_stderr)


def run(
    argv,
    *,
    shell=SHELL_AUTO,
    as_bytes=False,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=True,
    ignore_stderr=False,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    context_hook=None,
):
    return _run(
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
        context_hook=context_hook,
    )


def run_stdout(
    argv,
    *,
    shell=SHELL_AUTO,
    as_bytes=False,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=False,
    ignore_stderr=False,
    stderr=subprocess.PIPE,
    context_hook=None,
):
    return _run(
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
        context_hook=context_hook,
    ).stdout


def run_code(
    argv,
    *,
    shell=SHELL_AUTO,
    as_bytes=False,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=True,
    ignore_stderr=False,
    context_hook=None,
):
    return _run(
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
        context_hook=context_hook,
    ).returncode


def run_search_stdout(
    argv,
    pattern,
    *,
    shell=SHELL_AUTO,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=False,
    ignore_stderr=False,
    stderr=subprocess.PIPE,
    pattern_flags=re.DOTALL | re.MULTILINE,
    context_hook=None,
):
    # autodetect based on the pattern
    if isinstance(pattern, bytes):
        as_bytes = True
    elif isinstance(pattern, str):
        as_bytes = False
    else:
        as_bytes = isinstance(pattern.pattern, bytes)
    result = _run(
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
        context_hook=context_hook,
    )
    return re.search(pattern, result.stdout, flags=pattern_flags)


def nmcli(
    argv,
    *,
    as_bytes=False,
    timeout=60,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=False,
    ignore_stderr=False,
    context_hook=None,
):
    if isinstance(argv, str):
        argv = f"nmcli {argv}"
    else:
        argv = ["nmcli", *argv]

    return _run(
        argv,
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
        context_hook=context_hook,
    ).stdout


def nmcli_force(
    argv,
    *,
    as_bytes=False,
    timeout=60,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=True,
    ignore_stderr=True,
    context_hook=None,
):
    if isinstance(argv, str):
        argv = f"nmcli {argv}"
    else:
        argv = ["nmcli", *argv]

    return _run(
        argv,
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
        context_hook=context_hook,
    )


def systemctl(
    argv,
    *,
    as_bytes=False,
    timeout=60,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=True,
    ignore_stderr=True,
    context_hook=None,
):
    if isinstance(argv, str):
        argv = f"systemctl {argv}"
    else:
        argv = ["systemctl", *argv]

    return _run(
        argv,
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
        context_hook=context_hook,
    )
