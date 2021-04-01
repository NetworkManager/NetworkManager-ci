#!/usr/bin/python

import json, urllib, subprocess, sys, os

settings = {}

def read_env_options():
    print('>> Reading env options')
    # Setting defaults
    settings['code_branch'] = "master"
    settings['test_branch'] = "master"
    settings['features'] = "all"

    if 'CODE_BRANCH' in os.environ:
        settings['code_branch'] = os.environ['CODE_BRANCH']
    if 'TEST_BRANCH' in os.environ:
        settings['test_branch'] = os.environ['TEST_BRANCH']
    if 'FEATURES' in os.environ:
        settings['features'] = os.environ['FEATURES']



def run_tests(features, code_branch, test_branch):
    url_base="http://admin.ci.centos.org:8080"
    # This file was generated on your slave.  See https://wiki.centos.org/QaWiki/CI/GettingStarted
    api=open('/home/networkmanager/duffy.key').read().strip()
    ver="8-stream"
    arch="x86_64"
    count=1
    try:
        get_nodes_url="%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (url_base,api,ver,arch,count)
        dat=urllib.urlopen(get_nodes_url).read()
        b=json.loads(dat)
    except:
        ver="8"
        get_nodes_url="%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (url_base,api,ver,arch,count)
        dat=urllib.urlopen(get_nodes_url).read()
        b=json.loads(dat)

    features = "all"

    for h in b['hosts']:
        h += str(".ci.centos.org")
        # Do the work
        subprocess.call("echo '*running tests' >> log.txt", shell=True)
        cmd0="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'yum install -y git python3 \
                                                   && git clone https://github.com/NetworkManager/NetworkManager-ci \
                                                   && cd NetworkManager-ci \
                                                   && git checkout %s \
                                                   && python run/centos-ci/node_runner.py %s %s %s \
                                                   "% (h, test_branch, test_branch, code_branch, features)

        rtn_code=subprocess.call(cmd0, shell=True)
        subprocess.call("echo 'download stuff' >> log.txt", shell=True)
        subprocess.call("mkdir results", shell=True)
        subprocess.call("scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s:/tmp/results/Test_results-* ./results" % (h), shell=True)
        subprocess.call("cd results && tar -xzf Test_results* && rm -rf Test_results* && cd ..", shell=True)
        subprocess.call("echo '* ALL DONE' >> log.txt", shell=True)

    done_nodes_url="%s/Node/done?key=%s&ssid=%s" % (url_base, api, b['ssid'])
    das=urllib.urlopen(done_nodes_url).read()

if __name__ == "__main__":
    read_env_options()
    sys.exit(run_tests(settings['features'], settings['code_branch'], settings['test_branch']))
