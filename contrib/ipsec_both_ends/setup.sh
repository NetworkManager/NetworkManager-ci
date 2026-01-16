#!/bin/bash

# work in progress

set -x

# Default values
distro=centos:stream9
rpm_dir=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --distro|-d)
            if [[ $# -lt 2 ]]; then
                echo "Missing argument to '$1'"
                exit 1
            fi
            shift
            distro=$1
            shift
            ;;
        --rpm-dir|--rpm|-r)
            if [[ $# -lt 2 ]]; then
                echo "Missing argument to '$1'"
                exit 1
            fi
            shift
            rpm_dir=$1
            if [[ ! -d "$rpm_dir" ]]; then
                echo "Error: rpm directory '$rpm_dir' does not exist"
                exit 1
            fi
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --distro DISTRO    Container base image (default: centos:stream10)"
            echo "  -r, --rpm-dir DIR      Directory with RPM packages to install"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Export variables for common.sh
export distro
export rpm_dir

. common.sh

#  +----------------+      +----------------+      +----------------+
#  | 172.16.1.10/24 <------> 172.16.1.15/24 |      |                |
#  |  fd01::10/64   |  n1  |  fd01::15/64   |      |                |
#  |                |      |                |      |                |
#  |  ipsec-host1   |      |  ipsec-router  |      |  ipsec-host2   |
#  |                |      |                |      |                |
#  |                |      | 172.16.2.15/24 <------> 172.16.2.20/24 |
#  |                |      |  fd02::15/64   |  n2  |  fd02::20/64   |
#  +----------------+      +----------------+      +----------------+
#
image=ipsec
scriptdir="$(dirname "$(readlink -f "$0")")"
tmpdir=$(mktemp -d /tmp/libreswan-XXXXXX)

# trap 'rm -rf "$tmpdir"' EXIT

container_is_running() {
    test "$(podman ps --format "{{.ID}} {{.Names}}" | sed -n "s/ $1\$/\0/p")" != "" || return 1
}

generate_host_key()
{
    local container="$1"

    podman exec "$container" rm -f /var/lib/ipsec/nss/*.db /var/lib/ipsec/nss/pkcs11.txt
    podman exec "$container" ipsec initnss --nssdir /var/lib/ipsec/nss > /dev/null
    podman exec "$container" ipsec newhostkey /dev/null
    ckaid=$(podman exec "$container" ipsec showhostkey --list | tail -n 1 | grep -o "[0-9a-f]*$")
    key=$(podman exec "$container" ipsec showhostkey --left --ckaid $ckaid)
    echo "$key" | sed -e '/^\t#/d' -e 's/^\tleftrsasigkey=//'
}

replace_string()
{
    local from="$1"
    local to="$2"
    local file="$3"

    to_escaped=$(sed 's/[&/\]/\\&/g' <<< "$to")
    sed -i -e "s/$from/$to_escaped/g" "$file"
}

build_base_image()
{
    podman image exists "$image" && return

    mkdir -p $tmpdir/build/
    cp ~/.ssh/authorized_keys $tmpdir/build/

    # Copy RPM files if directory specified
    if [[ -n "$rpm_dir" && -d "$rpm_dir" ]]; then
        for rpm in "$rpm_dir"/*.rpm; do
            [[ -f "$rpm" ]] && cp "$rpm" "$tmpdir/build/"
        done
    fi

    cat <<EOF > "$tmpdir/build/Containerfile"
FROM $distro

ENTRYPOINT ["/sbin/init"]

COPY authorized_keys /root/.ssh/authorized_keys
COPY *.rpm /tmp

RUN dnf install -y libreswan \
    iputils \
    hostname \
    openssh-server \
    bash-completion \
    less \
    policycoreutils \
    gdb \
    valgrind \
    rsync \
    tcpdump \
    \$(ls /tmp/*.rpm) \
    --allowerasing
RUN systemctl enable sshd
RUN rm /etc/machine-id
EOF

    podman build \
           --squash-all \
           --tag "$image" \
           "$tmpdir/build"
}

build_base_image

if ! podman network exists n1; then
    podman network create --subnet 172.16.1.0/24 --ipv6 --subnet fd01::/64 n1
fi

if ! podman network exists n2; then
    podman network create --subnet 172.16.2.0/24 --ipv6 --subnet fd02::/64 n2
fi

# Restart the containers every time
podman stop "$c1" 2>/dev/null
podman stop "$c2" 2>/dev/null
podman stop "$cr" 2>/dev/null

if ! container_is_running "$c1"; then
    podman run \
           --rm \
           --privileged \
           --detach \
           --tty \
           -v $tmpdir:/tmp/ipsec \
           --network n1:ip=172.16.1.10,ip=fd01::10 \
           --dns=none \
           --name "$c1" \
           "$image"
fi


if ! container_is_running "$c2"; then
    podman run \
           --rm \
           --privileged \
           --detach \
           --tty \
           -v $tmpdir:/tmp/ipsec \
           --network n2:ip=172.16.2.20,ip=fd02::20 \
           --dns=none \
           --name "$c2" \
           "$image"
fi

if ! container_is_running "$cr"; then
    podman run \
           --rm \
           --privileged \
           --detach \
           --tty \
           -v $tmpdir:/tmp/ipsec \
           --network n1:ip=172.16.1.15,ip=fd01::15,interface_name=eth0 \
           --network n2:ip=172.16.2.15,ip=fd02::15,interface_name=eth1 \
           --name "$cr" \
           "$image"
fi

# On Rawhide firstboot service sometimes blocks boot
# Give some more time to the script to settle
sleep 2
echo " * Stopping systemd-firstboot service..."
podman exec "$c1" systemctl stop systemd-firstboot.service
podman exec "$c2" systemctl stop systemd-firstboot.service  
podman exec "$cr" systemctl stop systemd-firstboot.service
sleep 2

echo " * Setting up IPv6..."
podman exec "$c1" sh -c 'printf "[logging]\ndomains=ALL,VPN_PLUGIN:trace\n" > /etc/NetworkManager/conf.d/50-logging.conf'
podman exec "$c1" systemctl restart NetworkManager

podman exec "$c1" nmcli connection delete eth0
podman exec "$c1" nmcli connection add type ethernet ifname eth0 con-name eth0 \
       ip4 172.16.1.10/24 gw4 172.16.1.15 \
       ip6 fd01::10/64 gw6 fd01::15
podman exec "$c1" nmcli connection up eth0

podman exec "$c2" sh -c 'printf "[logging]\ndomains=ALL,VPN_PLUGIN:trace\n" > /etc/NetworkManager/conf.d/50-logging.conf'
podman exec "$c2" systemctl restart NetworkManager

podman exec "$c2" nmcli connection delete eth0
podman exec "$c2" nmcli connection add type ethernet ifname eth0 con-name eth0 \
       ip4 172.16.2.20/24 gw4 172.16.2.15 \
       ip6 fd02::20/64 gw6 fd02::15
podman exec "$c2" nmcli connection up eth0


podman exec "$cr" nmcli connection delete eth0 eth1
podman exec "$cr" nmcli connection add type ethernet ifname eth0 con-name eth0 \
       ip4 172.16.1.15/24 ip6 fd01::15/64
podman exec "$cr" nmcli connection up eth0

podman exec "$cr" nmcli connection add type ethernet ifname eth1 con-name eth1 \
       ip4 172.16.2.15/24 ip6 fd02::15/64
podman exec "$cr" nmcli connection up eth1

podman exec "$cr" sh -c "echo 1 > /proc/sys/net/ipv4/conf/all/forwarding"
podman exec "$cr" sh -c "echo 1 > /proc/sys/net/ipv6/conf/all/forwarding"

ip1=$(podman inspect "$c1" -f '{{ .NetworkSettings.Networks.n1.IPAddress }}')
ip2=$(podman inspect "$c2" -f '{{ .NetworkSettings.Networks.n2.IPAddress }}')

echo " * Setting hostnames ..."
podman exec "$c1" hostname hosta.example.org
podman exec "$c1" sh -c "echo hosta.example.org > /etc/hostname"
podman exec "$c2" hostname hostb.example.org
podman exec "$c2" sh -c "echo hostb.example.org > /etc/hostname"

echo " * Generating keys ..."
key1=$(generate_host_key "$c1")
key2=$(generate_host_key "$c2")

echo "   - key1: $key1"
echo "   - key2: $key2"

printf "$ip1 $ip2 : PSK \"a64-charslongrandomstringgeneratedwithpwgenoropensslorothertool\"" > "$tmpdir/ipsec.secrets"

podman exec "$c1" cp /tmp/ipsec/ipsec.secrets /etc/
podman exec "$c2" cp /tmp/ipsec/ipsec.secrets /etc/

echo " * Setting up certificates..."

for h in hosta.example.org hostb.example.org; do
    openssl pkcs12 -export -in "$scriptdir/certs/$h.crt" \
            -inkey "$scriptdir/certs/$h.key" \
            -certfile "$scriptdir/certs/ca.crt" \
            -passout pass:password \
            -out "$tmpdir/$h.p12"
done

podman exec "$c1" pk12util -i /tmp/ipsec/hosta.example.org.p12 \
       -d sql:/var/lib/ipsec/nss \
       -W password

podman exec "$c1" certutil -M \
       -n "nmstate-test-ca.example.org" -t CT,, -d sql:/var/lib/ipsec/nss

podman exec "$c2" pk12util -i /tmp/ipsec/hostb.example.org.p12 \
       -d sql:/var/lib/ipsec/nss \
       -W password
podman exec "$c2" pk12util -i /tmp/ipsec/hosta.example.org.p12 \
       -d sql:/var/lib/ipsec/nss \
       -W password

podman exec "$c2" certutil -M \
       -n "nmstate-test-ca.example.org" -t CT,, -d sql:/var/lib/ipsec/nss

echo " * Copying configurations ..."

cp -r "$scriptdir"/tests "$tmpdir"

for f in "$tmpdir"/tests/*/{1,2}.{conf,nmconnection}; do
    replace_string "@@KEY1@@" "$key1" "$f"
    replace_string "@@KEY2@@" "$key2" "$f"
done

podman exec "$c1" ls /tmp/ipsec/
podman exec "$c1" ls /tmp/ipsec/tests

podman exec "$c1" sh -c 'for f in $(ls /tmp/ipsec/tests/ | grep -v .sh); do cp /tmp/ipsec/tests/$f/1.conf /etc/ipsec.d/$f.conf; done'
podman exec "$c2" sh -c 'for f in $(ls /tmp/ipsec/tests/ | grep -v .sh); do cp /tmp/ipsec/tests/$f/2.conf /etc/ipsec.d/$f.conf; done'

podman exec "$c1" sh -c "mkdir /root/ipsec; cp -r /tmp/ipsec/tests /root/ipsec/"
podman exec "$c2" sh -c "mkdir /root/ipsec; cp -r /tmp/ipsec/tests /root/ipsec/"


echo " * Starting IPsec..."

podman exec "$c2" ipsec setup stop
podman exec "$c2" ipsec setup start
podman exec "$c1" ipsec setup stop
podman exec "$c1" ipsec setup start

# FIXME: add route to local libvirt network
podman exec "$c1" ip route add 192.168.122.0/24 via 172.16.1.1 dev eth0
podman exec "$c2" ip route add 192.168.122.0/24 via 172.16.2.1 dev eth0
