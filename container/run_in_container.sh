#!/bin/bash
# MVP helper to run a single NM-CI test inside a disposable CentOS Stream 10
# container instead of a full Beaker round-trip. See
# nmt-agentic-sdlc/.claude/skills/nmci-testing/TODO.md item #12.
#
# Unlike run/centos-ci/node_runner.py (CentOS CI's own orchestration, not
# relevant here), this does NOT pre-provision the machine by hand. It only
# installs NetworkManager and clones the repo; test_run.sh's own
# configure_environment() does the rest, exactly as it would on any other
# fresh machine. Needs real root (rootful podman) -- systemd-udevd can't
# initialize the container's network device under rootless podman, which
# leaves it permanently "unmanaged" in NetworkManager.
set -euo pipefail

step() { echo; echo "==> $*"; }

# Best-effort, silent self-install of contrib/bash_completion/nmci.sh (which
# also covers this script) into the invoking user's bash-completion dynamic
# loader dir, so colleagues get tab-completion the first time they run this
# without needing to know the file exists or source/symlink it by hand. This
# script runs as root (via sudo), so $HOME here is root's, not the actual
# user's -- resolve via $SUDO_USER instead, and hand the result back to them
# (chown) since mkdir/ln as root would otherwise leave it unusable without
# sudo. Does nothing (not an error) if bash-completion's dynamic loader
# isn't set up on this machine -- it's just an unused symlink in that case.
install_bash_completion() {
    local home dir target src
    if [ -n "${SUDO_USER:-}" ]; then
        home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    else
        home="$HOME"
    fi
    [ -n "$home" ] || return 0
    dir="$home/.local/share/bash-completion/completions"
    target="$dir/run_in_container.sh"
    [ -e "$target" ] && return 0
    src="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/contrib/bash_completion/nmci.sh"
    mkdir -p "$dir" 2>/dev/null || return 0
    ln -s "$src" "$target" 2>/dev/null || return 0
    [ -n "${SUDO_UID:-}" ] && chown -R "$SUDO_UID:$SUDO_GID" "$home/.local/share/bash-completion" 2>/dev/null
    echo "(installed bash completion for run_in_container.sh -- open a new shell to use it)" >&2
}
install_bash_completion

DISTRO="c10s"
NM_SOURCE="main"
NMCI_BRANCH="main"
EXTRA_TAGS=""
FEATURES=""
FORCE_REINSTALL=0
SAVE_IMAGE=""
PUSH_IMAGE=0
SHELL_ONLY=0
REFRESH=0
CLEAN=0
REBOOT=0
NMCI_URL="https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git"
CONTAINER_REPO="/root/NetworkManager-ci"

usage() {
    cat <<EOF
Usage: $0 [options]

  -d, --distro <name>       c10s (default) or c9s -- picks the prebaked image
                            (quay.io/nmstate/nmci-<name>:latest), container name
                            (nmci-<name>) and EPEL version to match. Override any of these
                            individually with the env vars below if needed.
  -n, --nm-version <src>    main (default, COPR networkmanager/NetworkManager-main-debug),
                            X.YY (e.g. 1.58, shorthand for the per-branch COPR
                            networkmanager/NetworkManager-X.YY-debug), copr:<user>/<project>,
                            or skip (use whatever ships in the image)
  -b, --nmci-branch <name>  branch of NetworkManager-ci to clone (default: main)
  -t, --tags <tag> [<tag> ...]
                            extra test tag(s) to run, one at a time (default: none).
                            'pass' always runs first as a sanity check.
  -F, --feature <name> [<name> ...]
                            run one or more whole features via run/runfeature.sh (all their
                            mapper.yaml tests) after the tags above, e.g. 'bond wifi gsm'.
                            'gate' is special: runs every mapper.yaml test tagged 'gate'
                            (across all features, via run/runtests.sh) instead of a feature
                            literally named 'gate'. 'all' is likewise special: every test in
                            mapper.yaml's default testmapper (not the hardware-only
                            NetworkManager-wifi/-wwan/-infiniband subcomponent sections) --
                            expect dracut to skip -- its whole feature file carries a
                            feature-level @skip_in_centos tag, unrelated to nested virt.
  -f, --force               reinstall NetworkManager even if already present in the container
                            (bandwidth note: reusing an existing container skips both the NM
                            install and the git clone/pull when nothing changed -- good for
                            metered connections)
  -s, --save-image <tag>    on success, 'podman commit' the container to <tag> (e.g.
                            quay.io/you/nmci-c10s:baked) so a future run can start from it via
                            NMCI_CONTAINER_IMAGE=<tag> instead of redoing dnf/pip/git work.
  -P, --push                with --save-image, also 'podman push' the tag automatically on
                            success. You still need to be logged in yourself beforehand
                            (podman login <registry>) -- this won't handle credentials.
  --shell                   skip NM install/clone/tests, just start the container (if needed)
                            and drop into an interactive shell inside it. Also offered
                            interactively at the end of a normal run (when attached to a TTY).
  -r, --refresh             remove the existing container for this --distro first (e.g. if it
                            got into a bad state), so this run starts from a clean one. Only
                            removes the container, not the shared network or other distros.
  --reboot                  podman restart the existing container and exit (no install/tests).
                            Cheaper than --refresh for a container whose networking got wedged
                            (e.g. a test that did 'modprobe -r veth' or otherwise broke eth0) --
                            keeps the installed NM build and git checkout, just redoes the
                            per-boot fixups (resolv.conf/hostname unmount, openvswitch unmask,
                            re-activating the pinned eth0 profile) that podman only applies at
                            container start, not automatically on every restart. Presets
                            /tmp/nm_packages_installed and /tmp/nm_eth_configured_part1 (that
                            on-disk state survives the restart) but clears
                            /tmp/nm_eth_configured and /tmp/nm_veth_configured, since the
                            container's network namespace -- and with it every veth testbed
                            device (eth1-eth10/testeth1-eth10) -- is destroyed and recreated on
                            restart and must be regenerated by the next test run.
  -c, --clean               remove the container for this --distro and exit (no install/tests).
                            Also removes the shared network and its DHCP/DNS server, but only
                            once no nmci container (any distro) is using them anymore.
  -h, --help                show this help

