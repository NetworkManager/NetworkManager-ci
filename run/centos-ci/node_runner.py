#!/usr/bin/python3
import logging
import subprocess
import sys
import urllib.request
import gzip
import os
import yaml
import json

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
    # Enable build deps for NM
    subprocess.call("yum -y copr enable nmstate/nm-build-deps", shell=True)

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
    logging.debug("Generate JUNIT")
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
    logging.debug("JUNIT Done")
    return 0

def get_features_from_mapper(branch):
    mapper = get_testmapper(branch)
    print (mapper)
    if mapper:
        content = mapper.read().decode('utf-8')
        content_parsed = yaml.load(content)
        default_exclude = ['dcb', 'wifi', 'infiniband', 'wol', 'sriov', 'gsm']
        features = []
        for test in content_parsed['testmapper']['default']:
            for test_name in test:
                f = test[test_name]['feature']
                if f not in default_exclude:
                    if f not in features:
                        features.append(f)
        return (features)
    return None

def process_raw_features(raw_features, testbranch, gitlab_trigger=None):
    tests = ""

    if 'best' in raw_features:
        if gitlab_trigger:
            features = get_modified_features_for_testarea (gitlab_trigger)
            if features == None or features == []:
                features = ["all"]
        else:
            features = ["all"]
        logging.debug("running best effort execution to shorten time: %s" %features)

    elif raw_features == "" or 'all' in raw_features:
        features = get_features_from_mapper(testbranch)
    else:
        features = raw_features.split(',')

    for test in get_test_cases_for_features(features, testbranch):
        tests=tests+test+" "
    return tests.strip()

def install_all_nm_packages ():
    # Install all packages and remove them
    add_epel_crb_repos()

    logging.debug("install all packages to pull in all deps")
    subprocess.call("yum -y install crda NetworkManager-team \
                        NetworkManager-ppp NetworkManager-wifi \
                        NetworkManager-adsl NetworkManager-ovs \
                        NetworkManager-tui NetworkManager-wwan \
                        NetworkManager-bluetooth NetworkManager-libnm-devel \
                        --skip-broken", shell=True)

def remove_all_nm_packages ():
    logging.debug("Removing NM rpms")
    cmd1 = "rpm -ea --nodeps $(rpm -qa | grep NetworkManager)"
    subprocess.call(cmd1, shell=True)
    logging.debug("Done")

def prepare_log_dir (results_dir):
    subprocess.call("mkdir -p %s" %results_dir, shell=True)

def prepare_box(nm_refspec):
    results_dir = "/tmp/results/"
    build_dir = "/root/nm-build"
    install_all_nm_packages ()
    prepare_log_dir (results_dir)

    # Prepare copr repo if we know branch
    dir = ""
    if nm_refspec == "main":
        dir = "NetworkManager-main-debug"
    if nm_refspec == "nm-1-30":
        dir = "NetworkManager-1.30-debug"
    if nm_refspec == "nm-1-28":
        dir = "NetworkManager-CI-1.28-git"
    if nm_refspec == "nm-1-26":
        dir = "NetworkManager-CI-1.26-git"

    remove_all_nm_packages ()

    if dir != "":
        logging.debug("prepare %s copr repo" %dir)
        if not write_copr (dir):
            return 1
        # Install new rpms
        cmd2 = "yum -y install --repo nm-copr-repo NetworkManager*"
        return subprocess.call(cmd2, shell=True)

    else:
        # compile from source
        logging.debug("Building from refspec id %s" %nm_refspec)
        cmd0 = "sh run/centos-ci/scripts/./build.sh %s" %nm_refspec
        if subprocess.call(cmd0, shell=True) == 1:
            # We want config.log to be archived
            cmd1 = "cp %s/NetworkManager/config.log %s" %(build_dir,results_dir)
            subprocess.call(cmd1, shell=True)
        else:
            return 0

    return 1

def install_workarounds ():
    # pass
    cmd0 = "yum -y install https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-1.7-5.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-devel-1.7-5.el8.x86_64.rpm"
    subprocess.call(cmd0, shell=True)
    cmd1 = "yum -y install crda make"
    subprocess.call(cmd1, shell=True)

