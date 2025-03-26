configure_installed_packages () {
    systemctl enable --now podman.socket

    # build netdevsim driver - have to be done for image mode,
    # while building Docker image or while /usr is unlocked
    grep -q ostree /proc/cmdline && mount -o remount,rw lazy /usr
    bash prepare/netdevsim.sh setup 1
    bash prepare/netdevsim.sh teardown
    grep -q ostree /proc/cmdline && mount -o remount,ro lazy /usr
}