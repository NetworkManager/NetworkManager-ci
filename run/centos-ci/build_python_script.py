#
# This script uses the Duffy node management api to get fresh machines to run
# your CI tests on. Once allocated you will be able to ssh into that machine
# as the root user and setup the environ
#
# XXX: You need to add your own api key below, and also set the right cmd= line
#      needed to run the tests
#
# Please note, this is a basic script, there is no error handling and there are
# no real tests for any exceptions. Patches welcome!

import json, urllib, subprocess, sys

url_base="http://admin.ci.centos.org:8080"

# This file was generated on your slave.  See https://wiki.centos.org/QaWiki/CI/GettingStarted
api=open('/home/networkmanager/duffy.key').read().strip()

ver="7"
arch="x86_64"
count=1

get_nodes_url="%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (url_base,api,ver,arch,count)

dat=urllib.urlopen(get_nodes_url).read()
b=json.loads(dat)
for h in b['hosts']:
    cmd="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'run/fedora-vagrant/scripts/./setup.sh'" % (h)
    print cmd
    rtn_code=subprocess.call(cmd, shell=True)
    cmd2="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'run/fedora-vagrant/scripts/./build.sh nm-1-6'" % (h)
    print cmd2
    rtn_code=subprocess.call(cmd2, shell=True)
    cmd3="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'run/fedora-vagrant/scripts/./get_tests.sh master'" % (h)
    print cmd3
    rtn_code=subprocess.call(cmd3, shell=True)
    cmd4="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'run/fedora-vagrant/scripts/./runtest.sh ipv6_never-default_remove'" % (h)
    print cmd4
    rtn_code=subprocess.call(cmd4, shell=True)


done_nodes_url="%s/Node/done?key=%s&ssid=%s" % (url_base, api, b['ssid'])
das=urllib.urlopen(done_nodes_url).read()

sys.exit(rtn_code)
