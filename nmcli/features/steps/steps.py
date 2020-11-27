# -*- coding: UTF-8 -*-
import os
import pexpect
import pyte
import re
import subprocess
import time

IS_NMTUI = "nmtui" in __file__


def run(context, command, *a, **kw):
    proc = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          encoding="utf-8", *a, *kw)
    if not IS_NMTUI:
        if context is not None:
            data = "%s\nreturncode: %d\noutput:\n%s" % (command, proc.returncode, proc.stdout)
            context.embed("text/plain", data, caption=command[0:32] + "...")
    return (proc.stdout, proc.returncode)


def command_output(context, command, *a, **kw):
    if IS_NMTUI:
        assert not a
        assert not kw
        if not os.path.isfile("/tmp/tui-screen.log"):
            return
        fd = open("/tmp/tui-screen.log", "a+")
        fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
        fd.flush()
        output, _ = run(context, command)
        fd.write(output + "\n")
        fd.flush()
        fd.close()
    else:
        output, code = run(context, command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d\noutput:\n%s" % (command, code, output)
    return output


def command_code(context, command, *a, **kw):
    _, code = run(context, command, *a, **kw)
    return code


def additional_sleep(secs):
    if IS_NMTUI:
        time.sleep(secs)
