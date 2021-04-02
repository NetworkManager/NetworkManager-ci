#!/usr/bin/python3
import logging
import subprocess
import sys
import urllib.request
import gzip
import os
import yaml

def check_build(baseurl):
    copr_log = "backend.log.gz"
    last = "curl -s %s \
            | grep -o \"<a href='[0-9]*-NetworkManager'>\" \
            | sort -r | head -n 1 \
            | grep -o '[0-9]*-NetworkManager'" % baseurl

    last_but_one = "curl -s %s \
            | grep -o \"<a href='[0-9]*-NetworkManager'>\" \
            | sort -r | head -n 2 | tail -n -1 \
            | grep -o '[0-9]*-NetworkManager'" % baseurl

    out = subprocess.check_output(last, shell=True)
    last_dir = out.decode('utf-8').strip()
    backend_url = baseurl+"/"+last_dir+"/"+copr_log

    try:
        logging.debug ("Opening %s" %backend_url)
        back = urllib.request.urlopen(backend_url)
    except:
        logging.debug ("Trying the last but one as current one probably running")
        try:
            out = subprocess.check_output(last_but_one, shell=True)
            logging.debug(out)
            last_but_one_dir = out.decode('utf-8').strip()
            backend_url = baseurl+"/"+last_but_one_dir+"/"+copr_log
            logging.debug(backend_url)
            back = urllib.request.urlopen(backend_url)
        except:
            logging.debug ("FATAL: Cannot get last but one either.")
            return False

    with gzip.open(back,'r') as f:
        readfile = f.read().decode('utf-8')
        if 'Worker failed build' in readfile:
            logging.debug("Copr build failed")
            return False
        else:
            logging.debug("Copr build succesfull")
            return True

def add_epel_crb_repos():
    # Add some extra repos
    epel_url = "https://dl.fedoraproject.org/pub/epel/"
    rpm = "epel-release-latest-8.noarch.rpm"
    subprocess.call("dnf -y install %s%s" %(epel_url, rpm), shell=True)
    # For some reason names can differ, so enable both powertools
    subprocess.call("yum config-manager --set-enabled PowerTools", shell=True)
    subprocess.call("yum config-manager --set-enabled powertools", shell=True)

def write_copr(nm_dir):
    host = "https://copr-be.cloud.fedoraproject.org"
    dirs = "results/networkmanager"
    nm_dir = nm_dir
    centos_dir = "centos-stream-8-x86_64"
    baseurl = host+"/"+dirs+"/"+nm_dir+"/"+centos_dir+"/"

    if not check_build(baseurl):
        return False

    with open("/etc/yum.repos.d/nm-copr.repo", "w") as cfg:
        cfg.write('[nm-copr-repo]\n')
        cfg.write('name=nm-copr-repo\n')
        cfg.write('baseurl=%s\n' %baseurl)
        cfg.write('enable=1\n')
        cfg.write('gpgcheck=0\n')
        cfg.write('skip_if_unavailable=0\n')
        cfg.write('sslverify=0\n')
        cfg.write("\n")
    cfg.close()
    return True


def get_testmapper(testbranch):
    gh_url = "https://raw.githubusercontent.com/"
    gh_dirs = "NetworkManager/NetworkManager-ci/%s/" %testbranch
    testmapper_url = '%s/%s/mapper.yaml' %(gh_url, gh_dirs)
    try:
        logging.debug ("Opening %s" %testmapper_url)
        return urllib.request.urlopen(testmapper_url)
    except:
        logging.debug ("No testmapper")
        return None

def get_test_cases_for_features(features, testbranch):
    testnames = []
    mapper = get_testmapper(testbranch)
    if mapper:
        content = mapper.read().decode('utf-8')
        content_parsed = yaml.load(content)
        for test in content_parsed['testmapper']['default']:
            for test_name in test:
                if test[test_name]['feature'] in features or 'all' in features:
                    if test_name and test_name not in testnames:
                        testnames.append(test_name)
    return testnames


