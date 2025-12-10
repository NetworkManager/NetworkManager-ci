#!/bin/bash

# cs_tests_runner.sh - Runner for bengal's cs- IPsec tests in NMCI environment
#
# This script sets up containers, updates NetworkManager to match host version,
# and runs the cs- prefixed tests from bengal/scripts repository.
#
# Usage:
#   $0 setup                    - Setup test environment
#   $0 test <cs-test-name>      - Run specific cs- test
#   $0 cleanup                  - Cleanup test environment
#   $0 list                     - List available cs- tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="/tmp/cs_ipsec_tests"
SCRIPTS_REPO="https://github.com/bengal/scripts.git"
SCRIPTS_DIR="$WORK_DIR/scripts"

# Container names
HOSTA_CONTAINER="hosta.example.org"
HOSTB_CONTAINER="hostb.example.org"

# Detect container image based on host distribution (systemd-enabled)
get_container_image() {
    # Use nmstate development containers for NetworkManager testing
    if [[ -f /etc/fedora-release ]]; then
        local fedora_version
        fedora_version=$(grep -o 'release [0-9]*' /etc/fedora-release | sed 's/release //')
        if [[ "$fedora_version" == "Rawhide" ]]; then
            echo "quay.io/nmstate/fed-nmstate-dev:rawhide"
        else
            echo "quay.io/nmstate/fed-nmstate-dev:latest"
        fi
    elif [[ -f /etc/redhat-release ]]; then
        # For RHEL/CentOS, use nmstate development containers
        local version
        version=$(grep -o 'release [0-9]*' /etc/redhat-release | sed 's/release //')
        if [[ "$version" == "9" ]]; then
            echo "quay.io/nmstate/c9s-nmstate-dev"
        elif [[ "$version" == "10" ]]; then
            echo "quay.io/nmstate/c10s-nmstate-dev"
        else
            echo "quay.io/nmstate/c9s-nmstate-dev"
        fi
    else
        # Default fallback
        echo "quay.io/nmstate/c10s-nmstate-dev"
    fi
}