Environment variables (override the --distro-derived defaults individually):
  NMCI_CONTAINER_IMAGE     base image (default: quay.io/nmstate/nmci-<distro>:latest -- set
                           to quay.io/nmstate/<distro>-nmstate-dev:latest for the plain
                           nmstate base image instead, e.g. before nmci-<distro> is baked)
  NMCI_CONTAINER_NAME      container name (default: nmci-<distro>)
  NMCI_CONTAINER_NETWORK   podman network name (default: nmci-egress)
  NMCI_CONTAINER_IP        pinned container IP (default: 203.0.113.10)

Examples:
  $0
      Just the sanity check: c10s, NM main from COPR, the 'pass' test.

  $0 --distro c9s --nm-version main --tags bond_add_default_bond
      c9s instead of c10s, one extra test after 'pass'.

  $0 --nm-version 1.58 --feature bond wifi
      Specific stable-branch COPR build, run the whole bond and wifi features.

  $0 --feature gate
      Every mapper.yaml test tagged 'gate', across all features.

  $0 --nm-version skip --save-image localhost/nmci-c10s:latest --push
      Use whatever NM ships in the image, bake + push the result on success
      (needs 'podman login <registry>' done beforehand).

  $0 --shell
      Skip everything, just get a shell in the (new or existing) container.

  $0 --reboot
      Container's networking got wedged (e.g. a test removed the veth
      kernel module) -- restart it and redo the per-boot fixups, without
      reinstalling NM or re-cloning NM-CI.

  $0 --clean
      Tear down the container for this --distro (and the shared network/DHCP+DNS
      server too, once no nmci container is left using them).

  $0 --clean && $0 --distro c9s --clean
      Full teardown of both distros -- the second call also removes the
      shared network/DHCP+DNS server since nothing's left using them.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--distro) DISTRO="$2"; shift 2 ;;
        -n|--nm-version) NM_SOURCE="$2"; shift 2 ;;
        -b|--nmci-branch) NMCI_BRANCH="$2"; shift 2 ;;
        -F|--feature)
            shift
            FEATURES=""
            while [ $# -gt 0 ] && [[ "$1" != -* ]]; do
                FEATURES="$FEATURES $1"
                shift
            done
            FEATURES="${FEATURES# }"
            ;;
        -f|--force) FORCE_REINSTALL=1; shift ;;
        -s|--save-image) SAVE_IMAGE="$2"; shift 2 ;;
        -P|--push) PUSH_IMAGE=1; shift ;;
        --shell) SHELL_ONLY=1; shift ;;
        -r|--refresh) REFRESH=1; shift ;;
        --reboot) REBOOT=1; shift ;;
        -c|--clean) CLEAN=1; shift ;;
        -t|--tags)
            shift
            EXTRA_TAGS=""
            while [ $# -gt 0 ] && [[ "$1" != -* ]]; do
                EXTRA_TAGS="$EXTRA_TAGS $1"
                shift
            done
            EXTRA_TAGS="${EXTRA_TAGS# }"
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    echo "This needs real root (rootful podman), not sudo-less/rootless -- systemd-udevd" >&2
    echo "can't initialize the container's network device under rootless podman, which" >&2
    echo "leaves it permanently 'unmanaged' in NetworkManager. Re-run with sudo." >&2
    exit 1
fi

case "$DISTRO" in
    c10s|c9s) ;;
    *) echo "Unknown --distro: $DISTRO (expected c10s or c9s)" >&2; exit 1 ;;
esac

# A distro+timestamp subdirectory per run -- otherwise a second run (e.g.
# c9s after c10s, or just a re-run) dumps its reports into the same flat
# directory and overwrites/mixes with the previous run's same-named files.
REPORT_DIR="$(pwd)/.tmp/container-reports/$(date +%Y%m%d-%H%M%S)-$DISTRO"

# Our own prebaked image (see -s/--save-image/-P/--push above) -- built on
# top of nmstate's dev image (quay.io/nmstate/<distro>-nmstate-dev, which
# ships systemd-udevd, NetworkManager and openvswitch preinstalled and
# enabled -- see nmstate/packaging/Dockerfile.<distro>-nmstate-dev) but with
# NM/pkg_install_common's dnf work already done, so a fresh run doesn't
# redo it every time. Override with NMCI_CONTAINER_IMAGE=quay.io/nmstate/
# <distro>-nmstate-dev:latest to go back to the plain nmstate base (e.g. if
# nmci-<distro> hasn't been baked/pushed for a given distro yet).
CONTAINER_NAME="${NMCI_CONTAINER_NAME:-nmci-$DISTRO}"
IMAGE="${NMCI_CONTAINER_IMAGE:-quay.io/nmstate/nmci-$DISTRO:latest}"
NETWORK_NAME="${NMCI_CONTAINER_NETWORK:-nmci-egress}"

container_exec() {
    podman exec "$CONTAINER_NAME" bash -lc "$*"
}

NETWORK_SUBNET="203.0.113.0/24"
NETWORK_GATEWAY="203.0.113.1"
# Distinct per distro so a c10s and a c9s container can run at the same time
# on the shared nmci-egress network without an IPAM collision.
case "$DISTRO" in
    c10s) DISTRO_IP_SUFFIX=10 ;;
    c9s) DISTRO_IP_SUFFIX=9 ;;
esac
CONTAINER_IP="${NMCI_CONTAINER_IP:-203.0.113.$DISTRO_IP_SUFFIX}"

# Default podman network (pasta) exposes a tun-type device that NM refuses to
# manage by policy, so nmcli never reports "connected". A plain bridge network
# fixes that (real ethernet-type device), but its default 10.88.0.0/16 subnet
# turned out to be unreachable to the internet on some corp VPN setups
# (apparently treated as internal-only). Use a dedicated network outside
# 10.0.0.0/8 instead, created on first use so this works on any machine
# without manual pre-setup.
ensure_network() {
    if podman network exists "$NETWORK_NAME"; then
        # aardvark-dns (podman's own per-network DNS) manages /etc/resolv.conf
        # itself and fights with NetworkManager over it -- a test setting
        # ipv4.dns-search never shows up there, it stays pinned to aardvark's
        # own "search dns.podman ..." content. --disable-dns turns that off
        # so NM fully owns /etc/resolv.conf like on a real machine. Recreate
        # if an older version of this network predates that flag.
        if [ "$(podman network inspect "$NETWORK_NAME" --format '{{.DNSEnabled}}' 2>/dev/null)" != "false" ]; then
            step "Recreating '$NETWORK_NAME' with --disable-dns (was fighting NM over /etc/resolv.conf)"
            podman network rm -f "$NETWORK_NAME" >/dev/null
        fi
    fi
    if ! podman network exists "$NETWORK_NAME"; then
        step "Creating podman network '$NETWORK_NAME' ($NETWORK_SUBNET, outside 10.0.0.0/8)"
        podman network create --subnet "$NETWORK_SUBNET" --gateway "$NETWORK_GATEWAY" --disable-dns "$NETWORK_NAME"
    fi
    # NOT calling ensure_dhcp_server here: the bridge's kernel interface
    # (e.g. podman1) doesn't actually exist until a container connects to
    # this network -- `podman network create` only writes its config. See
    # the ensure_dhcp_server call after the container itself is up.
}

