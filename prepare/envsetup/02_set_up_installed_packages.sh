configure_installed_packages () {
    systemctl enable --now podman.socket

    # build netdevsim driver - have to be done for image mode,
    # while building Docker image or while /usr is unlocked
    bash prepare/netdevsim.sh setup 1
    bash prepare/netdevsim.sh teardown
}