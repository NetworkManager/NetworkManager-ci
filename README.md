# NetworkManager-ci
This repo contains a set of integration tests for NetworkManager and CentOS 8 Stream based VM test instructions


### Nightly status (CentOS CI)

| Code Branch | Build Status |
| ------------| ------------ |
| main | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/) |
| 1.40.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-40/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-40/) |
| 1.38.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-38/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-38/) |
| 1.36.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-36/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-36/) |
| 1.34.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-34/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-34/) |
| 1.32.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-32/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-32/) |

### Howto execute basic test suite manually on localhost

* Prerequisites
  * CentOS qcow2 image, running libvirtd
    ```bash
    dnf -y install virt-install /usr/bin/virt-sysprep virt-viewer libvirt
    systemctl start libvirtd

    SSH_KEY=/home/vbenes/.ssh/id_rsa.pub
    IMG=CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2
    wget https://cloud.centos.org/centos/8-stream/x86_64/images/$IMG

    virt-sysprep -root-password password:centos -a $IMG

    # We need sudo to access default bridged networking
    sudo virt-install --name CentOS_8_Stream --memory 4096 --vcpus 4 --disk $IMG,bus=sata --import --os-variant centos-stream8 --network default

    # Virsh doesn't sort machines so you may need to use different VM
    # than the first. Alternatives are name resolution or port forwarding.
    IP=$(sudo virsh net-dhcp-leases default | grep ipv4 | awk '{print $5}' |head -1 | awk -F '/' '{print $1}')
    ssh-copy-id root@$IP
    ```
    Name resolution of or port forwarding to a given VM are described in 
    [Networking tips for local VMs](#networking-tips-for-local-vms) section below.

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

    INSTALL1="dnf install -y git python3 wget"
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

    INSTALL1="dnf install -y git python3 wget"
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
 * [`/`](/.)
   * [`mapper.yaml`](/mapper.yaml) file
     * use for driving tests
     * all tests names are written there (together with features)
     * all dependencies and basically all metadata is there
   * [`nmci`](/nmci) dir
     * various scripts used for driving tests
     * the most interesting are tags that are used for preparing and cleaning environment
     * we have unit tests for version_control here, libs for tags, run for running commands, etc
   * [`nmci/helpers/version_control.py`](/nmci/helpers/version_control.py) script
     * we have just one NMCI branch for all NM versions, RHELs, Fedora, CentOSes
     * this is the control mechanism if we need to skip test here and there
  * [`features`](/features) dir
    * [`scenarios`](/features/scenarios) dir
      * sets of features in `.feature` files
      * test itself will be described deeper later on
    * [`environment.py`](/features/environment.py) script
      * script driving setup and teardown of each test
      * includes [`nmci/tags.py`](/nmci/tags.py) to be more readable
      * collects all logs and creates html log
    * [`steps`](/features/steps) dir
      * all steps (aka test lines) are defined here
      * strictly python, with paramterized decorators used in features itself
 	  * categorized into various functional areas like bond/bridge/team/connection/commands, etc
  * [`prepare`](/prepare) dir
    * various scripts for preparing environment
    * [`vethsetup.sh`](/prepare/vethsetup.sh)
      * this one creates whole 11 device wide test bed
      * executed at first test execution if needed
      * some CI machines have equivalent environment set up by physical switches or virt/cloud
        VM settings. If you need to tweak the environment for your scenario, use
        `Prepare simulated test...` steps instead, please.
    * [`envsetup.sh`](/prepare/envsetup.sh)
      * installs various packages and tunes environment
      * executed at first test execution
  * [`run`](/run)
    * various executors for various envs
    * [`runtest.sh`](/run/runtest.sh)
      * the main driver of tests
      * execution of test looks like: `run/runtest.sh test_name`
      * to embed everything to HTML use: `NMCI_DEBUG=yes run/runtest.sh test_name`
    * [`runfeature.sh`](/run/runfeature.sh)
      * doing the same as `runtest.sh` but for whole features
      * `run/runfeature.sh bond` for example
      * `run/runfeature.sh bond --dry` just lists tests
  * [`contrib`](/contrib)
    * various files and reproducers needed for tests


* Let's use an example test to describe how we do that
  *
  ```gherkin  
  # Reference to bugzilla, doing nothing
  @rhbz1915457
  # Version control, test will run on F32+ or RHEL8.4+
  # with NM of 1.30+ only. Test will be skipped in CentOS
  @ver+=1.30 @rhelver+=8.4 @fedver+=32 @skip_in_centos
  # Bond and slaves residuals will be deleted after test
  # Test name as stated in mapper.txt. Must be last tag and sole tag on the line
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

#### How to test your changes
  1. Run your new or updated scenario by hand:
     ```
     run/runtest.sh my_new_scenario
     ```
     as already mentioned. The [`run/runtest.sh`](/run/runtest.sh) script comes with some handy features:
     * bash completion is available so you can type just `run/runtest.sh my_new<tab>` and it will complete the
       command to `run/runtest.sh my_new_scenario`
     * also, the `run/runtest.sh` script is forgiving of @-sign at the start of test\_tag for mouse-friendly tag pasting
     * when you need to pretend that NM version is different from one actually installed, nmci will honor version
       set in environment variable such as `NM_VERSION=1.39.1`
     * `run/runtest.sh` produces terse report for PASSing scenarios by default to save space
       required by CI. To get full output always, set (as already mentioned) `NMCI_DEBUG` environment variable to `yes`
  1. Unit tests
     * you can run them yourself before submitting or updating a MR:
       ```
       NetworkManager-ci$ python3 -m pytest nmci/test_nmci.py
       ```
  1. or you can create a Merge Request in [Freedesktop Gitlab](https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci)
     right away and CI tooling will run both of these for you (changed scenarios only if unit tests pass successfully).

### Accessing reports over HTTP

When testing at different machine than that running your browser, it is handy to have HTTP server on the test
machine and some means to auto-archive your test report from /tmp somewhere else. NetworkManager-ci come
with script that will configure `httpd` on your machine to serve the copied reports on port 8080 and a
little system service that watches /tmp. When new report is created, the service copies it with a timestamp
to `httpd`'s DocumentRoot so you can compare multiple runs of the same scenario.

Service can be set up by script `run/publish_behave_logs/setup_pbl.py` or manually by copying service and its file
to appropriate location and configuring web server as you need. CI machines install these by default so you can access
their test reports this way when the test run is still underway and CI didn't collect them yet.

### Networking tips for local VMs

Default libvirt networking works just OK but leaves a bit of convenience or features for regular use
or when one has multiple VMs. Following sections feature tips to make local VM network more convenient or
more accessible from outside.

#### Name-based networking for local libvirt networks

For local libvirt VMs with floating bridges or NAT'd networks, there are several good ways how to access VMs by name:
  * [libvirt-nss](https://libvirt.org/nss.html) which when set up according to their docs allows you to access
    VMs by their ‘libvirt domain’ name (`libvirt_guest` nsswitch module) or by guest's hostname (`libvirt` nsswitch module).
    Prerequisite for that is however that libvirt gets IP information from within the guest system via agent, you can
    verify if this is the case that you can see the IP when you run:
    ```
    virsh domifaddr DOMAIN_NAME
    ```
    names exposed this way are always without a domain
  * by hooking up libvirt-run dnsmasq that works as DHCP and DNS server for `type="nat"` libvirt networks to the
    system resolver. This is achiveved by:
    1. setting `<domain name="DOMAIN"/>` and `<forward mode='nat'/>` for the network
    1. pointing system DNS resolver to libvirt-run `dnsmasq` for this network. This is pretty easy to configure
       statically for `dnsmasq` or `unbound` however if you run `systemd-resolved`, it's only possible to
       configure specific DNS server for a given domain by changing runtime configuration.
 
       It's possible to automate this using [libvirt hooks](https://www.libvirt.org/hooks.html) mechanism and
       `systemd`'s commands `resolvectl` or `systemd-resolve` but neither project ships necessary glue script
       itself. Therefore I (@djasa) created [this script](https://gist.github.com/djasa/09bf57c152925717db1133d74220b0fc)
       that is fired by libvirt network events and when relevant, updates `systemd-resolved` about it. This
       configuration allows me to use gnome-boxes VMs with bridge/NAT network managed by system-level libvirt
       (or better say `virtnetworkd` these days) and access VMs by their hostname suffixed by custom domain,
       e.g. http://rhel9-nightly.vm:8080/ or `ssh [root@]rhel9-nightly.vm`

NAT or isolated network however don't allow easy access from outside network to VM's ssh or http ports.

#### Host port forwarding to the guest

There is also option to forward given port on host system to another port in the VM when using qemu's
[user mode networking](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29) and it's
`hostdev` option. This is not integrated to libvirt, so in order to use this option, you need to add
`qemu` namespace URI to libvit domain xml:

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>nmci-vm</name>
  …
```

that allows specifying custom arguments (env vars and others, [see libvirt docs](https://libvirt.org/kbase/qemu-passthrough-security.html)
for more information).
Options that create user-mode network interface for the guest with port forwarding from the host can be:

```xml
  …
  <qemu:commandline>
    <qemu:arg value='-netdev'/>
    <qemu:arg value='user,id=mynet.9,net=192.168.120.0/24,hostfwd=tcp::4922-:22,hostfwd=::4980-:8080'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='virtio-net-pci,netdev=mynet.9'/>
  </qemu:commandline>
</domain>
```
Notes:
  * `net=192.168.120.0/24` specifies network range used by qemu. You may want to choose range that won't
    collide with private networks you need to reach from the guest. Guest by default gets .15 address of the range
    (can be changed by `dhcpstart=` according to [Qemu docs](https://www.qemu.org/docs/master/system/invocation.html#hxtool-5)),
    to this addres (192.168.120.15 for this configuration, 10.0.2.15 with no `network=` specification) qemu
    redirects host ports configured by `hostfwd` option unles overriden there
  * `hostfwd=::4922-:22` specifies host forwarding itself:
    * empty source address means v4 wildcard (`0.0.0.0`). If you wonder why qemu doesn't support dual-stack
      wildcard `::` in 2022, you're not alone.
    * empty guest address (between `-` and `:`) means .15 address of range specified by `net=` or
      address specified by `dhcpstart=`
  * Other arguments are well described in `qemu` manual page or
    [online docs](https://www.qemu.org/docs/master/system/invocation.html#:~:text=hostfwd%3D%5Btcp%7Cudp%5D%3A%5Bhostaddr%5D%3Ahostport-%5Bguestaddr%5D%3Aguestport).

Please note that NetworkManager-ci expects just one interface with outside connectivity so this is either-or situation,
there is either bridged networking or qemu-provided port forwarding. Having port forwarding with bridge networking would
need port forwarding configured on system level (doable using already mentioned libvirt hooks mechanism but not used
by anyone in the team right now. Feel free to contribute a working solution if you have one).

### Distribution dependence

nmci is primarily developed and maintained on RHEL/CentOS/Fedora systems so there are distro-specific
parts of the code. They are primarily in
  * `envsetup`. Distro-specific parts are already largely or completely taken out to specific files
    in [`prepare/envsetup`](/prepare/envsetup) directory. Adding more of them for other distros
    should be straightforward
  * other scripts in [`prepare`](/prepare) and some tag implementations in [`tags.py`](/nmci/tags.py) (and few cases in
    [`ctx.py`](/nmci/ctx.py)) use hardwired `rpm`/`yum`/`dnf` invocations. These would need to be generalized
    or where suitable, package instalation moved to `envsetup`
  * version detection code in [`nmci/misc.py`](/nmci/misc.py). Analogous may be needed for finer-grained decisions
    of what scenarios should run on given system
  * CI runners in in [`run`](/run)
  * [`setup_pbl.py`](/run/publish_behave_logs/setup_pbl.py). You may try ansible version
    [`setup_pbl.yml`](/run/publish_behave_logs/setup_pbl.yml) which at least abstracts away package installation.
