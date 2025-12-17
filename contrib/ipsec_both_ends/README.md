# IPsec (Libreswan) test scripts

## Quick start

First, run the setup.sh script to create containers and set them up for IPsec. The topology is:

```
  +----------------+      +----------------+      +----------------+
  | 172.16.1.10/24 <------> 172.16.1.15/24 |      |                |
  |  fd01::10/64   |  n1  |  fd01::15/64   |      |                |
  |                |      |                |      |                |
  |  ipsec-host1   |      |  ipsec-router  |      |  ipsec-host2   |
  |                |      |                |      |                |
  |                |      | 172.16.2.15/24 <------> 172.16.2.20/24 |
  |                |      |  fd02::15/64   |  n2  |  fd02::20/64   |
  +----------------+      +----------------+      +----------------+
```

Then, run one of the tests with "./test.sh $name". A test is specified by a directory in tests/, which contains configurations for the 2 nodes and a script to check the result.

When running a tests, the following steps are done:

 - on both host1 and host2, the "cleanup" action is invoked, which clears existing configuration
 - on host2, the libreswan configuration is loaded
 - on host1, a NM connection is created by importing the libreswan configuration
 - on host1, the NM connection is activated
 - on both hosts, the "check" action is invoked to check if the VPN is functional

Some tests have the "cs-" prefix, indicating that they are
client/server tests, i.e. NetworkManager is used on both host1 and
host2.

To run all tests, use "./test.sh all".
