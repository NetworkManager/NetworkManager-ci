#!/bin/bash

function setup () {
    # override DNS static.redhat.com to localhost
    echo "0.0.0.0 static.redhat.com" >> /etc/hosts
    # prepare directory for http server
    mkdir -p /tmp/python_http/test/
    cd /tmp/python_http
    echo -n "OK" > test/rhel-networkmanager.txt
    # run python http server (sharing working directory "/tmp/python_http/")
    if which python3 &> /dev/null; then
        #python3
        python3 -m http.server 8001 &
        echo $! > /tmp/python_http.pid
    else
        #python2
        python2 -m SimpleHTTPServer 8001 &
        echo $! > /tmp/python_http.pid
    fi
}


function teardown () {
    # remove dns override
    sed '/^0\.0\.0\.0 static\.redhat\.com/d' -i /etc/hosts
    # stop http server and clean up
    kill $(cat /tmp/python_http.pid)
    rm -rf /tmp/python_http/
}


if [ "x$1" != "xteardown" ]; then
    setup
else
    teardown
fi