# podman's IPAM only assigns eth0's own address at container-creation time --
# there's no real DHCP server on this network, so any *other* connection a
# test creates with the default ipv4.method=auto just hangs until it times
# out (e.g. gate's ipv4_dns-search_add et al). With --disable-dns above,
# aardvark-dns is also gone, so this dnsmasq now does double duty: DHCP, and
# (since --disable-dns leaves no other resolver on this network) DNS too,
# forwarding to whatever the host itself uses -- so containers get real
# internet DNS the same way a real machine would.
DHCP_PIDFILE="/run/nmci-egress-dnsmasq.pid"
DHCP_RANGE_START="203.0.113.100"
DHCP_RANGE_END="203.0.113.200"
ensure_dhcp_server() {
    # Always restart rather than reuse -- cheap, and avoids serving a stale
    # config (e.g. a leftover --port=0 instance) after a script update.
    if [ -f "$DHCP_PIDFILE" ]; then
        kill "$(cat "$DHCP_PIDFILE")" 2>/dev/null || true
        rm -f "$DHCP_PIDFILE"
    fi
    if ! command -v dnsmasq >/dev/null; then
        echo "WARNING: dnsmasq not found on the host -- tests that create their own" >&2
        echo "         DHCP-based connections will hang until timeout, and containers" >&2
        echo "         will have no DNS at all. Install it (dnf install dnsmasq)." >&2
        return
    fi
    local bridge_if
    bridge_if=$(podman network inspect "$NETWORK_NAME" --format '{{.NetworkInterface}}' 2>/dev/null)
    if [ -z "$bridge_if" ]; then
        echo "WARNING: couldn't determine bridge interface for $NETWORK_NAME, skipping" >&2
        echo "         DHCP/DNS server (tests needing them will time out)." >&2
        return
    fi
    step "Starting DHCP+DNS server (dnsmasq) on $bridge_if for $NETWORK_NAME"
    # podman1 et al are typically unassigned to any specific zone (falls
    # back to the default zone), unlike an interface explicitly zoned by
    # the user -- so fall back to --get-default-zone when the interface
    # itself has none, same default zone the masquerade rule lives in.
    local zone
    zone=$(firewall-cmd --get-zone-of-interface="$bridge_if" 2>/dev/null || true)
    [ -z "$zone" ] && zone=$(firewall-cmd --get-default-zone 2>/dev/null || true)
    [ -n "$zone" ] && firewall-cmd --zone="$zone" --add-port=67/udp --add-port=53/udp --add-port=53/tcp >/dev/null 2>&1 || true
    dnsmasq \
        --interface="$bridge_if" --bind-interfaces --except-interface=lo \
        --dhcp-range="$DHCP_RANGE_START,$DHCP_RANGE_END,12h" \
        --dhcp-option=option:router,"$NETWORK_GATEWAY" \
        --dhcp-option=option:dns-server,"$NETWORK_GATEWAY" \
        --pid-file="$DHCP_PIDFILE"
}

# Only tears down the shared network/DHCP+DNS server once no nmci container
# (any distro) is left using them -- they're shared across a c10s and a c9s
# container running at the same time.
do_clean() {
    step "Removing container $CONTAINER_NAME"
    podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    local other any_left=0
    for other in c10s c9s; do
        [ "$other" = "$DISTRO" ] && continue
        podman container exists "nmci-$other" 2>/dev/null && any_left=1
    done
    if [ "$any_left" -eq 1 ]; then
        echo "Other nmci containers still exist -- leaving shared network '$NETWORK_NAME' and its DHCP/DNS server running."
        return
    fi
    step "No nmci containers left -- also removing network '$NETWORK_NAME' and its DHCP/DNS server"
    podman network rm -f "$NETWORK_NAME" >/dev/null 2>&1 || true
    if [ -f "$DHCP_PIDFILE" ]; then
        kill "$(cat "$DHCP_PIDFILE")" 2>/dev/null || true
        rm -f "$DHCP_PIDFILE"
    fi
}

# podman's IPAM assigns eth0's address once, at container-creation time, via
# netlink -- there is no real DHCP server on this network. NM initially
# "assumes" that static config into a transient /run/NetworkManager profile,
# which works fine until something restarts NM with a clean runtime state
# (e.g. prepare/vethsetup.sh's own crash-recovery path, which nukes
# /var/run/NetworkManager). At that point NM has no persistent profile to
# fall back to, tries DHCP, gets no answer, and eth0 never comes back --
# breaking test_run.sh's own network-setup dance (ORIG_DEV ends up empty).
# Write a real, persistent keyfile matching the pinned --ip so eth0 survives
# an NM restart the same way a real DHCP-leased or statically-configured
# machine would.
ETH0_UUID="b3f6b3a0-19cf-4a00-9000-1eb300000000"
write_static_eth0_profile() {
    step "Writing persistent static NM profile for eth0 ($CONTAINER_IP)"
    podman exec -i "$CONTAINER_NAME" bash -c 'cat > /etc/NetworkManager/system-connections/eth0.nmconnection' <<EOF
[connection]
id=eth0
uuid=$ETH0_UUID
type=ethernet
interface-name=eth0
autoconnect=true

[ipv4]
method=manual
address1=$CONTAINER_IP/24,$NETWORK_GATEWAY
dns=$NETWORK_GATEWAY;

[ipv6]
method=disabled
EOF
    container_exec "chmod 600 /etc/NetworkManager/system-connections/eth0.nmconnection"
}

