#!/bin/bash

function is_installed {
    # check that everything works
    if ! which wg > /dev/null ; then
        echo "wireguard utility 'wg' not found"
        exit 1
    fi


    if ! modprobe wireguard; then
        echo "module wireguard not loaded"
        exit 1
    fi
}

function install_module_cert {
    if ! [ -f /lib/modules/$(uname -r)/build/certs/signing_key.pem ]; then
        echo "generating certificate for kernel module signing"
        openssl req -new -nodes -utf8 -sha512 -days 36500 -batch -x509 -config module_cert.req -outform DER -out signing_key.x509 -keyout signing_key.pem
        cp signing_key.pem signing_key.x509 /lib/modules/$(uname -r)/build/certs/
    fi
}

function make_from_src {

    ARCH="$(uname -p)"

    if [ $ARCH == "ppc64le" ] ;then 
        ARCH="powerpc"
    elif [ $ARCH == "s390x" ] ;then 
        ARCH="s390"
    elif [ $ARCH == "x86_64" ] ;then 
        ARCH="x86"
    elif [ $ARCH == "aarch64" ] ;then 
        ARCH="arm64"
    fi

    # compile module
    git clone https://git.zx2c4.com/wireguard-linux-compat
    pushd wireguard-linux-compat/src
        make ARCH=$ARCH && sudo make install ARCH=$ARCH
    popd

    #compile tools
    git clone https://git.zx2c4.com/wireguard-tools
    pushd wireguard-tools/src
        make && sudo make install
    popd

}

# test whether wireguard module and utility are already installed
if (is_installed) ; then
    echo "wireguard already configured"
    exit 0
fi

# install tools required for build
sudo yum -y install libmnl-devel elfutils-libelf-devel kernel-devel-$(uname -r) pkg-config gcc git

cd contrib/wireguard/

install_module_cert
gpg --import wireguard.asc

# compile from repo
make_from_src
if (is_installed) ; then
    exit 0
fi

# # if latest tag is not buildable, clean and try 20180613
# cd ..
# rm -rf WireGuard*
# echo "trying to build snapshot 20180613"
# make_from_src 0.0.20180613
# if (is_installed) ; then exit 0; fi

# if not exited normaly yet, error ocured
exit 1
