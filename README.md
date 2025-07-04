# NetworkManager-ci
This repo contains a set of integration tests for NetworkManager and CentOS 8 Stream based VM test instructions


### Nightly status (CentOS CI)

| Code Branch | Build Status                                                                                                                                                                                                     |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| main        | [![Build Status](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-main-c10s/badge/icon)](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-main-c10s/) |
| 1.54.x      | [![Build Status](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-1.54-c10s/badge/icon)](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-1.54-c10s/) |
| 1.52.x      | [![Build Status](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-1.52-c10s/badge/icon)](https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-1.52-c10s/) |


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
  Scenario: nmcli - bond - options - mode set to 802.3ad with vlan+srcmac
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

#### `@ver` Version Tags

Tests have tags (with an `@`). The @ver tag checks the version of NetworkManager to run or skip the test.
See also `nmci/helpers/version_control.py` script. Use following best practice for choosing a version tag.

- prefer `@ver+=NUMBER` over `@ver+NUMBER` because it is nicer to state the version when the feature starts working,
  and not the version before.

- similarly, prefer `@ver-NUMBER` over `@ver-=NUMBER` to mirror a `@ver+=NUMBER`. We can write two variants of
  a test with different version tags, and the version selection must only match for one variants of the test.
  Hence there should always be separate ranges. The use of `@ver-NUMBER` to mirror `@ver+=NUMBER` makes that clear.

- in NetworkManager, stable releases have an even second version number and an even third number (e.g. 1.42.2).
  A patch/feature/bugfix can only be added in a development version that leads up to a stable release. In the example,
  between the tag 1.42.1 and 1.42.2. The right way for a `@ver+=` tag is thus always the development version, like
  `@ver+=1.42.1`, because the patch is already upstream in `nm-1-42` branch, which is currently between 1.42.1 and
  1.42.2. The test should start working with 1.42.1+ already. Yes, early versions of 1.42.1+ don't have the patch
  yet, but it's more important to test the later versions of the development branch and run the test.
  The right `@ver+=NUMBER` is what `git describe` gives for the commit with the patch.

  * on main branch, the second number is odd and the third number can be odd or even. For example, 1.43.6 is a
    development version leading towards the next major release 1.44.0. Also there, a patch is always introduced
    between two development snapshots, like between 1.43.5 and 1.43.6. Here too, we shall use `@ver+=1.43.5`,
    so that testing current `main` branch (when 1.43.6 is not yet tagged) also covers the test. Note that
    we may take a devel snapshot (1.43.5) and package in RHEL. But that version doesn't have the patch yet,
    so for that RHEL package the test `@ver+=1.43.5` will run but fail. There are are three possibilities.
    First, don't care. These are all just development versions and the situation resolves itself in a few days.
    Second, choose `@ver+=1.43.5.2000`, which would match for upstream builds
    but not for RHEL (note the package version from upstream builds adds a large 4th number).
    Third, add a RHEL specific override like `@ver+=1.43.5 @ver/rhel+=1.43.6`.

The tested NetworkManager version is parsed with a "stream" along the version
number. The stream is a variant of the NetworkManager package or a specific
build configuration. For example, we can have upstream release 1.44.2, which we
can build in copr, as a Fedora package or as a CentOS Stream 9 package. The
build configurations may slightly differ for the same tarball. For example, a
RHEL 8.7 package will be detected to have "rhel/8/7" stream. For most cases,
downstream RHEL/Fedora is very close to upstream so there is no difference
between streams. However, when having a stream like rhel/8/7, then the runner
will first search for version tags `@ver/rhel/8/7`, then `@ver/rhel/8`, then
`@ver/rhel` and finally `@ver`. If any stream specific version tag is found, it
is evaluated and more general tags (like `@ver`) are ignored. For example,
`@ver+=1.43.5 @ver/rhel/9+=1.43.6` means that RHEL 9 packages require a version
1.43.6 or newer, but all other packages require at least version 1.43.5.

### Gitlab merge request pipelines (CI/CD)

Another possibility how to test the changes is to open a merge request in Gitlab. Pipeline first executes [UnitTests](nmci/test_nmci.py) (checks that the tests are consistent, well defined). Independently, remote jenkins triggers executes the tests, when a maintaner reviews and approves the code. The following apply for RHEL and [CentOS trigger](run/centos-ci/cico_gitlab_trigger.py):

1. The tests can be retriggered by sending `rebuild` message to merge request discussion.