# On every boot/restart, regardless of the persistent profile above already
# existing on disk, NM finds eth0 already carrying an IP (podman assigned it
# via netlink before NM ever started) and "assumes" it into its own
# generic externally-managed connection (managed-type: 'external',
# ipv4.dns empty) instead of activating our matching keyfile -- confirmed
# via `nmcli connection show --active` showing a different UUID each time
# than our fixed $ETH0_UUID. Force our profile to actually take over.
restart_nm_and_wait_for_dns() {
    container_exec "systemctl restart NetworkManager"
    local i
    for i in $(seq 1 10); do
        container_exec "nmcli connection up uuid $ETH0_UUID" 2>/dev/null && break
        sleep 0.5
    done
    # NM regenerates /etc/resolv.conf asynchronously after that -- give it a
    # moment so callers right after this (e.g. dnf install) don't race a
    # window where the file has no nameserver yet.
    local i
    for i in $(seq 1 20); do
        container_exec "grep -q '^nameserver' /etc/resolv.conf" 2>/dev/null && return
        sleep 0.5
    done
    echo "WARNING: /etc/resolv.conf had no nameserver line after 10s -- DNS may not work yet." >&2
}

# `podman restart` (as opposed to the initial `podman run`) re-establishes
# podman's own /etc/resolv.conf/hostname/hosts bind mounts and re-masks
# openvswitch.service, but doesn't rerun any of the one-time fixups
# ensure_container() applies right after creation -- so a container that
# gets restarted (e.g. to recover from a test that broke eth0, such as one
# doing 'modprobe -r veth', which also takes down the container's own veth
# uplink) comes back with /etc/resolv.conf busy again and openvswitch
# masked. This redoes just those fixups, without reinstalling NM or
# re-cloning NM-CI like a full --refresh would.
do_reboot() {
    if ! podman container exists "$CONTAINER_NAME"; then
        echo "No container '$CONTAINER_NAME' to reboot -- nothing to do." >&2
        exit 1
    fi
    step "Restarting $CONTAINER_NAME"
    podman restart "$CONTAINER_NAME" >/dev/null
    ensure_dhcp_server
    echo "Waiting for systemd to settle..."
    container_exec "systemctl is-system-running --wait" || true
    container_exec "umount /etc/resolv.conf 2>/dev/null; rm -f /etc/resolv.conf; umount /etc/hostname 2>/dev/null; umount /etc/hosts 2>/dev/null; true"
    restart_nm_and_wait_for_dns
    step "Starting openvswitch (safe now that the bridge is in active use)"
    container_exec "umount /etc/systemd/system/multi-user.target.wants/openvswitch.service 2>/dev/null; systemctl daemon-reload; systemctl start openvswitch" || true
    # On-disk state (packages, sudoers, systemd overrides, ...) survives the
    # restart, so skip redoing those. The veth testbed does NOT survive --
    # the container's network namespace, and every device in it
    # (eth1-eth10/testeth1-eth10), is destroyed and recreated by the
    # restart -- clear these so the next test run regenerates it instead of
    # trusting a now-stale "already configured" marker.
    step "Marking packages/base-system config as still valid, clearing veth testbed markers"
    container_exec "touch /tmp/nm_packages_installed /tmp/nm_eth_configured_part1; rm -f /tmp/nm_eth_configured /tmp/nm_veth_configured"
    # Kernel modules are host-global, not per-netns, so a restart doesn't
    # reset them -- only the netns-scoped pieces of configure_networking()
    # (the veth testbed itself) actually need redoing. Do that now, right
    # away, rather than leaving the container in a half-usable state until
    # whatever runs the next test lazily triggers it via test_run.sh.
    step "Regenerating the veth testbed"
    container_exec "cd $CONTAINER_REPO && bash prepare/vethsetup.sh check"

    if [ -t 0 ] && [ -t 1 ]; then
        read -r -p "Drop into a shell in $CONTAINER_NAME? [y/N] " ans
        if [[ "$ans" =~ ^[Yy] ]]; then
            exec podman exec -it "$CONTAINER_NAME" bash -lc "cd $CONTAINER_REPO 2>/dev/null; exec bash"
        fi
    fi
}

# Containers share the host's actual running kernel, but get their own
# separate /lib/modules/ (populated by whatever kernel-modules-* packages
# *their* distro's package manager resolves, not the host's real kernel
# version) -- so modprobe run *inside* the container fails to find modules
# even when the host's kernel has them, unless the module is already loaded
# and therefore shared kernel-wide (confirmed with `bonding`: 112/120 bond
# tests passed on a host kernel that only had it loaded, not on disk in the
# container). Pre-load the ones NM-CI commonly needs on the host itself so
# tests that just use (not reload) them work; warn about whatever's missing
# so a later test failure isn't a surprise.
preload_host_kernel_modules() {
    local mods="bonding dummy sch_netem ip_gre ip6_gre sit ip_tunnel ip6_tunnel ip_vti ip6_vti mac80211_hwsim macsec wireguard netdevsim"
    local missing=()
    local m
    for m in $mods; do
        lsmod | grep -q "^$m " && continue
        modprobe "$m" 2>/dev/null || missing+=("$m")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "WARNING: could not load these kernel modules on the host: ${missing[*]}" >&2
        echo "         Tests needing them will fail inside the container (this is a" >&2
        echo "         host/kernel limitation, not a container or NM-CI bug)." >&2
    fi
}

