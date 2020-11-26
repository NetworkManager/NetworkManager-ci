# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
import os
import pyte
import pexpect
import re
import subprocess
from behave import step
from time import sleep
from subprocess import check_output


def run(context, command, *a, **kw):
    try:
        output = subprocess.check_output(
            command, shell=True, stderr=subprocess.STDOUT, *a, **kw
        ).decode("utf-8", "ignore")
        returncode = 0
        exception = None
    except subprocess.CalledProcessError as e:
        output = str(e.output)
        returncode = e.returncode
        exception = e
    return output, returncode, exception


def command_output(context, command):
    if not os.path.isfile("/tmp/tui-screen.log"):
        return
    fd = open("/tmp/tui-screen.log", "a+")
    fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
    fd.flush()
    output, _, _ = run(context, command)
    fd.write(output + "\n")
    fd.flush()
    fd.close()
    return output


def command_code(context, command, *a, **kw):
    _, code, _ = run(context, command, *a, **kw)
    return code


# will sleep, because in nmtui
def additional_sleep(time):
    sleep(time)