1. Only tests in changed `.feature` files are executed (whole features), if not overridden.
   * To override, use `@RunTests:test1,test2,...` in `rebuild` message, or in commit message or in merge request description.
   * `@RunTests:*` forces to execute all tests.
   * `@RunFeatures:feature1,feature2,...` override, which executes only specified features. It can be in either in the latest commit message, in the merge request description or in the `rebuild` comment.

1. Latest NetworkManager main copr build (CentOS) or stock NetworkManager RPM (internal) are tested.
   * To test on specific NetworkManager build, use `@Build:main` or `@Build:0e5a4638807dc34c517988432120e3a5`, in `rebuild` message, or in commit message or in merge request description.
   * In CentOS, if specified `@Build` branch is found in COPR, COPR build will be used instead of build.

1. By default, builds on *CentOS 9 stream* and *RHEL8.X (latest release)* are tested. These OSs can be overriden:
    * by `rebuild OS_STRING` GitLab comment. A build is going to be started just for the OS specified by the `OS_STRING`
    * by `@os:OS_STRING` lines in the latest commit message or in the MR description. Push events or `rebuild` comment in gitlab will trigger builds on these OSs only.

    The format of `OS_STRING` for respective OSs is:
    * for Centos X Stream: `centosX-stream` or short: `cXs`. So for 9 stream, it's `centos9-stream` or `c9s`
    * for RHEL: `rhelX.Y`, so for RHEL 9.3, the string is `rhel9.3`
    * for Fedora: `Fedora-release`, thus `Fedora-39` or `Fedora-Rawhide`. Just `rawhide` is also recognized.

    All the strings mentioned are case insensitive so `@oS:fEDoRa-rAWhIdE` will still get recognized.

1. The priority of overrides is `rebuild` message, commit message, merge request description.

1. The tests can be skipped either by pushing with `git push -o ci.skip`, or "Rebase without pipeline button" in WebUI.

1. If you interlink merge requests (mention counterpart merge request in description), corresponding branch will be used for testing/build:
    * In a [NetworkManager merge request](https://gitlab.freedesktop.org/NetworkManager/NetworkManager/merge_requests) description mention `NetworkManager-ci!ABC` or `https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci/-/merge_requests/ABC` and it will use test from merge request numbered `ABC`

    * In a [NetworkManager-ci merge request](https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci/merge_requests) description mention `NetworkManager!XYZ` or `https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/merge_requests/XYZ` and it will build NetworkManager from merge request numbered `XYZ`

    * Example: NetworkManager!1536 and NetworkManager-ci!1317

1. New build can be triggered by:
   * commenting to open merge request:
     - `rebuild` message will re-trigger build with no additional overrides,
     - message containing overrides starting with `@` will automatically execute new builds,
   * pushing to open merge request - overrides defined in the commit message and merge-request description will be honored.

In CentOS, older builds running on the same CentOS release from the same merge request are stopped to save resources. So, if you push to the merge request before the tests are finished, you may get "Aborted" message in the merge request discussion.


#### Gitlab common use-case examples:

1. When creating merge request, add overrides to description, one override per line:

   ```
   This is example Merge Request
   ...

   @Build:main
   @RunTests:my_new_regression_test
   @OS:rhel8.5
   ```

1. Edit merge request description and add `rebuild` comment to the discussion, which will force the new run of the tests with overrides. The overrides will apply for further pushes to the merge request.

1. For one-time overrides, you can either do rebuild comment in merge request discussion:

   ```
   @Build:nm-1-38
   @RunTests:my_test1,my_test2

   rebuild c8s  # this line can be ommited, works only in CentOS, rhel will be executed too.
   ```

   or specify overrides in the last commit before pushing to the merge request:

   ```
   This adds feature XYZ to the testsuite

   # this feature is not yet merged in NetworkManager
   @Build:my_supporting_branch_in_NM_repository
   # We want to execute all tests, not only changed files
   @RunTests:*
   ```


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
    [`prepare.py`](/nmci/prepare.py)) use hardwired `rpm`/`yum`/`dnf` invocations. These would need to be generalized
    or where suitable, package instalation moved to `envsetup`
  * version detection code in [`nmci/misc.py`](/nmci/misc.py). Analogous may be needed for finer-grained decisions
    of what scenarios should run on given system
  * CI runners in in [`run`](/run)
  * [`setup_pbl.py`](/run/publish_behave_logs/setup_pbl.py). You may try ansible version
    [`setup_pbl.yml`](/run/publish_behave_logs/setup_pbl.yml) which at least abstracts away package installation.