# prepare/netdevsim.sh's from-source build downloads a kernel-source RPM
# matching $(uname -r) via a URL chosen by reading /etc/redhat-release --
# but in a container /etc/redhat-release describes the *image's* distro
# while $(uname -r) is always the *host's* kernel (shared, not the image's
# own), so whenever those differ (e.g. a CentOS Stream image on a Fedora
# host) it ends up requesting a source RPM that doesn't exist and fails.
# Recent kernels increasingly don't need the patches at all (the
# permanent-address support they add merged upstream in mid-2025), so
# rather than guessing from a version number, actually probe the stock
# module's behavior. If it already provides everything the patches add
# (channels, ring, coalesce, permanent address), skip the build by
# pre-creating its "already installed" marker; otherwise leave the marker
# unset so the from-source build still runs (works fine when the host
# kernel and the image's distro actually match, e.g. a real RHEL host
# running its matching RHEL-flavored image).
netdevsim_stock_module_has_needed_features() {
    local out
    out=$(container_exec '
        # netdevsim is host-global (kernel modules are not namespaced per
        # container), and this probe -- like prepare/netdevsim.sh itself --
        # always uses hardcoded device id 0. A container that got
        # force-removed mid-test (e.g. --refresh) can leave device 0
        # registered on the host with no net/ interface behind it (its
        # netns is long gone), which makes new_device below fail with
        # "File exists" and the rest of the probe silently operate on
        # nothing. Clean up any such leftover before starting.
        echo 0 > /sys/bus/netdevsim/del_device 2>/dev/null
        modprobe -r netdevsim 2>/dev/null
        modprobe netdevsim 2>&1
        echo "0 0 128" > /sys/bus/netdevsim/new_device 2>&1
        echo "1 6e:81:1e:c4:50:01" > /sys/bus/netdevsim/devices/netdevsim0/new_port 2>&1
        for _ in $(seq 1 20); do
            iface=$(ls /sys/devices/netdevsim*/net/ 2>/dev/null)
            [ -n "$iface" ] && break
            sleep 0.2
        done
        ethtool -l "$iface" 2>&1
        ethtool -P "$iface" 2>&1
        echo 0 > /sys/bus/netdevsim/del_device 2>/dev/null
        modprobe -r netdevsim 2>/dev/null
    ')
    if echo "$out" | grep -q "Combined:[[:space:]]*128" && \
        echo "$out" | grep -q "Permanent address: 6e:81:1e:c4:50:01"; then
        return 0
    fi
    echo "---- netdevsim probe output (for diagnosing the warning below) ----" >&2
    echo "$out" >&2
    echo "---------------------------------------------------------------------" >&2
    return 1
}

ensure_container() {
    preload_host_kernel_modules
    ensure_network
    if [ "$REFRESH" -eq 1 ] && podman container exists "$CONTAINER_NAME"; then
        step "Refreshing: removing existing container $CONTAINER_NAME"
        podman rm -f "$CONTAINER_NAME" >/dev/null
    fi
    if podman container exists "$CONTAINER_NAME"; then
        step "Reusing existing container $CONTAINER_NAME"
        podman start "$CONTAINER_NAME" >/dev/null
        # The bridge's kernel interface only exists once a container is
        # actually attached to it, so this can't run any earlier than here.
        ensure_dhcp_server
    else
        step "Starting new container $CONTAINER_NAME from $IMAGE"
        # The nmstate-dev image auto-enables openvswitch at boot. Its
        # ovs-kmod-ctl helper does its own kernel module bookkeeping and,
        # since kernel modules are host-global (not namespaced per
        # container), ends up rmmod-ing the *host's* `bridge` module a couple
        # seconds after boot -- silently killing the just-created podman
        # bridge network from under us. Block the auto-start by shadowing its
        # multi-user.target enablement symlink from container creation
        # onward (masking it *after* boot would race the rmmod). Tests that
        # actually need OVS can still `systemctl start openvswitch` later.
        # Without --dns/--dns-search, podman's default is to copy the
        # *host's* own /etc/resolv.conf (nameservers AND search domain)
        # into the container verbatim -- on a VPN that bakes in the
        # current user's corporate nameservers/domain, useless (and wrong)
        # for anyone else running this. Point it at our own dnsmasq and
        # clear the search domain instead.
        # Bind-mount the host's real kernel module tree (read-only) so the
        # container's own modprobe can find modules for the kernel it's
        # actually (and always) running on top of -- the container's own
        # package manager only ever populates /lib/modules for whatever
        # kernel version *it* believes it's on, which never matches a
        # different host distro/kernel (e.g. EL10 container on a Fedora
        # host). Without this, an explicit `modprobe <mod>` call from a
        # test (e.g. macsec_psk's `modprobe macsec`) fails with "Module ...
        # not found" even when that module is already loaded host-wide.
        # NOT done for mac80211_hwsim: that driver auto-creates net devices
        # at load time bound to whatever netns loaded it, so a
        # container-side modprobe would misplace them in the container's
        # own netns while the auto-created radios stay invisible to
        # anything expecting them in init_net -- moot here since macsec/
        # wireguard/etc. only create devices on demand via netlink, always
        # in the caller's own netns.
        # chronyd is permanently masked, never unmasked: the container's
        # clock is the host's (no independent time namespace), so it has
        # nothing to sync and no test needs it. Left running, it repeatedly
        # queries public NTP pool servers -- traffic that PBR/routing tests
        # (e.g. policy_based_routing_doc_procedure) can route straight into
        # their own synthetic `ip netns` topology once a test connection
        # becomes the system default route, causing that netns to emit a
        # burst of ICMP redirects. Those compete with the SAME netns's
        # ICMP-error rate-limit budget (net.ipv4.icmp_ratelimit, which a
        # fresh `ip netns add` always resets to the kernel default -- it is
        # not inherited from the parent netns) and can silently swallow an
        # expected ICMP time-exceeded reply the test is waiting for.
        # ipsec.service is likewise permanently masked, never unmasked: the
        # baked image happened to have it enabled+running when captured (a
        # stale artifact from whatever the container was doing at bake
        # time), so it auto-starts at boot on every container spun up from
        # that image from then on -- not something any test setup here
        # actually requests. It loads ip_vti/ip6_vti/xfrm_interface at
        # startup for VTI support, pinning them loaded forever, which then
        # makes any test that tries `modprobe -r ip6_tunnel`/`ip_tunnel`
        # (e.g. ipv6_tunnel_module_removal) fail with "Module ... is in
        # use" even though it never touched those modules itself. NM-CI's
        # own libreswan-tagged scenarios (prepare/libreswan.sh) don't rely
        # on this systemd unit at all -- they spawn their own `ipsec pluto`
        # by hand inside a dedicated netns -- so masking it doesn't affect
        # them.
        # --cap-drop=SYS_BOOT: --privileged grants every capability
        # including CAP_SYS_BOOT, and systemd running as the container's
        # PID 1 treats SIGINT the same way it would on a real console
        # (Ctrl-Alt-Del -> reboot). If that signal ever reaches PID 1
        # directly (e.g. `podman attach` instead of `podman exec -it ...
        # bash` -- attach connects straight to the container's main
        # process console, exec does not), CAP_SYS_BOOT is what lets
        # reboot() actually do something instead of failing with EPERM.
        # Drop it explicitly so a stray signal here can, at worst, kill
        # the container's own namespace -- never the host.
        podman run -d --name "$CONTAINER_NAME" \
            --privileged \
            --cap-drop=SYS_BOOT \
            --systemd=always \
            --network="$NETWORK_NAME" \
            --ip="$CONTAINER_IP" \
            --dns="$NETWORK_GATEWAY" \
            --dns-search=. \
            -v "/lib/modules/$(uname -r):/lib/modules/$(uname -r):ro" \
            -v /dev/null:/etc/systemd/system/multi-user.target.wants/openvswitch.service:ro \
            -v /dev/null:/etc/systemd/system/multi-user.target.wants/chronyd.service:ro \
            -v /dev/null:/etc/systemd/system/multi-user.target.wants/ipsec.service:ro \
            "$IMAGE" /sbin/init
        ensure_dhcp_server
        echo "Waiting for systemd to settle..."
        container_exec "systemctl is-system-running --wait" || true
        write_static_eth0_profile
        # podman bind-mounts /etc/resolv.conf, /etc/hostname AND /etc/hosts
        # itself -- that's how --dns/--dns-search above take effect -- but
        # it means NM/hostnamed (or any test doing a plain `sed -i`, which
        # renames a temp file over the original) can never replace their
        # contents: "write to /etc/resolv.conf failed (rc-manager=symlink,
        # ... Device or resource busy)", "Failed to set static hostname:
        # ... Device or resource busy" and "sed: cannot rename ...: Device
        # or resource busy" (on /etc/hosts, e.g. prepare/captive_portal.sh)
        # are the exact same mechanism. Unmount all three so they're
        # ordinary files, same as a real machine. Done *after*
        # write_static_eth0_profile (see its restart function's comment for
        # why the order matters), and the actual NM restart happens only
        # once, here.
        container_exec "umount /etc/resolv.conf 2>/dev/null; rm -f /etc/resolv.conf; umount /etc/hostname 2>/dev/null; umount /etc/hosts 2>/dev/null; true"
        restart_nm_and_wait_for_dns
        # Now that the network is up and stable, the bridge module is
        # actively in use -- so it's safe to lift the openvswitch.service
        # block from container creation above: ovs-kmod-ctl's own rmmod of
        # 'bridge' will just fail harmlessly (module in use) instead of
        # succeeding and killing the podman bridge network out from under
        # us, like it would at boot. OVS-dependent tests need the service
        # actually running, not just present.
        step "Starting openvswitch (safe now that the bridge is in active use)"
        container_exec "umount /etc/systemd/system/multi-user.target.wants/openvswitch.service 2>/dev/null; systemctl daemon-reload; systemctl start openvswitch" || true
        # `audit` (ausearch, used by nmci's embed_avcs()), `hostname` (the
        # `hostname` command, used by e.g. @restore_hostname), `sudo`
        # (used by e.g. @insufficient_perms_* to actually drop privileges),
        # `fuse-overlayfs` (libreswan tests run a *nested* podman container
        # as the simulated remote gateway via nmstate's IpsecTestEnv --
        # see the storage.conf fixup right below for why installing the
        # package alone isn't enough), `ethtool`
        # (needed a few lines down by netdevsim_stock_module_has_needed_features,
        # before pkg_install_common would otherwise install it), `e2fsprogs`
        # (mkfs.ext4, used by contrib/dracut/setup.sh to build the dracut
        # test root/iscsi filesystems), and `dracut-network` (ships the
        # `35network-manager` dracut module -- without it `dracut -a
        # network-manager` fails with "Module 'network-manager' cannot be
        # found") are all missing from the minimal image but always present
        # on a real machine. Needed regardless of --nm-version, so this
        # can't live in install_nm()'s COPR-only path (skipped entirely by
        # -n skip).
        local missing_pkgs="\
            audit \
            hostname \
            sudo \
            fuse-overlayfs \
            ethtool \
            e2fsprogs \
            dracut-network"
        container_exec "rpm -q $missing_pkgs &>/dev/null || dnf -y install $missing_pkgs"
        # The image ships no /etc/containers/storage.conf at all, so a
        # nested `podman run` (e.g. nmstate's IpsecTestEnv, which launches a
        # libreswan gateway container of its own) falls back to podman's
        # compiled-in default of the *native* overlay driver -- which can't
        # stack on top of our own container's root, itself already overlay:
        # "configure storage: 'overlay' is not supported over overlayfs, a
        # mount_program is required: backing file system is unsupported for
        # this graph driver". fuse-overlayfs (installed above) sidesteps
        # that restriction by doing the overlay in userspace via FUSE
        # instead of the kernel driver, but only if actually configured as
        # the mount_program -- merely having the binary installed and
        # available on $PATH does nothing on its own.
        container_exec "mkdir -p /etc/containers"
        podman exec -i "$CONTAINER_NAME" bash -c 'cat > /etc/containers/storage.conf' <<'EOF'
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
        # The c9s-nmstate-dev image bakes in its own minimal /etc/sudoers
        # (just a NOPASSWD grant for a 'test' user, no 'root ALL=(ALL) ALL')
        # -- installing the sudo package can't overwrite it (%config(noreplace))
        # and drops its real default as /etc/sudoers.rpmnew instead.
        # prepare/envsetup/01_configure_system.sh then backs up and re-derives
        # from that already-broken file, permanently missing the root grant,
        # which makes @insufficient_perms_* tests fail with "root is not in
        # the sudoers file" instead of the polkit denial they're testing for.
        # Restore the real default before test_run.sh ever runs.
        container_exec "[ -e /etc/sudoers.rpmnew ] && cp -f /etc/sudoers.rpmnew /etc/sudoers; true"
        # configure_basic_system() pulls debuginfo for every loaded NM-related
        # library unless /tmp/nm_no_debug exists (~80 packages, ~250MB, seen
        # in practice) -- skip it for this fast local-check flow. Remove this
        # touch if you actually need debug symbols for a crash investigation.
        container_exec "touch /tmp/nm_no_debug"
        if netdevsim_stock_module_has_needed_features; then
            step "Stock netdevsim already has ring/channels/coalesce/perm-addr support -- skipping prepare/netdevsim.sh's from-source build"
            container_exec "touch /tmp/netdevsim_installed /tmp/netdevsim_container_stock_ok"
        else
            echo "WARNING: host kernel's stock netdevsim module doesn't have" >&2
            echo "         everything prepare/netdevsim.sh's patches add; it will" >&2
            echo "         fall back to building from source, which only works if" >&2
            echo "         the host kernel and this image's distro actually match" >&2
            echo "         (e.g. both RHEL) -- expect netdevsim-dependent tests to" >&2
            echo "         fail otherwise (e.g. a Fedora host with a CentOS Stream" >&2
            echo "         image)." >&2
        fi
        return
    fi
    echo "Waiting for systemd to settle..."
    container_exec "systemctl is-system-running --wait" || true
    echo "systemd state: $(container_exec 'systemctl is-system-running' || true)"
}

copr_project_for_source() {
    case "$NM_SOURCE" in
        skip) echo "" ;;
        main) echo "networkmanager/NetworkManager-main-debug" ;;
        copr:*) echo "${NM_SOURCE#copr:}" ;;
        # Shorthand for the networkmanager/NetworkManager-<X.YY>-debug COPR
        # naming pattern (e.g. -n 1.58), so you don't have to spell out
        # 'copr:networkmanager/NetworkManager-1.58-debug' every time.
        [0-9]*.[0-9]*) echo "networkmanager/NetworkManager-$NM_SOURCE-debug" ;;
        *)
            echo "Unknown nm-source: $NM_SOURCE" >&2
            usage
            exit 1
            ;;
    esac
}

