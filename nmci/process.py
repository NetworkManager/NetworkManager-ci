import collections
import os
import re
import subprocess
import sys

from . import util


RunResult = collections.namedtuple("RunResult", ["returncode", "stdout", "stderr"])


IGNORE_RETURNCODE_ALL = object()


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
    context_hook,
):

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

    if context_hook is not None:
        context_hook("call", argv, shell, timeout)

    proc = subprocess.run(
        argv,
        shell=shell,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        cwd=cwd,
        env=env,
    )

    (returncode, stdout, stderr) = (proc.returncode, proc.stdout, proc.stderr)

    if context_hook is not None:
        context_hook("result", argv, returncode, stdout, stderr)

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
                stdout.decode("utf-8", errors="replace"),
                stderr.decode("utf-8", errors="replace"),
            )
        )

    if not ignore_stderr and stderr:
        # if anything was printed to stderr, we consider that a fail.
        raise Exception(
            "`%s` printed something on stderr: %s"
            % (
                " ".join([util.bytes_to_str(s, errors="replace") for s in argv]),
                stderr.decode("utf-8", errors="replace"),
            )
        )

    if not as_bytes:
        stdout = stdout.decode("utf-8", errors="strict")
        stderr = stderr.decode("utf-8", errors="strict")

    return RunResult(returncode, stdout, stderr)


def run(
    argv,
    *,
    shell=False,
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
        context_hook=context_hook,
    )


def run_stdout(
    argv,
    *,
    shell=False,
    as_bytes=False,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=False,
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
        context_hook=context_hook,
    ).stdout


def run_code(
    argv,
    *,
    shell=False,
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
        context_hook=context_hook,
    ).returncode


def run_search_stdout(
    argv,
    pattern,
    *,
    shell=False,
    timeout=5,
    cwd=util.BASE_DIR,
    env=None,
    env_extra=None,
    ignore_returncode=False,
    ignore_stderr=False,
    context_hook=None,
    pattern_flags=re.DOTALL | re.MULTILINE,
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
        context_hook=context_hook,
    )
    return re.search(pattern, result.stdout, flags=pattern_flags)
