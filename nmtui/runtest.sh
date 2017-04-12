#!/bin/bash
set -x

logger -t $0 "Running test $1"

if [ ! -e /tmp/nm_eth_configured ]; then
    #set the root password to 'networkmanager' (for overcoming polkit easily)
    echo "Setting root password to 'networkmanager'"
    echo "networkmanager" | passwd root --stdin

    echo "Setting test's password to 'networkmanager'"
    userdel -r test
    useradd -m test
    echo "networkmanager" | passwd test --stdin

    #adding ntp and syncing time
    yum -y install dnsmasq ntp tcpdump
    service ntpd restart
    sleep 10

    #removing rate limit for systemd journaling
    sed -i 's/^#\?\(RateLimitInterval *= *\).*/\10/' /etc/systemd/journald.conf
    sed -i 's/^#\?\(RateLimitBurst *= *\).*/\10/' /etc/systemd/journald.conf
    systemctl restart systemd-journald.service

    #fake console
    echo "Faking a console session..."
    touch /run/console/test
    echo test > /run/console/console.lock

    #passwordless sudo
    echo "enabling passwordless sudo"
    if [ -e /etc/sudoers.bak ]; then
    mv -f /etc/sudoers.bak /etc/sudoers
    fi
    cp -a /etc/sudoers /etc/sudoers.bak
    grep -v requiretty /etc/sudoers.bak > /etc/sudoers
    echo 'Defaults:test !env_reset' >> /etc/sudoers
    echo 'test ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers

    #setting ulimit to unlimited for test user
    echo "ulimit -c unlimited" >> /home/test/.bashrc

    #making sure all wifi devices are named wlanX
    NUM=0
    wlan=0
    if ! rpm -q --quiet NetworkManager-wifi; then
        yum -y install NetworkManager-wifi
    fi
    for DEV in `nmcli device | grep wifi | awk {'print $1'}`; do
        wlan=1
        ip link set $DEV down
        ip link set $DEV name wlan$NUM
        ip link set wlan$NUM up
        NUM=$(($NUM+1))
    done

    #installing behave and pexpect
    yum -y install install/*.rpm

    echo $1
    dcb_inf=0
    if [[ $1 == *dcb_* ]]; then
        dcb_inf=1
    fi
    if [[ $1 == *inf_* ]]; then
        dcb_inf=1
    fi

    veth=0
    if [ $wlan -eq 0 ]; then
        if [ $dcb_inf -eq 0 ]; then
            for X in $(seq 0 10); do
                if ! nmcli -f DEVICE -t device |grep eth${X}; then
                    veth=1
                    break
                fi
            done
        fi
    fi


    if [ $veth -eq 1 ]; then
        sh vethsetup.sh setup

        touch /tmp/nm_newveth_configured

    else
        #profiles tuning
        if [ $wlan -eq 0 ]; then
            if [ $dcb_inf -eq 0 ]; then
                nmcli connection add type ethernet ifname eth0 con-name testeth0
                nmcli connection delete eth0
                #nmcli connection modify testeth0 ipv6.method ignore
                nmcli connection up id testeth0
                nmcli con show -a
                for X in $(seq 1 10); do
                    nmcli connection add type ethernet con-name testeth$X ifname eth$X autoconnect no
                    nmcli connection delete eth$X
                done
                nmcli connection modify testeth10 ipv6.method auto
            fi
        fi
        if [ $wlan -eq 1 ]; then
            if [ ! "eth0" == $(nmcli -f TYPE,DEVICE -t c sh --active  | grep ethernet | awk '{split($0,a,":"); print a[2]}') ]; then
                DEV=$(nmcli -f TYPE,DEVICE -t c sh --active  | grep ethernet | awk '{split($0,a,":"); print a[2]}')
                UUID=$(nmcli -t -f UUID c show --active)
                sleep 0.5
                ip link set $DEV down
                ip link set $DEV name eth0
                nmcli con mod $UUID connection.interface-name eth0
                nmcli con mod $UUID connection.id testeth0
                ip link set eth0 up
                nmcli connection modify testeth0 ipv6.method auto
                kill -SIGHUP $(pidof NetworkManager)
                sleep 5
                nmcli c u testeth0
            fi
            # obtain valid certificates
            mkdir /tmp/certs
            wget http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem -O /tmp/certs/eaptest_ca_cert.pem
            wget http://wlan-lab.eng.bos.redhat.com/certs/client.pem -O /tmp/certs/client.pem
        fi
    fi

    touch /tmp/nm_eth_configured
fi

if [[ $1 == *dcb_* ]]; then
    if [ ! -e /tmp/dcb_configured ]; then
        #start dcb modules
        yum -y install lldpad fcoe-utils
        systemctl enable fcoe
        systemctl start fcoe
        systemctl enable lldpad
        systemctl start lldpad

        dcbtool sc enp4s0f0 dcb on

        touch /tmp/dcb_configured
    fi
fi

if [[ $1 == *inf_* ]]; then
    if [ ! -e /tmp/inf_configured ]; then
        nmcli dev disconnect mlx4_ib1
        nmcli dev disconnect mlx4_ib1.8005
        sleep 5
        nmcli connection delete mlx4_ib1
        nmcli connection delete mlx4_ib1.8005
        sleep 5

        touch /tmp/inf_configured
    fi
fi

# install the pyte VT102 emulator
if [ ! -e /tmp/nmtui_pyte_installed ]; then
    easy_install pip
    pip install pyte

    touch /tmp/nmtui_pyte_installed
fi

# can't have the default 'dumb' for curses to "work" even if we redirect output
# for the internal pyte based terminal
export TERM=vt102

# set TEST variable for version_control script
if [ -z "$TEST" ]; then
    TEST="NetworkManager_Test0_$1"
fi

#check if NM version is correct for test
TAG=$(python version_control.py nmtui $TEST); vc=$?
if [ $vc -eq 1 ]; then
    echo "Skipping due to incorrect NM version for this test"
    # exit 0 doesn't affect overal result
    exit 0

elif [ $vc -eq 0 ]; then
    if [ x$TAG != x"" ]; then
        echo "Running $TAG version of $TEST"
        behave nmtui/features --no-capture --no-capture-stderr -k -t $1 -t $TAG -f plain -o /tmp/report_$TEST.log; rc=$?
    else
        behave nmtui/features --no-capture --no-capture-stderr -k -t $1 -f plain -o /tmp/report_$TEST.log; rc=$?
    fi
fi

RESULT="FAIL"
if [ $rc -eq 0 ]; then
    RESULT="PASS"
fi

# only way to have screen snapshots for each step present in the individual logs
# the tui-screen log is created via environment.py
cat /tmp/tui-screen.log >> /tmp/report_$TEST.log

# this is to see the semi-useful output in the TESTOUT for failed tests too
echo "--------- /tmp/report_$TEST.log ---------"
cat /tmp/report_$TEST.log

rhts-report-result $TEST $RESULT "/tmp/report_$TEST.log"

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
