# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob

# Helpers for the steps that leave the execution trace

def run(context, command, *a, **kw):
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT, *a, **kw).decode('utf-8')
        returncode = 0
        exception = None
    except subprocess.CalledProcessError as e:
        output = e.output.decode('utf-8')
        returncode = e.returncode
        exception = e
    context.embed('text/plain', '$?=%d' % returncode, caption='%s result' % command)
    context.embed('text/plain', output, caption='%s output' % command)
    return output, returncode, exception

def command_output(context, command, *a, **kw):
    output, code, e = run(context, command, *a, **kw)
    if code != 0:
        raise e
    return output

def command_code(context, command, *a, **kw):
    _, code, _ = run(context, command, *a, **kw)
    return code

# may be usefull in another project (nmtui)
def additional_sleep(time):
    pass
