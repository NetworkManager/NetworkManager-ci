#!/usr/bin/env python3
import time
import os

FREEZE_FILE = "/tmp/dracut_dhcpd_freeze"

last_freeze = 0

if os.path.isfile(FREEZE_FILE):
    with open(FREEZE_FILE) as f:
        last_freeze = float(f.read())

now = time.time()
if now - last_freeze > 10:
    with open(FREEZE_FILE, "w") as f:
        f.write(str(now))
    time.sleep(8)
