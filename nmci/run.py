import os
import subprocess
import time

IS_NMTUI = "nmtui" in __file__


###############################################################################


def run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        encoding="utf-8", *a, **kw):
    proc = subprocess.run(command, shell=shell, stdout=stdout, stderr=stderr,
                          encoding=encoding, *a, *kw)
    return (proc.stdout, proc.stderr, proc.returncode)


def command_output(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   encoding="utf-8", *a, **kw):
    output, err, code = run(command, shell=shell, stdout=stdout, stderr=stderr,
                            encoding=encoding, *a, *kw)
    assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
        % (command, code, output, err)
    return output


def command_output_err(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       encoding="utf-8", *a, **kw):
    output, err, code = run(command, shell=shell, stdout=stdout, stderr=stderr,
                            encoding=encoding, *a, *kw)
    assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
        % (command, code, output, err)
    return output, err


def command_code(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                 encoding="utf-8", *a, **kw):
    _, _, code = run(command, shell=shell, stdout=stdout, stderr=stderr,
                     encoding=encoding, *a, *kw)
    return code


def Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
          encoding="utf-8", *a, **kw):
    return subprocess.Popen(command, shell=shell, stdout=stdout, stderr=stderr,
                            encoding=encoding, *a, **kw)


def additional_sleep(secs):
    if IS_NMTUI:
        time.sleep(secs)
