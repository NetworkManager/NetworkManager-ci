#!/bin/bash

set -x

###############################################################################
# Script to run OCP origin (conformance) tests using a NetworkManager rpm from
# a copr repository.
#
# In order to do this, we need to use several scripts like
# cluster-deployment-automation, nm-to-rhcos and openshift-tests tool. This
# process takes a lot of time and requires a beefy machine, otherwise it won't
# work. The script was tested in a machine with this hardware:
# - 64 Cores
# - 196 GB RAM
# - 450 GB HDD
#
# Requirements:
# - Generate a quay.io user and an encrypted password.
# - Download pull-secret file and place it in the NetworkManager-ci repo named
#   pull_secret.json
# - You must have a repository in a quay.io registry
#
###############################################################################

# Prints usage help
script_usage() {
    cat << EOF
Usage:
     -h|--help              Display this help.
     --nm-copr              Specify the NM stable release to take from Copr
                            to the RHCOS image. Default value is main branch.
     --registry             Specify registry to be used to push the image.
     --tag                  Specify the tag to be used when pushing the image to the registry.
                            Default value is: latest
     --tests                Indicate which test should it run, if none specified it will run all.
     --podman-user          Specify a quay.io user to log in.
     --podman-password      Specify a quay.io encrypted password to log in.
EOF
}

# Parse the parameters
parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h | --help)
                script_usage
                exit 0
                ;;
            --nm-copr)
                nm_copr="$2"
                shift
                shift
                ;;
            --registry)
                registry="$2"
                shift
                shift
                ;;
            --tag)
                tag="$2"
                shift
                shift
                ;;
            --tests)
                tests="$2"
                shift
                shift
                ;;
            --podman-user)
                podman_user="$2"
                shift
                shift
                ;;
            --podman-password)
                podman_password="$2"
                shift
                shift
                ;;
            *)
                echo "Invalid parameter provided \"$1\""
                exit 1
        esac
    done
}

install_needed_tools() {
    dnf install -y git
}

# Clone needed repositories
clone_repos() {
    git clone https://gitlab.freedesktop.org/NetworkManager/NetworkManager.git
    git clone https://github.com/bn222/cluster-deployment-automation.git
    git clone https://github.com/openshift/origin.git
}

setup_cluster() {
    cp pull_secret.json cluster-deployment-automation/
    cd cluster-deployment-automation/
    dnf install -y python3.11
    python3.11 -m venv ocp-venv
    source ocp-venv/bin/activate
    ./dependencies.sh
    usermod -a -G root qemu

    # Ensure having a suitable SSH key
    [ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519

    cat > cluster.yaml << EOF
clusters:
  - name : "vm"
    api_vip: "192.168.122.99"
    ingress_vip: "192.168.122.101"
    kubeconfig: "/root/kubeconfig.vm"
    masters:
    - name: "vm-master-1"
      kind: "vm"
      node: "localhost"
      ip: "192.168.122.141"
    - name: "vm-master-2"
      kind: "vm"
      node: "localhost"
      ip: "192.168.122.142"
    - name: "vm-master-3"
      kind: "vm"
      node: "localhost"
      ip: "192.168.122.143"
    workers:
    - name: "vm-worker-1"
      kind: "vm"
      node: "localhost"
      ip: "192.168.122.144"
    - name: "vm-worker-2"
      kind: "vm"
      node: "localhost"
      ip: "192.168.122.145"
EOF

    python cda.py cluster.yaml deploy
    if [ $? -ne 0 ]; then
	# Sometimes, the script fails on the first attemp, try again.
        python cda.py cluster.yaml deploy

	if [ $? -ne 0 ]; then
            echo "Failed to set up the cluster :("
	    exit 1
	fi
    fi

    export KUBECONFIG=/root/kubeconfig.vm

    cd ../
}

build_and_install_mco() {
    podman login -u $podman_user -p $podman_password quay.io

    if [ $? -ne 0 ]; then
        echo "Failed to log in in quay.io :("
	exit 1
    fi

    cp pull_secret.json NetworkManager/pull-secret
    base=$(oc adm release info --image-for rhel-coreos 2>&1 | grep -o -E 'quay\.io\/openshift-release-dev\/ocp-release-nightly@sha256:[a-f0-9]{64}')
    cd NetworkManager/
    ./tools/nm-to-rhcos --nm-copr $nm_copr --base $base --registry $registry --tag $tag

    cat > mco-control.yml << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: os-layer-custom-nm-control
spec:
  osImageURL: $registry:$tag
EOF

    cat > mco-worker.yml << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: os-layer-custom-nm-worker
spec:
  osImageURL: $registry:$tag
EOF

    oc create -f mco-control.yml
    oc create -f mco-worker.yml

    echo "Waiting mcp for control-plane role"
    i=0
    while [ $i -lt 1000 ]
    do
        ((i++))
        oc get mcp master | grep -o -E '\bTrue\b\s*False\b\s*False\b'
	if [ $? -eq 0 ]; then
            break
        fi
	sleep 5
    done

    echo "Checking mcp for worker role"
    i=0
    while [ $i -lt 1000 ]
    do
        ((i++))
        oc get mcp worker | grep -o -E '\bTrue\b\s*False\b\s*False\b'
	if [ $? -eq 0 ]; then
            break
        fi
	sleep 5
    done

    cd ../
}

run_tests() {
    cd origin/
    make WHAT=cmd/openshift-tests

    if [ "$test" == "all" ]; then
        ./openshift-tests run all
	exit $?
    fi

    ./openshift-tests run-test $test
    exit $?
}

main() {
    tag="latest"
    tests="all"
    podman_user=""
    podman_password=""

    parse_params "$@"
    install_needed_tools
    clone_repos
    setup_cluster
    build_and_install_mco
    run_tests
}

main "$@"

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
