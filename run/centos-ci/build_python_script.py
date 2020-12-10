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

import json, yaml, urllib, subprocess, sys, os

settings = {}


def get_testmapper(testbranch):
    if not os.path.isfile("mapper.yaml"):
        testmapper_url = (
            "https://raw.githubusercontent.com/NetworkManager/NetworkManager-ci/\%s/mapper.yaml"
            % (testbranch)
        )
        os.system("curl -s  %s -o mapper.yaml" % testmapper_url)


def get_test_cases_for_features(features, testbranch):
    get_testmapper(testbranch)
    testnames = []
    with open("mapper.yaml", "r") as f:
        content = f.read()
        content_parsed = yaml.load(content)
        for test in content_parsed["testmapper"]["default"]:
            for test_name in test:
                if test[test_name]["feature"] in features or "all" in features:
                    if test_name and test_name not in testnames:
                        testnames.append(test_name)
    subprocess.call("rm -rf mapper.yaml", shell=True)
    return testnames


def process_raw_features(features, testbranch):
    tests = ""
    if not features or features.lower() == "all":
        raw_features = "adsl,alias,bond,bridge,team,vlan,connection,dispatcher,ethernet,general,ipv4,ipv6,libreswan,openvpn,ppp,pptp,tuntap,vpnc,tc"
    else:
        raw_features = features
    features = []
    for f in raw_features.split(","):
        features.append(f.strip())
    for test in get_test_cases_for_features(features, testbranch):
        tests = tests + test + " "
    return tests.strip()


def read_env_options():
    print(">> Reading env options")
    # Setting defaults
    settings["code_branch"] = "master"
    settings["test_branch"] = "master"
    settings["features"] = "all"

    if "CODE_BRANCH" in os.environ:
        settings["code_branch"] = os.environ["CODE_BRANCH"]
    if "TEST_BRANCH" in os.environ:
        settings["test_branch"] = os.environ["TEST_BRANCH"]
    if "FEATURES" in os.environ:
        settings["features"] = os.environ["FEATURES"]


def generate_junit():
    failed = []
    passed = []
    for f in os.listdir("results"):
        f = f.split(".html")[0]
        if "FAIL" in f:
            f = f.split("FAIL-")[1]
            failed.append(f)
            continue
        if "RESULT" in f:
            continue
        else:
            passed.append(f)

    import xml.etree.ElementTree as ET

    root = ET.ElementTree()
    testsuite = ET.Element("testsuite", tests=str(len(passed) + len(failed)))
    for passed_test in passed:
        testcase = ET.Element("testcase", classname="tests", name=passed_test)
        testsuite.append(testcase)
    for failed_test in failed:
        testcase = ET.Element("testcase", classname="tests", name=failed_test)
        failure = ET.Element("failure")
        failure.text = "Error"
        testcase.append(failure)
        testsuite.append(testcase)
    root._setroot(testsuite)
    junit_path = "junit.xml"
    root.write(junit_path)
    return 0


def run_tests(features, code_branch, test_branch):
    url_base = "http://admin.ci.centos.org:8080"
    # This file was generated on your slave.  See https://wiki.centos.org/QaWiki/CI/GettingStarted
    api = open("/home/networkmanager/duffy.key").read().strip()
    ver = "8-stream"
    arch = "x86_64"
    count = 1
    try:
        get_nodes_url = "%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (
            url_base,
            api,
            ver,
            arch,
            count,
        )
        dat = urllib.urlopen(get_nodes_url).read()
        b = json.loads(dat)
    except:
        ver = "8"
        get_nodes_url = "%s/Node/get?key=%s&ver=%s&arch=%s&count=%s" % (
            url_base,
            api,
            ver,
            arch,
            count,
        )
        dat = urllib.urlopen(get_nodes_url).read()
        b = json.loads(dat)

    tests = process_raw_features(features, test_branch)
    print(tests)

    for h in b["hosts"]:
        h += str(".ci.centos.org")
        # Do the work
        subprocess.call("echo '*running tests' >> log.txt", shell=True)
        cmd0 = (
            "ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s 'yum install -y git \
                                                   && git clone https://github.com/NetworkManager/NetworkManager-ci \
                                                   && cd NetworkManager-ci \
                                                   && git checkout %s \
                                                   && sh run/centos-ci/scripts/./get_tests.sh %s \
                                                   && sh run/centos-ci/scripts/./setup.sh \
                                                   && sh run/centos-ci/scripts/./build.sh %s \
                                                   && sh run/centos-ci/scripts/./runtest.sh %s' \
                                                   "
            % (h, test_branch, test_branch, code_branch, tests)
        )
        # Save return code
        rtn_code = subprocess.call(cmd0, shell=True)

        subprocess.call("echo '* DONE' >> log.txt", shell=True)
        # Archive results and rpms
        subprocess.call("echo 'archive results' >> log.txt", shell=True)
        cmd1 = (
            "ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s \
                                                    'sh NetworkManager-ci/run/centos-ci/scripts/./archive.sh %s'"
            % (h, api[:13])
        )
        subprocess.call(cmd1, shell=True)
        subprocess.call("echo '* DONE' >> log.txt", shell=True)

        # Upload results to transfer.sh
        # subprocess.call("ssh -t -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s \
        #                        curl --upload-file /tmp/results/Test_results-* https://transfer.sh && echo \n" % (h), shell=True)

        # Download results for in jenkins storage
        subprocess.call("echo 'download stuff' >> log.txt", shell=True)
        subprocess.call("mkdir results", shell=True)
        subprocess.call(
            "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@%s:/tmp/results/Test_results-* ./results"
            % (h),
            shell=True,
        )
        subprocess.call(
            "cd results && tar -xzf Test_results* && rm -rf Test_results* && cd ..",
            shell=True,
        )
        subprocess.call("echo '* DONE' >> log.txt", shell=True)

        subprocess.call("echo 'generate junit' >> log.txt", shell=True)
        # Generate junit.xml for graph from results dir
        generate_junit()
        subprocess.call("echo '* DONE' >> log.txt", shell=True)

        subprocess.call("echo '* ALL DONE' >> log.txt", shell=True)

    done_nodes_url = "%s/Node/done?key=%s&ssid=%s" % (url_base, api, b["ssid"])
    das = urllib.urlopen(done_nodes_url).read()

    return rtn_code


if __name__ == "__main__":
    read_env_options()
    sys.exit(
        run_tests(
            settings["features"], settings["code_branch"], settings["test_branch"]
        )
    )
