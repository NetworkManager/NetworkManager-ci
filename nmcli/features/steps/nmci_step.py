import os
import subprocess
import time

IS_NMTUI = "nmtui" in __file__


###############################################################################


def run(context, command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        encoding="utf-8", *a, **kw):
    proc = subprocess.run(command, shell=shell, stdout=stdout, stderr=stderr,
                          encoding=encoding, *a, *kw)
    if not IS_NMTUI:
        if context is not None:
            command_calls = getattr(context, "command_calls", [])
            command_calls.append((command, proc.returncode, proc.stdout, proc.stderr))
    return (proc.stdout, proc.stderr, proc.returncode)


def command_output(context, command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   encoding="utf-8", *a, **kw):
    if IS_NMTUI:
        assert not a
        assert not kw
        if not os.path.isfile("/tmp/tui-screen.log"):
            return
        fd = open("/tmp/tui-screen.log", "a+")
        fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
        fd.flush()
        output, _, _ = run(context, command, shell=shell, stdout=stdout, stderr=stderr,
                           encoding=encoding, *a, *kw)
        fd.write(output + "\n")
        fd.flush()
        fd.close()
    else:
        output, err, code = run(context, command, shell=shell, stdout=stdout, stderr=stderr,
                                encoding=encoding, *a, *kw)
        assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
            % (command, code, output, err)
    return output


def command_output_err(context, command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       encoding="utf-8", *a, **kw):
    if IS_NMTUI:
        assert not a
        assert not kw
        if not os.path.isfile("/tmp/tui-screen.log"):
            return
        fd = open("/tmp/tui-screen.log", "a+")
        fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
        fd.flush()
        output, err, _ = run(context, command, shell=shell, stdout=stdout, stderr=stderr,
                             encoding=encoding, *a, *kw)
        fd.write(err + "\n")
        fd.flush()
        fd.close()
    else:
        output, err, code = run(context, command, shell=shell, stdout=stdout, stderr=stderr,
                                encoding=encoding, *a, *kw)
        assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
            % (command, code, output, err)
    return output, err


def command_code(context, command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                 encoding="utf-8", *a, **kw):
    _, _, code = run(context, command, shell=shell, stdout=stdout, stderr=stderr,
                     encoding=encoding, *a, *kw)
    return code


def additional_sleep(secs):
    if IS_NMTUI:
        time.sleep(secs)
