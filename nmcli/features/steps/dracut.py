# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import sys
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob
import json
from steps import command_output, command_code, additional_sleep


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        return open(file, mode).read().decode('utf-8', 'ignore').encode('utf-8')
    else:
        return open(file, mode, encoding='utf-8', errors='ignore').read()


@step(u'Setup dracut test "{testdir}"')
def dracut_test(context, testdir):
    with open("/tmp/dracut_test_dirname", "w") as f:
        f.write(testdir)
    rc = subprocess.call(
        "cd %s; timeout 6m sudo basedir=/usr/lib/dracut/ testdir=../ "
        "bash ./test.sh --setup &> /tmp/dracut_setup.log"
        % (testdir), shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/dracut_setup.log"), "DRACUT_SETUP")
    assert rc == 0, "Test setup failed"


@step(u'Run dracut test "{testdir}" named "{testname}"')
def dracut_run(context, testname, testdir):
    rc = subprocess.call(
        "cd %s; timeout 6m sudo basedir=/usr/lib/dracut/ testdir=../ TEST_TO_RUN='%s' "
        "bash ./test.sh --run &> /tmp/dracut_run.log"
        % (testdir, testname), shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/dracut_run.log"), "DRACUT_RUN")
    assert rc == 0, "Test run failed"