install_nm() {
    local project
    project="$(copr_project_for_source)"
    if [ -z "$project" ]; then
        step "Skipping NetworkManager (re)install, using whatever ships in the image"
        return
    fi
    local repo_filter="${project##*/}"
    local current_repo
    current_repo="$(container_exec "dnf repoquery --installed --qf '%{from_repo}' NetworkManager 2>/dev/null" || true)"
    if [ "$FORCE_REINSTALL" != 1 ] && [[ "$current_repo" == *"$repo_filter"* ]]; then
        step "NetworkManager already installed from '$repo_filter', skipping (use --force to refresh)"
        return
    fi
    step "Installing NetworkManager from COPR $project"
    # dnf-plugins-core also provides the config-manager/copr subcommands used
    # below, so this one install covers both, bundled with epel-release into
    # a single transaction instead of separate metadata-resolve round trips.
    local base_pkgs="dnf-plugins-core"
    if container_exec "[ -f /etc/yum.repos.d/epel.repo ]" &>/dev/null; then
        container_exec "dnf -y install $base_pkgs"
    else
        # \$(rpm -E %rhel) is evaluated inside the container, not here, so
        # this picks the right EPEL release (9, 10, ...) for whatever image
        # is in use (NMCI_CONTAINER_IMAGE), not just c10s.
        container_exec "dnf -y install $base_pkgs https://dl.fedoraproject.org/pub/epel/epel-release-latest-\$(rpm -E %rhel).noarch.rpm"
    fi
    container_exec "dnf config-manager --set-enabled crb" || true
    container_exec "dnf -y copr enable $project"
    # Prefer the COPR build over any same-named package baseos/appstream
    # might also ship (stock NetworkManager*), without restricting the
    # transaction to *only* the COPR repo -- that used to also hide
    # non-NM dependencies (wireless-regdb, ModemManager, ppp, newt/slang)
    # that plugins like NetworkManager-wifi/-wwan/-ppp/-tui need, causing
    # dnf to silently skip all four every single run via --skip-broken.
    local copr_repoid="copr:copr.fedorainfracloud.org:${project/\//:}"
    container_exec "dnf config-manager --save --setopt='$copr_repoid.priority=1'" || true
    # --exclude 'kernel*': a container never boots its own kernel, so
    # letting dnf's dependency resolution drag in a kernel-core/
    # kernel-modules-core upgrade (seen happening via unrelated deps from
    # the newly enabled crb/epel repos) is pure wasted time.
    # --disablerepo=epel,appstream: wireless-regdb/ModemManager/ppp/newt/
    # slang (the deps the --repo restriction used to hide) all live in
    # baseos/crb -- but leaving epel/appstream enabled here makes the
    # 'NetworkManager*' glob also pull their openconnect/openvpn/pptp/
    # libreswan -gnome plugin builds, which prepare/envsetup installs
    # separately (different source/version) a few steps later, or not at
    # all. Not needed this early.
    container_exec "dnf -y install 'NetworkManager*' --disablerepo=epel,appstream \
        --exclude '*-connectivity-*' --exclude '*-devel*' \
        --exclude '*-debuginfo*' --exclude '*-debugsource*' \
        --exclude '*-gnome*' --exclude 'NetworkManager-bluetooth*' \
        --exclude 'kernel*' \
        --skip-broken"
    container_exec "systemctl restart NetworkManager"
    container_exec "rpm -q NetworkManager"
}

