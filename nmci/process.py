import collections
import os
import re
import subprocess
import sys

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


def _run_prepare_args(argv, shell, env, env_extra, stdout, stderr):

    if shell is SHELL_AUTO:
        # Autodetect whether to use a shell.
        if isinstance(argv, WithShell):
            argv = argv.cmd
            shell = True
        else:
            shell = False
    else:
        shell = True if shell else False

    if isinstance(argv, str):
        # For convenience, we allow argv as string.
        if shell:
            argv = [argv]
        else:
            import shlex

            argv = shlex.split(argv)

    if env_extra:
        if env is None:
            env = dict(os.environ)
        else:
            env = dict(env)
        env.update(env_extra)

    if stdout is None:
        stdout = subprocess.PIPE

    if stderr is None:
        stderr = subprocess.PIPE

    return argv, shell, env, stdout, stderr


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

    argv, shell, env, stdout, stderr = _run_prepare_args(
        argv, shell, env, env_extra, stdout, stderr
    )

    if context_hook is not None:
        context_hook("call", argv, shell, timeout)

    proc = subprocess.run(
        argv,
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
        context_hook("result", argv, shell, returncode, r_stdout, r_stderr)

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
                " ".join([util.bytes_to_str(s, errors="replace") for s in argv]),
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
                " ".join([util.bytes_to_str(s, errors="replace") for s in argv]),
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
    stdout=None,
    stderr=None,
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
    stderr=None,
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
        stdout=None,
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
        stdout=None,
        stderr=None,
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
    stderr=None,
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
        stdout=None,
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
        stdout=None,
        stderr=None,
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
        stdout=None,
        stderr=None,
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
        stdout=None,
        stderr=None,
        context_hook=context_hook,
    )
