#!/usr/bin/env python3l
import psutil
import sys
import time
import signal

sys.path.append(".")
import nmci

samples = []


def log_average(signal, frame):
    global samples
    if samples:
        nmci.misc.journal_send(
            f"Average {proc_name} usage: {sum(samples)/len(samples)}"
        )
    else:
        nmci.misc.journal_send(f"No samples for {proc_name} found.")
    samples = []


signal.signal(signal.SIGUSR1, log_average)

proc_name = sys.argv[1]
thr = float(sys.argv[2])


def check_process_cpu(process_name, threshold):
    found = False
    for proc in psutil.process_iter(["pid", "name", "cpu_percent"]):
        if proc.info["name"] == process_name:
            found = True
            cpu_percent = proc.info["cpu_percent"]
            samples.append(cpu_percent)
            pid = proc.info["pid"]
            if cpu_percent > threshold:
                nmci.misc.journal_send(
                    f"ERROR: {process_name}[{pid}] usage too high: {cpu_percent}"
                )
            else:
                nmci.misc.journal_send(
                    f"{process_name}[{pid}] usage within threshold: {cpu_percent}"
                )
    if not found:
        nmci.misc.journal_send(f"ERROR: {process_name} process not found")


while True:
    check_process_cpu(proc_name, thr)
    time.sleep(0.1)
