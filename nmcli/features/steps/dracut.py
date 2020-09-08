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


@step(u'Run dracut test')
def dracut_run(context):
    qemu_args = ""
    kernel_args = "rd.net.timeout.dhcp=3 panic=1 systemd.crash_reboot rd.shell=0 $DEBUGFAIL " \
                  "rd.retry=50 console=ttyS0,115200n81 selinux=0 noapic "
    initrd = "initramfs.client.NM"
    checks = ""
    log_contains = []
    log_not_contains = []
    for row in context.table:
        if "qemu" in row[0].lower():
            qemu_args += " " + row[1]
        elif "kernel" in row[0].lower():
            kernel_args += " " + row[1]
        elif "initrd" in row[0].lower():
            initrd = row[1]
        elif "check" in row[0].lower():
            checks += row[1] + " || die\n"
        elif "log+" in row[0].lower():
            log_contains.append(row[1])
        elif "log-" in row[0].lower():
            log_not_contains.append(row[1])

    with open("/tmp/client-check.sh", "w") as f:
        f.write("client_check() {\n" + checks + "}")

    rc = subprocess.call(
        "cd contrib/dracut/; . ./test_environment.sh; "
        "echo FAIL > $TESTDIR/client.img; "
        "cat check_lib/*.sh /tmp/client-check.sh > $TESTDIR/client_check.img; "
        "timeout 6m sudo bash ./run-qemu "
        "-drive format=raw,index=0,media=disk,file=$TESTDIR/client.img "
        "-drive format=raw,index=1,media=disk,file=$TESTDIR/client_check.img "
        "%s -append \"%s\" -initrd $TESTDIR/%s "
        "&> /tmp/dracut_run.log" % (qemu_args, kernel_args, initrd), shell=True)
    log = utf_only_open_read("/tmp/dracut_run.log")
    context.embed("text/plain", log, "DRACUT_RUN")
    assert rc == 0, "Test run FAILED"
    result = command_output(None,
                            "cd contrib/dracut; . ./test_environment.sh; cat $TESTDIR/client.img")
    assert "PASS" in result, "Test FAILED"

    for log_line in log_contains:
        assert log_line in log, "Fail: not visible in log:\n" + log_line
    for log_line in log_not_contains:
        assert log_line not in log, "Fail: visible in log:\n" + log_line
