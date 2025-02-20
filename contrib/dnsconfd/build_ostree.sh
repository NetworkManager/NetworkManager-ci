#!/bin/bash

if grep f40 /etc/os-release || grep el10 /etc/os-release || grep el9 /etc/os-release; then
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" install dnf "$(rpm -q --whatprovides system-release)" openvpn NetworkManager-openvpn selinux-policy unbound selinux-policy-base
else
  dnf -y --setopt=install_weak_deps=False --use-host-config --installroot="$PWD/tests/baseroot" install dnf "$(rpm -q --whatprovides system-release)" openvpn NetworkManager-openvpn selinux-policy selinux-policy-base
fi;
if grep el10 /etc/os-release; then
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" install -y $(./tests/./koji_links.sh unbound 1.20.0 |grep -v devel |grep -v debug*)
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" install -y $(./tests/./koji_links.sh NetworkManager |grep -v devel |grep -v debug*)
elif grep el9 /etc/os-release; then
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" install -y $(./tests/./koji_links.sh unbound 1.16.2 |grep -v devel |grep -v debug*)
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" install -y $(./tests/./koji_links.sh NetworkManager |grep -v devel |grep -v debug*)
elif grep f40 /etc/os-release; then
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" copr enable networkmanager/NetworkManager-1.52-debug
  dnf -y --setopt=install_weak_deps=False --releasever=/ --installroot="$PWD/tests/baseroot" upgrade -y NetworkManager-1.51.90*
else
  dnf -y --setopt=install_weak_deps=False --use-host-config --installroot="$PWD/tests/baseroot" copr enable networkmanager/NetworkManager-1.52-debug
  dnf -y --setopt=install_weak_deps=False --use-host-config --installroot="$PWD/tests/baseroot" upgrade -y NetworkManager-1.51.90*
fi