def set_gitlab (trigger_data, gl_token):
    with open("/etc/python-gitlab.cfg", "w") as cfg:
        cfg.write('[global]\n')
        cfg.write('default = gitlab.freedesktop.org\n')
        cfg.write('ssl_verify = false\n')
        cfg.write('timeout = 30\n')
        cfg.write('[gitlab.freedesktop.org]\n')
        cfg.write('url = https://gitlab.freedesktop.org\n')
        cfg.write('private_token = %s\n' %gl_token)
        cfg.write("\n")
        cfg.close()

    import base64
    content = base64.b64decode(trigger_data).decode('utf-8').strip()
    data = json.loads(content)
    logging.debug(data)
    from cico_gitlab_trigger import GitlabTrigger
    gitlab_trigger = GitlabTrigger(data)
    return gitlab_trigger

def get_modified_features_for_testarea(gl_trigger):
    default_exlude = ['dcb', 'wifi', 'infiniband', 'wol', 'sriov', 'gsm']
    features = []
    # do it via wget and raw mode - as API is silly complicated in getting MR's diff
    print(">> Reading patch from gitlab merge request: " + gl_trigger.merge_request_url)
    cmd = "wget %s.diff -O patch.diff" % gl_trigger.merge_request_url
    print("Executing " + cmd)
    if os.system(cmd) != 0:
        print("Failed downloading diff")
        return None
    with open('patch.diff', 'r') as f:
        content = f.readlines()

    for line in content:
        import re
        m = re.match(r'^\+\+\+(.*/(\S+)\.feature)', line)
        if m is not None and 'nmcli' in m.group(1):
            if m.group(2) not in default_exlude:
                logging.debug('Found feature: %s' % m.group(1))
                features.append(m.group(2))
        elif m is not None and 'nmtui' in m.group(1):
            features.append('nmtui')
    return features

def post_results (gl_trigger):
    with open('/tmp/summary.txt', 'r') as f:
        lines = f.readlines()
    # PASS/FAIL/SKIP
    p = lines[0].strip()
    f = lines[1].strip()
    s = lines[2].strip()
    msg = "CentOS Testing Summary\n\n"
    if p == '0' and f == '0' and s == '0':
        msg+= "Something went wrong!\n"
    if f != '0':
        msg+= "Result: Unstable: Some tests failed!\n"
    else:
        msg+= "Result: STABLE: All tests passing!\n"
    msg+="\nPassed: %s, Failed: %s, Skipped: %s\n\n" %(p, f, s)
    with open('/etc/redhat-release') as f:
        msg+="Executed on: %s" %(f.read())
    gl_trigger.post_commit_comment(msg)

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.debug("reading params")
    # NEVER PRINT THIS AS IT HAS GL_TOKEN
    # logging.debug(sys.argv)

    test_branch = sys.argv[1]
    logging.debug(test_branch)

    if len(sys.argv) > 2:
        nm_refspec = sys.argv[2]
        logging.debug(nm_refspec)
    if len(sys.argv) > 3:
        raw_features = sys.argv[3]
        logging.debug(raw_features)
    if len(sys.argv) > 4:
        build_id = sys.argv[4]
        logging.debug(build_id)
        os.environ['BUILD_URL'] = build_id
    if len(sys.argv) > 5:
        gl_token = sys.argv[5]
        # NEVER PRINT THIS AS IT HAS GL_TOKEN
        # logging.debug(gl_token)
    if len(sys.argv) > 6:
        trigger_data = sys.argv[6]
        logging.debug(trigger_data)
    else:
        trigger_data = None

    gitlab_trigger = None
    if trigger_data:
        gitlab_trigger = set_gitlab(trigger_data, gl_token)
    if gitlab_trigger:
        tests = process_raw_features (raw_features, test_branch, gitlab_trigger)
    else:
        tests = process_raw_features (raw_features, test_branch)

    if tests == "":
        tests = "pass"
        logging.debug("no tests to run, running just pass test")
    else:
        logging.debug("tests to run: %s" %tests)

    install_workarounds ()

    if prepare_box (nm_refspec) != 0:
        sys.exit(1)

    cmd = "sh run/centos-ci/scripts/./runtest.sh %s" %tests
    if gitlab_trigger:
        gitlab_trigger.set_pipeline('running')
    runtest = subprocess.Popen(cmd, shell=True)
    exit_code = runtest.wait()

    if gitlab_trigger:
        if exit_code != 0:
            gitlab_trigger.set_pipeline('failed')
        else:
            gitlab_trigger.set_pipeline('success')
        post_results (gitlab_trigger)

    generate_junit ("/tmp/results")
    logging.debug("All Done. Exit with %s" %exit_code)
    sys.exit (exit_code)
