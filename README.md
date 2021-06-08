# NetworkManager-ci
This repo contains a set of integration tests for NetworkManager and CentOS 8 Stream based VM test instructions


### Nightly status (CentOS CI)

| Code Branch | Build Status |
| ------------| ------------ |
| main | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-main/) |
| 1.30.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/) |
| 1.28.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-28/) |
| 1.26.x | [![Build Status](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-30/badge/icon)](https://jenkins-networkmanager.apps.ocp.ci.centos.org/job/NetworkManager-1-26/) |

### Howto execute basic test suite manually on localhost 

* Prerequisites
  * CentOS qcow2 image, running libvirtd
  ```
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
  ```
  # NMCI test code. NMCI master should work everywhere
  TEST_BRANCH='master'
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
  ```
  # NMCI test code. NMCI master should work everywhere
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
  ```
  cd /root/NetworkManager-ci
  # Test by test as defined in mapper.txt
  nmcli/./runtest.sh your_desired_test
  # Feature by feature as listed too in mapper.txt
  run/runfeature.sh your_desired_feature
  ```
* Results check
  * you will see execution progress as it goes ( tests do have 10m timeout to prevent lockup )
  * there is a summary at the end

