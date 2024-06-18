#!/bin/bash
set -e

NM_CI_DIR=$1
cd $NM_CI_DIR
shift 1

cmd=$1
shift 1

nm_openvpn_gnome() {
  if grep -q 'release 10' in /etc/redhat-release; then
    dnf -y install \
      https://kojipkgs.fedoraproject.org/packages/NetworkManager-openvpn/1.10.2/6.fc40/$(arch)/NetworkManager-openvpn-1.10.2-6.fc40.$(arch).rpm \
      https://kojipkgs.fedoraproject.org/packages/NetworkManager-openvpn/1.10.2/6.fc40/$(arch)/NetworkManager-openvpn-gnome-1.10.2-6.fc40.$(arch).rpm
  elif grep -q 'release 9' in /etc/redhat-release; then
    dnf -y install \
      https://kojipkgs.fedoraproject.org/packages/NetworkManager-openvpn/1.10.2/1.el9/$(arch)/NetworkManager-openvpn-1.10.2-1.el9.$(arch).rpm \
      https://kojipkgs.fedoraproject.org/packages/NetworkManager-openvpn/1.10.2/1.el9/$(arch)/NetworkManager-openvpn-gnome-1.10.2-1.el9.$(arch).rpm
  elif grep -q 'release 8' in /etc/redhat-release; then
    dnf -y install \
      https://kojipkgs.fedoraproject.org//packages/NetworkManager-openvpn/1.8.10/1.fc30/$(arch)/NetworkManager-openvpn-1.8.10-1.fc30.$(arch).rpm \
      https://kojipkgs.fedoraproject.org//packages/NetworkManager-openvpn/1.8.10/1.fc30/$(arch)/NetworkManager-openvpn-gnome-1.8.10-1.fc30.$(arch).rpm
  fi
}

if [ "$cmd" == "install" ]; then
    if ! [ -f /tmp/network_pkgs_installed ]; then
        set -x
        if [ "$(arch)" != "s390x" ]; then
          if ! grep "release 10" /etc/redhat-release; then
            dnf -y install epel-release
            dnf -y install --enablerepo=epel NetworkManager-openvpn-gnome NetworkManager-openvpn
          fi
          nm_openvpn_gnome
          dnf -y install NetworkManager-libreswan-gnome NetworkManager-libreswan
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
