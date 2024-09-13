configure_installed_packages () {
    systemctl enable --now podman.socket
}
