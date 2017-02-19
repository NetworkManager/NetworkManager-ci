# NetworkManager-ci
This repo contains a set of integration tests for NetworkManager and vagrant based executor

### Howto execute basic test suite (90minutes)

* Prerequisites
 * vagrant ( https://www.vagrantup.com/downloads.html )
 * libvirt (kvm) or virtualbox ( http://download.virtualbox.org/virtualbox/ )
   * install vagrant libvirt-plugin if needed (```vagrant plugin install --plugin-version=0.0.35 vagrant-libvirt```)

* Running tests
 * clone repo ( git clone https://github.com/NetworkManager/NetworkManager-ci.git )
 * go into NetworkManager-ci/run/fedora-vagrant directory
 * execute ./nmtest ( ```./nmtest -p libvirt -i centos/7 -f all -c master -t testbranch``` )

```
Usage: nmtest [options]

Options:
  -h, --help            show this help message and exit
  -w, --wizard          Use wizard mode.
  -d, --defaults        Use default mode. test ALL tests on MASTER branch
                        using vbenes/fedora-25-server on virtualbox
  -p PROVIDER, --provider=PROVIDER
                        VM provider (virtualbox, libvirt, vmware_fusion,
                        vmware_workstation, docker, hyperv)
  -i IMAGE, --image=IMAGE
                        VM provider box name. (e.g. vbenes/fedora-25-server)
  -f FEATURES, --features=FEATURES
                        Comma separated list of test areas. All or anything
                        from adsl,alias,bond,bridge,connection,dispatcher,ethe
                        rnet,general,ipv4,ipv6,libreswan,openvpn,ppp,pptp,team
                        ,tuntap,vlan,vpnc,nmtui
  -c CODEBRANCH, --codebranch=CODEBRANCH
                        NM code branch to be used for compilation.
  -t TESTBRANCH, --testbranch=TESTBRANCH
                        NM test branch to be used for execution.
  -Y, --YES             Answer yes to all question. Can be dangerous and
                        overwrite things!
```

* Results check
 * you will see execution progress as it goes ( tests do have 10m timeout to prevent lockup ) 
 * there is a summary at the end
 * detailed summary available at: http://localhost:8080/results/
 * vagrant ssh to log into environment to debug
 * vagrant destroy to remove the environment completely