log() {
    echo "[$(date '+%H:%M:%S')] $*" >&2
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Check if script is running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Setup working directory
setup_work_dir() {
    log "Setting up working directory: $WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
}

# Clone bengal's scripts repository
clone_scripts_repo() {
    log "Cloning bengal/scripts repository"
    if [[ -d "$SCRIPTS_DIR" ]]; then
        log "Scripts directory already exists, pulling latest changes"
        cd "$SCRIPTS_DIR"
        git pull
    else
        git clone "$SCRIPTS_REPO" "$SCRIPTS_DIR"
    fi
}

# Get current NetworkManager version from host
get_nm_version() {
    local nm_version
    nm_version=$(NetworkManager --version)
    log "Host NetworkManager version: $nm_version"
    echo "$nm_version"
}

# Get NM package URLs/paths with priority: local builds -> koji -> copr
get_nm_package_urls() {
    local nm_version="$1"
    log "Getting NetworkManager package URLs for version $nm_version"

    # Priority 1: Check for local builds first (MR builds)
    for nm_build_path in "/"{root,tmp}"/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"{noarch,$(arch)}"/" "/root/rpms/"; do
        if [[ -d "$nm_build_path" ]]; then
            local rpms=($(find "$nm_build_path" -name "NetworkManager-*.rpm" ! -name "*debuginfo*" ! -name "*devel*" 2>/dev/null))
            if [[ ${#rpms[@]} -gt 0 ]]; then
                log "Found local NetworkManager RPMs in $nm_build_path"
                printf '%s\n' "${rpms[@]}"
                return 0
            fi
        fi
    done

    # Priority 2: Try koji_links.sh for CentOS Stream packages
    local koji_urls
    koji_urls=$("$SCRIPT_DIR/../utils/koji_links.sh" NetworkManager "$nm_version" 2>/dev/null | grep -v debuginfo | grep -v devel)
    if [[ -n "$koji_urls" ]]; then
        log "Found NetworkManager packages via koji_links"
        echo "$koji_urls"
        return 0
    fi

    # Priority 3: Try copr repository
    local copr_repo
    if [[ "$nm_version" == *"main"* ]] || [[ "$nm_version" > "1.56" ]]; then
        copr_repo="NetworkManager-main-debug"
    else
        # Extract major.minor from version (e.g., 1.55.90 -> 1.56, 1.54.2 -> 1.54)
        local major_minor
        if [[ "$nm_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            local major="${BASH_REMATCH[1]}"
            local minor="${BASH_REMATCH[2]}"
            local patch="${BASH_REMATCH[3]}"

            # Development versions (x.y.90+) map to next minor version
            if [[ "$patch" -ge 90 ]]; then
                ((minor++))
            fi
            major_minor="$major.$minor"
        else
            major_minor="main"
        fi
        copr_repo="NetworkManager-$major_minor-debug"
    fi

    log "Trying copr repository: $copr_repo"
    local copr_url="https://copr.fedorainfracloud.org/coprs/networkmanager/$copr_repo"
    # This would need specific implementation to get RPM URLs from copr
    log "Copr repository support not fully implemented yet: $copr_url"

    log "No NetworkManager packages found, using distribution defaults"
    return 1
}

# Create containers for testing
setup_containers() {
    log "Setting up test containers"

    # Check if containers already exist
    if podman container exists "$HOSTA_CONTAINER" 2>/dev/null; then
        log "Container $HOSTA_CONTAINER already exists, removing it"
        podman rm -f "$HOSTA_CONTAINER"
    fi

    if podman container exists "$HOSTB_CONTAINER" 2>/dev/null; then
        log "Container $HOSTB_CONTAINER already exists, removing it"
        podman rm -f "$HOSTB_CONTAINER"
    fi

    # Create custom network for the containers
    if ! podman network exists cs-ipsec-test 2>/dev/null; then
        log "Creating custom network for cs-tests"
        podman network create cs-ipsec-test --subnet 172.16.0.0/16
    fi

    # Get appropriate container image
    local container_image
    container_image=$(get_container_image)

    # Start containers with systemd (nmstate test-env containers have systemd configured)
    log "Starting host A container"
    podman run -d --name "$HOSTA_CONTAINER" \
        --hostname "$HOSTA_CONTAINER" \
        --network cs-ipsec-test \
        --ip 172.16.1.10 \
        --cap-add=NET_ADMIN \
        --privileged \
        --tmpfs /run \
        --tmpfs /tmp \
        "$container_image"

    log "Starting host B container"
    podman run -d --name "$HOSTB_CONTAINER" \
        --hostname "$HOSTB_CONTAINER" \
        --network cs-ipsec-test \
        --ip 172.16.2.20 \
        --cap-add=NET_ADMIN \
        --privileged \
        --tmpfs /run \
        --tmpfs /tmp \
        "$container_image"

    # Wait for containers to start and systemd to initialize
    sleep 5
    
    # Basic setup in both containers (nmstate test-env containers already have required packages)
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        log "Starting NetworkManager in $container"
        podman exec "$container" systemctl enable NetworkManager
        podman exec "$container" systemctl start NetworkManager
        
        # Install additional packages if needed
        podman exec "$container" dnf install -y wget || true
    done
}

# Update NetworkManager in containers to match host version
update_nm_in_containers() {
    local nm_version
    nm_version=$(get_nm_version)

    log "Updating NetworkManager in containers to version $nm_version"

    # Get package URLs
    local package_urls
    package_urls=$(get_nm_package_urls "$nm_version")

    if [[ -z "$package_urls" ]]; then
        log "Warning: Could not get package URLs for NetworkManager $nm_version, using default packages"
        return 0
    fi

    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        log "Updating NetworkManager in $container"

        # Prepare all packages for installation
        local temp_files=()

        for package in $package_urls; do
            if [[ "$package" =~ ^https?:// ]]; then
                # Remote URL - download to temp
                local rpm_name
                rpm_name=$(basename "$package")
                log "Downloading $rpm_name"
                podman exec "$container" wget -O "/tmp/$rpm_name" "$package"
                temp_files+=("/tmp/$rpm_name")
            elif [[ -f "$package" ]]; then
                # Local file - copy to container
                local rpm_name
                rpm_name=$(basename "$package")
                log "Copying $rpm_name to container"
                podman cp "$package" "$container:/tmp/$rpm_name"
                temp_files+=("/tmp/$rpm_name")
            else
                log "Warning: Package not found: $package"
            fi
        done

        # Install all packages at once (handles upgrade/downgrade/dependencies)
        if [[ ${#temp_files[@]} -gt 0 ]]; then
            log "Installing all NetworkManager packages together in $container"
            podman exec "$container" dnf install -y --allowerasing "${temp_files[@]}"
        fi

        # Restart NetworkManager
        podman exec "$container" systemctl restart NetworkManager

        # Verify version
        local container_version
        container_version=$(podman exec "$container" NetworkManager --version)
        log "NetworkManager version in $container: $container_version"
    done
}

# Copy scripts repository to containers
copy_scripts_to_containers() {
    log "Copying scripts to containers"

    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        log "Copying scripts to $container"
        podman cp "$SCRIPTS_DIR/ipsec" "$container:/root/"
    done
}

# List available cs- tests
list_cs_tests() {
    if [[ ! -d "$SCRIPTS_DIR/ipsec/tests" ]]; then
        error "Scripts not found. Please run '$0 setup' first."
    fi

    log "Available cs- tests:"
    cd "$SCRIPTS_DIR/ipsec/tests"
    find . -name "cs-*" -type d | sed 's|./||' | sort
}

# Run a specific cs- test
run_cs_test() {
    local test_name="$1"

    if [[ -z "$test_name" ]]; then
        error "Test name is required"
    fi

    if [[ ! "$test_name" =~ ^cs- ]]; then
        error "Only cs- prefixed tests are supported"
    fi

    if [[ ! -d "$SCRIPTS_DIR/ipsec/tests/$test_name" ]]; then
        error "Test '$test_name' not found"
    fi

    log "Running test: $test_name"

    # Setup phase
    log "Setting up test environment for $test_name"
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        podman exec "$container" bash -c "cd /root/ipsec/tests/$test_name && ./do.sh clean"
    done

    # Deploy configurations
    log "Deploying configurations for $test_name"
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        # Copy connection files
        for nmfile in "$SCRIPTS_DIR/ipsec/tests/$test_name"/*.nmconnection; do
            if [[ -f "$nmfile" ]]; then
                local basename_file
                basename_file=$(basename "$nmfile")
                log "Copying $basename_file to $container"
                podman cp "$nmfile" "$container:/etc/NetworkManager/system-connections/"
                podman exec "$container" chmod 600 "/etc/NetworkManager/system-connections/$basename_file"
            fi
        done

        # Copy .conf files if they exist
        for conffile in "$SCRIPTS_DIR/ipsec/tests/$test_name"/*.conf; do
            if [[ -f "$conffile" ]]; then
                local basename_file
                basename_file=$(basename "$conffile")
                log "Copying $basename_file to $container"
                podman cp "$conffile" "$container:/etc/ipsec.d/"
            fi
        done

        # Reload connections
        podman exec "$container" nmcli connection reload
    done

    # Post-setup phase (create dummy interfaces, etc.)
    log "Running post-setup for $test_name"
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        podman exec "$container" bash -c "cd /root/ipsec/tests/$test_name && ./do.sh post"
    done

    # Bring up connections
    log "Bringing up IPsec connections"
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        # Find connection name from .nmconnection files
        for nmfile in "$SCRIPTS_DIR/ipsec/tests/$test_name"/*.nmconnection; do
            if [[ -f "$nmfile" ]]; then
                local conn_id
                conn_id=$(grep "^id=" "$nmfile" | cut -d= -f2)
                if [[ -n "$conn_id" ]]; then
                    log "Bringing up connection '$conn_id' in $container"
                    podman exec "$container" nmcli connection up "$conn_id" || log "Warning: Failed to bring up $conn_id in $container"
                fi
            fi
        done
    done

    # Wait a bit for connections to establish
    sleep 5

    # Check phase
    log "Running connectivity checks for $test_name"
    local test_passed=true
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        log "Running checks in $container"
        if ! podman exec "$container" bash -c "cd /root/ipsec/tests/$test_name && ./do.sh check"; then
            log "ERROR: Checks failed in $container"
            test_passed=false
        fi
    done

    if $test_passed; then
        log "SUCCESS: Test $test_name passed"
        return 0
    else
        log "FAILURE: Test $test_name failed"
        return 1
    fi
}

# Cleanup test environment
cleanup_test_env() {
    log "Cleaning up test environment"

    # Stop and remove containers
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        if podman container exists "$container" 2>/dev/null; then
            log "Removing container $container"
            podman rm -f "$container"
        fi
    done

    # Remove custom network
    if podman network exists cs-ipsec-test 2>/dev/null; then
        log "Removing custom network"
        podman network rm cs-ipsec-test
    fi

    # Remove work directory
    if [[ -d "$WORK_DIR" ]]; then
        log "Removing work directory"
        rm -rf "$WORK_DIR"
    fi
}

# Main function
main() {
    local command="${1:-}"

    case "$command" in
        "setup")
            log "Setting up cs-tests environment"
            check_root
            setup_work_dir
            clone_scripts_repo
            setup_containers
            copy_scripts_to_containers
            log "Setup complete (NetworkManager update needed separately)"
            ;;
        "update-nm")
            log "Updating NetworkManager in containers"
            check_root
            update_nm_in_containers
            log "NetworkManager update complete"
            ;;
        "test")
            local test_name="${2:-}"
            check_root
            run_cs_test "$test_name"
            ;;
        "list")
            list_cs_tests
            ;;
        "cleanup")
            check_root
            cleanup_test_env
            log "Cleanup complete"
            ;;
        *)
            cat << EOF
Usage: $0 <command> [options]

Commands:
    setup                   Setup test environment (containers and scripts)
    update-nm               Update NetworkManager in containers to match host version
    test <cs-test-name>     Run specific cs- test
    list                    List available cs- tests
    cleanup                 Cleanup test environment

Examples:
    $0 setup
    $0 update-nm
    $0 list
    $0 test cs-host4
    $0 test cs-subnet4
    $0 cleanup
EOF
            exit 1
            ;;
    esac
}

main "$@"