def generate_junit(results_dir):
    failed = []
    passed = []
    for f in os.listdir(results_dir):
        f = f.split('.html')[0]
        if 'FAIL' in f:
            f = f.split('FAIL-')[1]
            failed.append(f)
            continue
        if 'RESULT' in f:
            continue
        if 'tar.gz' in f:
            continue
        else:
            passed.append(f)

    import xml.etree.ElementTree as ET
    root = ET.ElementTree()
    testsuite = ET.Element('testsuite', tests=str(len(passed) + len(failed)))
    for passed_test in passed:
        testcase = ET.Element('testcase', classname="tests", name=passed_test)
        testsuite.append(testcase)
    for failed_test in failed:
        testcase = ET.Element('testcase', classname="tests", name=failed_test)
        failure = ET.Element('failure')
        failure.text = "Error"
        testcase.append(failure)
        testsuite.append(testcase)
    root._setroot(testsuite)
    junit_path = "%s/junit.xml" %results_dir
    root.write(junit_path)
    return 0


def process_raw_features(features, testbranch):
    tests = ""
    if not features or features.lower() == 'all':
        raw_features = "adsl,alias, \
                        bond,bridge,\
                        team,vlan, \
                        connection,dispatcher, \
                        ethernet,general, \
                        ipv4,ipv6,\
                        libreswan,openvpn,\
                        ppp,pptp,\
                        tuntap,vpnc,tc"
    else:
        raw_features = features
    features = []
    for f in raw_features.split(','):
        features.append(f.strip())
    for test in get_test_cases_for_features(features, testbranch):
        tests=tests+test+" "
    return tests.strip()


def prepare_box(branch):
    # Install all packages and remove them
    add_epel_crb_repos()
    logging.debug("install all packages to pull in all deps")
    subprocess.call("yum -q -y install NetworkManager-team \
                        NetworkManager-ppp NetworkManager-wifi \
                        NetworkManager-adsl NetworkManager-ovs \
                        NetworkManager-tui NetworkManager-wwan \
                        NetworkManager-bluetooth NetworkManager-libnm-devel \
                        --skip-broken", shell=True)

    # # Prepare copr repo
    dir = "NetworkManager-main-debug"
    if branch == "nm-1-30":
        dir = "NetworkManager-1.30-debug"
    if branch == "nm-1-28":
        dir = "NetworkManager-CI-1.28-git"
    if branch == "nm-1-26":
        dir = "NetworkManager-CI-1.26-git"

    logging.debug("prepare %s copr repo" %dir)
    if not write_copr (dir):
        return False

    logging.debug("Removing NM rpms")
    cmd = "rpm -ea --nodeps $(rpm -qa | grep NetworkManager)"
    subprocess.call(cmd, shell=True)
    logging.debug("Done")

    # Install new rpms
    cmd = "yum -y install --repo nm-copr-repo NetworkManager*"
    if subprocess.call(cmd, shell=True) == 0:
        return True

def install_workarounds ():
    # We need non crashing lindp
    fedora_url = "https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/"
    libnl = fedora_url+"libndp-1.7-5.el8.x86_64.rpm"
    libnl_devel = fedora_url+"libndp-devel-1.7-5.el8.x86_64.rpm"
    cmd0 = "yum install -y libnl libnl-devel"
    cmd1 = "yum -y update %s %s" %(libnl, libnl_devel)
    subprocess.call(cmd0, shell=True) == 0
    subprocess.call(cmd1, shell=True) == 0

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    test_branch = sys.argv[1]
    code_branch = sys.argv[2]
    features = sys.argv[3]

    install_workarounds ()

    if not prepare_box (code_branch):
        sys.exit(1)

    tests = process_raw_features (features, test_branch)
    if tests == "":
        logging.debug("no tests to run: %s" %tests)
        sys.exit(1)
    else:
        logging.debug("tests to run: %s" %tests)

    cmd = "sh run/centos-ci/scripts/./runtest.sh %s" %tests
    runtest = subprocess.Popen(cmd, shell=True)
    exit_code = runtest.wait()
    generate_junit ("/tmp/results")
    sys.exit (exit_code)
