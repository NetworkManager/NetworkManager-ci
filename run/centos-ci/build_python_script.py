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

import json, urllib, subprocess, sys, os

settings = {}

def get_testmapper(testbranch):
    if not os.path.isfile('testmapper.txt'):
        testmapper_url = 'https://raw.githubusercontent.com/NetworkManager/NetworkManager-ci/\%s/testmapper.txt' % (testbranch)
        os.system("curl -s  %s -o testmapper.txt" % testmapper_url)
def get_test_cases_for_features(features, testbranch):
    get_testmapper(testbranch)
    testnames = []
    with open('testmapper.txt', 'r') as f:
        content = f.readlines()
        for feature_name in features:
            processing = False
            for line in content:
                if line.strip().startswith('#@%s_start' % feature_name):
                    processing = True
                    continue
                if line.strip().startswith('#@%s_end' % feature_name):
                    break
                if line.strip().startswith('#') :
                    continue
                line_csv = line.split(',')
                if processing and len(line_csv) >= 3:
                    test_name = line_csv[0].strip()
                    if test_name and test_name not in testnames:
                        testnames.append(test_name)
    subprocess.call('rm -rf testmapper.txt', shell=True)
    return testnames

def process_raw_features(features, testbranch):
    tests = ""
    if not features or features.lower() == 'all':
        raw_features = 'adsl,alias,bond,bridge,team,vlan,connection,dispatcher,ethernet,general,ipv4,ipv6,libreswan,openvpn,ppp,pptp,tuntap,vpnc'
    else:
        raw_features = features
    features = []
    for f in raw_features.split(','):
        features.append(f.strip())
    for test in get_test_cases_for_features(features, testbranch):
        tests=tests+test+" "
    return tests.strip()

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
    ver="7"
    arch="x86_64"
    count=1

    get_nodes_url="%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (url_base,api,ver,arch,count)

    dat=urllib.urlopen(get_nodes_url).read()
    b=json.loads(dat)

    tests=process_raw_features(features, test_branch)
    print (tests)

    for h in b['hosts']:
        # Do the work
        cmd0="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'yum install -y git \
                                                   && git clone https://github.com/NetworkManager/NetworkManager-ci \
                                                   && cd NetworkManager-ci \
                                                   && sh run/centos-ci/scripts/./setup.sh \
                                                   && sh run/centos-ci/scripts/./build.sh %s \
                                                   && sh run/centos-ci/scripts/./get_tests.sh %s \
                                                   && sh run/centos-ci/scripts/./runtest.sh %s ; \
                                                   sh run/centos-ci/scripts/./archive.sh %s' \
                                                   "% (h, code_branch, test_branch, tests, api[:13])
        # Save return code
        rtn_code=subprocess.call(cmd0, shell=True)

        # Archive results and rpms
        cmd1="ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'sh run/centos-ci/scripts/./archive.sh %s'"% (h, api[:13])
        subprocess.call(cmd1, shell=True)

        # Upload results to transfer.sh
        subprocess.call("ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s \
                                curl --upload-file /var/www/html/results/Test_results-* https://transfer.sh && echo \n" % (h), shell=True)


    done_nodes_url="%s/Node/done?key=%s&ssid=%s" % (url_base, api, b['ssid'])
    das=urllib.urlopen(done_nodes_url).read()

    return(rtn_code)

if __name__ == "__main__":
    read_env_options()
    sys.exit(run_tests(settings['features'], settings['code_branch'], settings['test_branch']))
