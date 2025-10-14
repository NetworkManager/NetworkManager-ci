#!/bin/bash
set -e

dnf=dnf
image_mode=false
grep -q ostree /proc/cmdline && dnf="dnf --transient" && image_mode=true

NM_CI_DIR=$1
cd $NM_CI_DIR
shift 1

cmd=$1
shift 1


if [ "$cmd" == "install" ]; then
    if ! [ -f /tmp/network_pkgs_installed ]; then
        set -x
        if [ "$(arch)" != "s390x" ]; then
          $image_mode && mount -o remount,rw lazy /usr || true
          bash contrib/utils/koji_links.sh NetworkManager-openvpn $(rpm -q NetworkManager-openvpn --qf '%{VERSION} %{RELEASE}') | xargs $dnf -y install
          $dnf -y install NetworkManager-libreswan-gnome
          $image_mode && mount -o remount,ro lazy /usr || true
        fi
        python3 -m pip install proxy.py
        systemctl restart NetworkManager
        touch /tmp/network_pkgs_installed
        set +x
    fi
elif [ "$cmd" == "envsetup" ]; then
    touch /tmp/keep_old_behave
    cp /etc/shadow /etc/shadow.backup
    bash -x prepare/envsetup.sh setup "$@"
    mv /etc/shadow.backup /etc/shadow
else
    chmod +x "$cmd"
    set -x
    ./$cmd "$@"
    set +x
fi
