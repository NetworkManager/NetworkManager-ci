# NetworkManager-ci
This repo contains a set of integration tests for NetworkManager and CentOS 8 Stream based VM test instructions


### Nightly status (CentOS CI)

| Code Branch | Build Status |
| ------------| ------------ |
| main | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/) |
| 1.38.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-38/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-38/) |
| 1.36.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-36/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-36/) |
| 1.34.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-34/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-34/) |
| 1.32.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-32/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-32/) |
| 1.30.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/) |

### Howto execute basic test suite manually on localhost

* Prerequisites
  * CentOS qcow2 image, running libvirtd
  ```bash
  yum -y install virt-install /usr/bin/virt-sysprep virt-viewer libvirt
  systemctl start libvirtd

  SSH_KEY=/home/vbenes/.ssh/id_rsa.pub
  IMG=CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2
  wget https://cloud.centos.org/centos/8-stream/x86_64/images/$IMG

  virt-sysprep -root-password password:centos -a $IMG

  # We need sudo to access default bridged networking
  sudo virt-install --name CentOS_8_Stream --memory 4096 --vcpus 4 --disk $IMG,bus=sata --import --os-variant centos-stream8 --network default

  # Virsh doesn't sort machines so you may need to use different than first
  # But you need IP for later usage
  IP=$(sudo virsh net-dhcp-leases default | grep ipv4 | awk '{print $5}' |head -1 | awk -F '/' '{print $1}')
  ssh-copy-id root@$IP
  ```

* Running Tests
  * with NM compilation
  ```bash
  # NMCI test code. NMCI main should work everywhere
  TEST_BRANCH='main'
  # REFSPEC of your NM code change, work with repo below
  REFSPEC='main'
  # Change to whatever repo you want to compile NM from
  NM_REPO='https://gitlab.freedesktop.org/vbenes/NetworkManager'
  # Choose a list of features you want to test, you can have 'all' to test everything
  FEATURES='adsl, bond'

  INSTALL1="yum install -y git python3 wget"
  INSTALL2="python3 -m pip install python-gitlab pyyaml"
  NMCI_URL="https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git"
  CLONE="git clone $NMCI_URL; cd NetworkManager-ci; git checkout  $TEST_BRANCH"
  TEST="cd NetworkManager-ci; python3 run/centos-ci/node_runner.py -t $TEST_BRANCH -c $REFSPEC -f \"$FEATURES\" -r $NM_REPO"

  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $INSTALL1 && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $INSTALL2 && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $CLONE && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $TEST
  ```
  * you can avoid compilation and use already installed packages
  ```bash
  # NMCI test code. NMCI main should work everywhere
  TEST_BRANCH='vb/nmtest'
  # Choose a list of features you want to test, you can have 'all' to test everything
  FEATURES='all'

  INSTALL1="yum install -y git python3 wget"
  INSTALL2="python3 -m pip install python-gitlab pyyaml"
  NMCI_URL="https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git"
  CLONE="git clone $NMCI_URL;cd NetworkManager-ci; git checkout  $TEST_BRANCH"
  TEST="cd NetworkManager-ci; python3 run/centos-ci/node_runner.py -t $TEST_BRANCH -f \"$FEATURES\" -D"

  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $INSTALL1 && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $INSTALL2 && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $CLONE && \
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP $TEST
  ```
  * or you can just ssh into the machine and run
  ```bash
  cd /root/NetworkManager-ci
  # Test by test as defined in mapper.txt
  run/runtest.sh your_desired_test
  # Feature by feature as listed too in mapper.txt
  run/runfeature.sh your_desired_feature
  ```
* Results check
  * you will see execution progress as it goes ( tests do have 10m timeout to prevent lockup )
  * there is a summary at the end


### How to write a NMCI test

* We use slightly modified python-behave framework to execute tests
  * https://behave.readthedocs.io/en/stable/
