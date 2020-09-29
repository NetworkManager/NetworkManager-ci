#!/bin/bash

cd /tmp/dracut_test/

mkdir mnt
mount server.ext3 mnt/

journalctl --root=mnt/nfs/client/ -b --no-pager $@
umount mnt
rmdir mnt