clone_nmci() {
    if container_exec "[ -d $CONTAINER_REPO/.git ]" &>/dev/null; then
        step "Updating existing NetworkManager-ci checkout ($NMCI_BRANCH)"
        container_exec "cd $CONTAINER_REPO && git fetch --depth 1 origin $NMCI_BRANCH && git checkout -B $NMCI_BRANCH FETCH_HEAD"
        return
    fi
    step "Cloning NetworkManager-ci ($NMCI_BRANCH)"
    container_exec "rm -rf $CONTAINER_REPO && git clone --branch $NMCI_BRANCH --depth 1 $NMCI_URL $CONTAINER_REPO"
}

run_one_test() {
    local tag="$1"
    local trc=0
    step "Running test '$tag' (test_run.sh sets up its own deps)"
    container_exec "cd $CONTAINER_REPO && ./test_run.sh $tag" || trc=$?
    echo "  -> '$tag': $([ "$trc" -eq 0 ] && echo PASS || echo "FAIL (rc=$trc)")"

    local report
    report="$(container_exec "ls -t $CONTAINER_REPO/../report_*.html /tmp/report_*.html 2>/dev/null | head -1" || true)"
    if [ -n "$report" ]; then
        podman cp "$CONTAINER_NAME:$report" "$REPORT_DIR/" 2>/dev/null || true
    fi
    return $trc
}