* It's quite readable and easy to learn
* Let's describe directory structure and files of NMCI first
 * /
   * mapper.yaml file
     * use for driving tests
     * all tests names are written there (together with features)
     * all dependencies and basically all metadata is there
   * nmci dir
     * various scripts used for driving tests
     * the most interesting are tags that are used for preparing and cleaning environment
     * we have unit tests for version_control here, libs for tags, run for running commands, etc
   * nmci/helpers/version_control.py script
     * we have just one NMCI branch for all NM versions, RHELs, Fedora, CentOSes
     * this is the control mechanism if we need to skip test here and there
  * features dir
    * scenarios dir
      * sets of features in .feature files
      * test itself will be described deeper later on
    * environment.py script
      * script driving setup and teardown of each test
      * includes nmci/tags.py to be more readable
      * collects all logs and creates html log
    * steps dir
      * all steps (aka test lines) are defined here
      * strictly python, with paramterized decorators used in features itself
 	  * categorized into various functional areas like bond_bridge_team/connection/commands, etc
  * prepare dir
    * various scripts for preparing environment
    * vethsetup.sh
      * this one creates whole 11 device wide test bed
      * executed at first test execution if needed
    * envsetup.sh
      * installs various packages and tunes environment
      * executed at first test execution
  * run
    * various executors for various envs
    * runtest.sh
      * the main driver of tests
      * execution of test looks like: `run/runtest.sh test_name`
      * to embed everything to HTML use: `NMCI_DEBUG=yes run/runtest.sh test_name`
    * runfeature.sh
      * doing the same as runtest.sh but for whole features
      * `run/runfeature.sh bond` for example
      * `run/runfeature.sh bond --dry` just lists tests
  * tmp/contrib
    * various files and reproducers needed for tests
    * should be later moved to contrib where we have +- the same


* Let's use an example test to describe how we do that
  *
  ```gherkin  
  # Reference to bugzilla, doing nothing
  @rhbz1915457
  # Version control, test will run on F32+ or RHEL8.4+
  # with NM of 1.30+ only. Test will be skipped in CentOS
  @ver+=1.30 @rhelver+=8.4 @fedver+=32 @skip_in_centos
  # Bond and slaves residuals will be deleted after test
  # Test name as stated in mapper.txt
  @bond_8023ad_with_vlan_srcmac
  # Human readable test name as stated in HTML report
  Scenario: nmcli - bond - options - mode set to 802.3ad with vlan+srcmax
  # Step for creation a NM profile with options
  * Add "bond" connection named "bond0" for device "nm-bond" and options
                                  """
                                  bond.options 'mode=802.3ad,
                                  miimon=100,xmit_hash_policy=vlan+srcmac'
                                  """
  # Step for creation slave connection, similar to above can be used too, we have two
  * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
  # Bring up the connection, you can use down too
  * Bring "up" connection "bond0.0"
  # You can execute various commands too
  * Execute "echo 'Hello world'"
  # Check various value via period of time (once a second). Then keyword is useles, just marking results more visible
  Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond" in "5" seconds
  # Check various value twice (default)
  Then "Transmit Hash Policy:\s+vlan\+srcmac" is visible with command "cat /proc/net/bonding/nm-bond"
  # Check various value immediately
  Then "Transmit Hash Policy:\s+vlan\+srcmac" is visible with command "cat /proc/net/bonding/nm-bond" in "1" seconds
  # Very bond specific step checking if bond device is up.
  Then Check bond "nm-bond" link state is "up"
  ```

* Reports
  * You can see stdout output when running from command line
  * You can see nice HTML reports too stored in /tmp
    * PASS report has just after cleanup info in it
      * https://vbenes.fedorapeople.org/NM/PASS_bond_8023ad_with_vlan_srcmac.html
    * FAIL report has all commands listed and logs added from before, after, after cleanup
      * https://vbenes.fedorapeople.org/NM/FAIL_ipv6_survive_external_link_restart.html
