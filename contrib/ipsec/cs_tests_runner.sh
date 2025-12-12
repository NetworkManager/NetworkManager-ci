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

# Setup logging
LOG_FILE="${LOG_FILE:-/tmp/cs_ipsec_tests.log}"
exec > >(tee "$LOG_FILE") 2>&1
echo "=== CS-Tests IPsec Runner Log ==="
echo "Log file: $LOG_FILE"

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
    echo "$*"
}

# Enhanced logging function that logs command execution
run_cmd() {
    local cmd="$*"
    log "COMMAND: $cmd"
    if "$@"; then
        log "SUCCESS: $cmd"
        return 0
    else
        local ret=$?
        log "FAILED: $cmd (exit code: $ret)"
        return $ret
    fi
}

error() {
    echo "ERROR: $*" >&2
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

# Clone bengal's scripts repository on host
clone_scripts_repo() {
    log "Cloning bengal/scripts repository on host"
    if [[ -d "$SCRIPTS_DIR" ]]; then
        log "Scripts directory already exists, pulling latest changes"
        cd "$SCRIPTS_DIR"
        git pull 2>/dev/null || {
            log "Warning: git pull failed, using existing scripts"
        }
    else
        git clone "$SCRIPTS_REPO" "$SCRIPTS_DIR" 2>/dev/null || {
            log "ERROR: Failed to clone scripts repository"
            return 1
        }
    fi
    log "Scripts repository ready on host"
}

# Get current NetworkManager version from host
get_nm_version() {
    local nm_version
    nm_version=$(NetworkManager --version)
    log "Host NetworkManager version: $nm_version" >&2
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
        log "Container $container is ready and setup complete"
    done
}

# Update NetworkManager in containers to match host version
update_nm_in_containers() {
    local nm_version
    nm_version=$(get_nm_version)

    log "Updating NetworkManager in containers to version $nm_version"

    # Create download directory
    local download_dir="/tmp/nm-builds-cs"
    mkdir -p "$download_dir"
    log "Downloading packages to $download_dir"

    # Download minimal NetworkManager packages using koji_links
    log "Getting minimal NetworkManager packages for version $nm_version"
    
    # Parse version-release (e.g., "1.55.90-1.el10" -> "1.55.90" "1.el10")
    local version release
    if [[ "$nm_version" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-(.+)$ ]]; then
        version="${BASH_REMATCH[1]}"
        release="${BASH_REMATCH[2]}"
        log "Parsed version: $version, release: $release"
    else
        version="$nm_version"
        release=""
        log "Using version as-is: $version"
    fi
    
    local nm_urls
    nm_urls=$("$SCRIPT_DIR/../utils/koji_links.sh" NetworkManager "$version" ${release:+"$release"} | 
        grep -E "(NetworkManager-libnm-|NetworkManager-[0-9]|NetworkManager-ovs-)" | 
        grep -v debug | grep -v devel)
    log "NetworkManager URLs found: $(echo "$nm_urls" | wc -l) packages"
    
    # Download NetworkManager-libreswan packages using koji_links
    log "Getting NetworkManager-libreswan packages"
    local libreswan_urls
    libreswan_urls=$("$SCRIPT_DIR/../utils/koji_links.sh" NetworkManager-libreswan ${release:+"$release"} | 
        grep -v debug | grep -v devel | grep -v gnome)
    log "NetworkManager-libreswan URLs found: $(echo "$libreswan_urls" | wc -l) packages"

    # Download all packages to local directory first
    local local_packages=()
    
    # Download NetworkManager packages
    for package in $nm_urls; do
        if [[ "$package" =~ ^https?:// ]]; then
            local rpm_name
            rpm_name=$(basename "$package")
            local local_path="$download_dir/$rpm_name"
            log "Downloading NetworkManager: $rpm_name"
            wget -q -O "$local_path" "$package" || {
                log "WARNING: Failed to download $package"
                continue
            }
            log "Downloaded: $rpm_name"
            local_packages+=("$local_path")
        fi
    done
    
    # Download NetworkManager-libreswan packages
    for package in $libreswan_urls; do
        if [[ "$package" =~ ^https?:// ]]; then
            local rpm_name
            rpm_name=$(basename "$package")
            local local_path="$download_dir/$rpm_name"
            log "Downloading NetworkManager-libreswan: $rpm_name"
            wget -q -O "$local_path" "$package" || {
                log "WARNING: Failed to download $package"
                continue
            }
            log "Downloaded: $rpm_name"
            local_packages+=("$local_path")
        fi
    done

    if [[ ${#local_packages[@]} -eq 0 ]]; then
        log "WARNING: No packages downloaded successfully"
        log "NetworkManager URLs were: $nm_urls"
        log "NetworkManager-libreswan URLs were: $libreswan_urls"
        return 1
    fi
    
    log "Successfully downloaded ${#local_packages[@]} packages to $download_dir"

    # Now copy packages to containers and install
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        log "Updating NetworkManager and NetworkManager-libreswan in $container"

        # Copy all packages to container
        local container_files=()
        for local_pkg in "${local_packages[@]}"; do
            local rpm_name
            rpm_name=$(basename "$local_pkg")
            log "Copying $rpm_name to $container"
            podman cp "$local_pkg" "$container:/tmp/$rpm_name"
            container_files+=("/tmp/$rpm_name")
        done

        # Install all packages at once (handles upgrade/downgrade/dependencies)
        if [[ ${#container_files[@]} -gt 0 ]]; then
            log "Installing ${#container_files[@]} NetworkManager packages in $container"
            log "Packages: $(basename -a "${container_files[@]}" | tr '\n' ' ')"
            podman exec "$container" rpm -U --force "${container_files[@]}" || {
                log "ERROR: Failed to install packages in $container"
                continue
            }
            log "Successfully installed packages in $container"
        fi

        # Enable and start NetworkManager after package installation
        log "Starting NetworkManager in $container after package installation"
        podman exec "$container" systemctl enable NetworkManager
        podman exec "$container" systemctl start NetworkManager

        # Verify versions
        local container_version
        container_version=$(podman exec "$container" NetworkManager --version 2>/dev/null) || {
            log "ERROR: Cannot get NetworkManager version in $container"
            continue
        }
        log "NetworkManager version in $container: $container_version"
        
        local libreswan_version
        libreswan_version=$(podman exec "$container" rpm -q NetworkManager-libreswan 2>/dev/null) || {
            log "WARNING: NetworkManager-libreswan not installed in $container"
        }
        log "NetworkManager-libreswan in $container: $libreswan_version"
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

    # Force kill and remove containers
    for container in "$HOSTA_CONTAINER" "$HOSTB_CONTAINER"; do
        if podman container exists "$container" 2>/dev/null; then
            log "Killing and removing container $container"
            podman kill "$container" 2>/dev/null || true
            podman rm -f "$container" 2>/dev/null || true
        fi
    done

    # Remove custom network
    if podman network exists cs-ipsec-test 2>/dev/null; then
        log "Removing custom network"
        podman network rm cs-ipsec-test 2>/dev/null || true
    fi

    # Remove work directory
    if [[ -d "$WORK_DIR" ]]; then
        log "Removing work directory"
        rm -rf "$WORK_DIR"
    fi
    
    # Remove download directory
    if [[ -d "/tmp/nm-builds-cs" ]]; then
        log "Removing download directory /tmp/nm-builds-cs"
        rm -rf "/tmp/nm-builds-cs"
    fi
}

# Main function
main() {
    local command="${1:-}"

    case "$command" in
        "setup")
            log "Setting up cs-tests environment"
            check_root
            # Clean up any existing containers/networks first
            cleanup_test_env 2>/dev/null || true
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