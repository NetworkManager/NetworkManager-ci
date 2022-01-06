configure_basic_system () {
    [ -e /tmp/nm_eth_configured_part1 ] && return

    # Set the root password to 'networkmanager' (for overcoming polkit easily)
    echo "Setting root password to 'networkmanager'"
    echo "networkmanager" | passwd root --stdin

    echo "Setting test's password to 'networkmanager'"
    userdel -r test
    sleep 1
    useradd -m test
    echo "networkmanager" | passwd test --stdin

    # Adding chronyd and syncing
    systemctl restart chronyd.service

    # Pull in debugging symbols
    if [ ! -e /tmp/nm_no_debug ]; then
        cat /proc/$(pidof NetworkManager)/maps | awk '/ ..x. / {print $NF}' |
            grep '^/' | xargs rpm -qf | grep -v 'not owned' | sort | uniq |
            xargs debuginfo-install -y
    fi

    # Restart with valgrind
    if [ -e /etc/systemd/system/NetworkManager-valgrind.service ]; then
        ln -s NetworkManager-valgrind.service /etc/systemd/system/NetworkManager.service
        systemctl daemon-reload
    elif [[      -e /etc/systemd/system/NetworkManager.service.d/override.conf-strace
            && ! -e /etc/systemd/system/NetworkManager.service.d/override.conf ]]; then
        ln -s override.conf-strace /etc/systemd/system/NetworkManager.service.d/override.conf
        systemctl daemon-reload
    fi

    # Removing rate limit for systemd journaling
    sed -i -e '/^ *\(Storage\|SystemMaxUse\|RateLimitBurst\|RateLimitInterval\|SystemMaxFiles\|SystemMaxFileSize\)=.*/d' \
      /etc/systemd/journald.conf
    cat << EOF >> /etc/systemd/journald.conf
Storage=persistent
SystemMaxUse=25G
RateLimitBurst=0
RateLimitInterval=0
SystemMaxFiles=500
SystemMaxFileSize=256M
EOF
    systemctl restart systemd-journald.service

    # Set max corefile size to infinity
    sed 's/.*DefaultLimitCORE=.*/DefaultLimitCORE=infinity/g' -i /etc/systemd/system.conf
    systemctl daemon-reexec
    systemctl restart NetworkManager

    # Fake console
    echo "Faking a console session..."
    touch /run/console/test
    echo test > /run/console/console.lock

    # Passwordless sudo
    echo "enabling passwordless sudo"
    if [ -e /etc/sudoers.bak ]; then
    mv -f /etc/sudoers.bak /etc/sudoers
    fi
    cp -a /etc/sudoers /etc/sudoers.bak
    grep -v requiretty /etc/sudoers.bak > /etc/sudoers
    echo 'Defaults:test !env_reset' >> /etc/sudoers
    echo 'test ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers

    # Setting ulimit to unlimited for test user
    echo "ulimit -c unlimited" >> /home/test/.bashrc

    # set bash completion
    ln -s run/runtest.sh ./test_run.sh
    cp contrib/bash_completion/nmci.sh /etc/bash_completion.d/nmci

    # Deploy ssh-keys
    deploy_ssh_keys

    touch /tmp/nm_eth_configured_part1
}
