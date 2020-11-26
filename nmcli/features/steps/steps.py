# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
import os
import pyte
import pexpect
import re
import subprocess
from subprocess import Popen, check_output, call
from behave import step
from time import sleep, time
from glob import glob

IS_NMTUI = "nmtui" in __file__


def run(context, command, *a, **kw):
    try:
        output = subprocess.check_output(
            command, shell=True, stderr=subprocess.STDOUT, *a, **kw
        ).decode("utf-8", "ignore")
        returncode = 0
        exception = None
    except subprocess.CalledProcessError as e:
        output = e.output.decode("utf-8", "ignore")
        returncode = e.returncode
        exception = e
    if not IS_NMTUI:
        if context is not None:
            data = "%s\nreturncode: %d\noutput:\n%s" % (command, returncode, output)
            context.embed("text/plain", data, caption=command[0:32] + "...")
    return output, returncode, exception


def command_output(context, command, *a, **kw):
    if IS_NMTUI:
        assert not a
        assert not kw
        if not os.path.isfile("/tmp/tui-screen.log"):
            return
        fd = open("/tmp/tui-screen.log", "a+")
        fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
        fd.flush()
        output, _, _ = run(context, command)
        fd.write(output + "\n")
        fd.flush()
        fd.close()
    else:
        output, code, e = run(context, command, *a, **kw)
        if code != 0:
            raise e
    return output


def command_code(context, command, *a, **kw):
    _, code, _ = run(context, command, *a, **kw)
    return code


def additional_sleep(time):
    if IS_NMTUI:
        sleep(time)