run_gate_tests() {
    step "Running feature 'gate' (every mapper.yaml test tagged 'gate', via run/runtests.sh)"
    # 'gate' is a per-test tag in mapper.yaml (used for TMT's plan/gate.fmf),
    # not a testmapper name -- run/runfeature.sh has no notion of it. Pull
    # the tagged test names ourselves and feed them to run/runtests.sh.
    local names
    names="$(container_exec "cd $CONTAINER_REPO && python3 -m nmci mapper_feature all all json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\" \".join(t[\"testname\"] for t in d if \"gate\" in t.get(\"tags\",\"\").split()))'")"
    if [ -z "$names" ]; then
        echo "  -> no tests tagged 'gate' found" >&2
        return 1
    fi
    echo "  -> $(echo "$names" | wc -w) gating tests"

    local frc=0
    container_exec "cd $CONTAINER_REPO && run/runtests.sh $names" || frc=$?
    echo "  -> feature 'gate': $([ "$frc" -eq 0 ] && echo PASS || echo "FAIL (rc=$frc)")"

    if container_exec "[ -d /tmp/results ]" &>/dev/null; then
        podman cp "$CONTAINER_NAME:/tmp/results/." "$REPORT_DIR/" 2>/dev/null || true
    fi
    return $frc
}

run_all_tests() {
    step "Running feature 'all' (every mapper.yaml test in the default testmapper, via run/runtests.sh)"
    # testmapper=default, not 'all' -- 'all' would also pull the hardware-only
    # subcomponent sections (NetworkManager-wifi, NetworkManager-wwan,
    # NetworkManager-infiniband, ...), which aren't meant to run on every
    # regular CI/local invocation, only via dedicated hardware jobs.
    local names
    names="$(container_exec "cd $CONTAINER_REPO && python3 -m nmci mapper_feature all default json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\" \".join(t[\"testname\"] for t in d))'")"
    if [ -z "$names" ]; then
        echo "  -> no tests found" >&2
        return 1
    fi
    echo "  -> $(echo "$names" | wc -w) tests -- expect dracut to skip (feature-level @skip_in_centos, unrelated to the container)"

    local frc=0
    container_exec "cd $CONTAINER_REPO && run/runtests.sh $names" || frc=$?
    echo "  -> feature 'all': $([ "$frc" -eq 0 ] && echo PASS || echo "FAIL (rc=$frc)")"

    if container_exec "[ -d /tmp/results ]" &>/dev/null; then
        podman cp "$CONTAINER_NAME:/tmp/results/." "$REPORT_DIR/" 2>/dev/null || true
    fi
    return $frc
}

run_one_feature() {
    local feature="$1"
    if [ "$feature" == "gate" ]; then
        run_gate_tests
        return $?
    fi
    if [ "$feature" == "all" ]; then
        run_all_tests
        return $?
    fi

    step "Running feature '$feature' (run/runfeature.sh -> run/runtests.sh)"
    local frc=0
    container_exec "cd $CONTAINER_REPO && run/runfeature.sh $feature" || frc=$?
    echo "  -> feature '$feature': $([ "$frc" -eq 0 ] && echo PASS || echo "FAIL (rc=$frc)")"

    if container_exec "[ -d /tmp/results ]" &>/dev/null; then
        podman cp "$CONTAINER_NAME:/tmp/results/." "$REPORT_DIR/" 2>/dev/null || true
    fi
    return $frc
}

run_tests() {
    mkdir -p "$REPORT_DIR"
    local rc=0
    local failed=()
    local tag
    local feature
    # 'pass' always runs first as a sanity check that the box is minimally usable;
    # skip it if the caller already listed it explicitly to avoid running it twice.
    local tags="pass"
    for tag in $EXTRA_TAGS; do
        [ "$tag" == "pass" ] || tags="$tags $tag"
    done
    for tag in $tags; do
        run_one_test "$tag" || { rc=1; failed+=("$tag"); }
    done

    for feature in $FEATURES; do
        run_one_feature "$feature" || { rc=1; failed+=("feature:$feature"); }
    done

    [ ${#failed[@]} -gt 0 ] && echo "Failed: ${failed[*]}"
    return $rc
}

print_report_links() {
    [ -d "$REPORT_DIR" ] || return
    # This whole script runs under sudo (rootful podman), so reports land
    # root-owned -- hand them back to whoever actually invoked sudo so they
    # can read/delete them without needing sudo again.
    if [ -n "${SUDO_UID:-}" ]; then
        chown -R "$SUDO_UID:$SUDO_GID" "$REPORT_DIR" 2>/dev/null || true
    fi
    step "Reports: file://$(readlink -f "$REPORT_DIR")"
}

if [ "$CLEAN" -eq 1 ]; then
    do_clean
    exit 0
fi

if [ "$REBOOT" -eq 1 ]; then
    do_reboot
    exit 0
fi

ensure_container

if [ "$SHELL_ONLY" -eq 1 ]; then
    step "Dropping into a shell in $CONTAINER_NAME ($CONTAINER_REPO)"
    exec podman exec -it "$CONTAINER_NAME" bash -lc "cd $CONTAINER_REPO 2>/dev/null; exec bash"
fi

install_nm
clone_nmci
rc=0
run_tests || rc=$?

if [ $rc -eq 0 ] && [ -n "$SAVE_IMAGE" ]; then
    step "Saving container as image '$SAVE_IMAGE'"
    podman commit "$CONTAINER_NAME" "$SAVE_IMAGE"
    if [ "$PUSH_IMAGE" -eq 1 ]; then
        step "Pushing '$SAVE_IMAGE'"
        if ! podman push "$SAVE_IMAGE"; then
            echo "Push failed -- are you logged in? Try: podman login <registry>, then push manually:" >&2
            echo "  podman push $SAVE_IMAGE" >&2
        fi
    else
        echo "Run 'podman push $SAVE_IMAGE' yourself if you want it available remotely."
    fi
fi

print_report_links
step "RESULT: $([ $rc -eq 0 ] && echo PASS || echo "FAIL (rc=$rc)")"

if [ -t 0 ] && [ -t 1 ]; then
    read -r -p "Drop into a shell in $CONTAINER_NAME? [y/N] " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
        exec podman exec -it "$CONTAINER_NAME" bash -lc "cd $CONTAINER_REPO 2>/dev/null; exec bash"
    fi
fi

exit $rc
