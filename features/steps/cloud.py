# pylint: disable=no-name-in-module
from behave import step

import nmci


@step('Mock Aliyun metadata for device with MAC address "{mac}"')
def aliyun_mac(context, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/ --data '{mac_addr}'"
    )


@step('Mock Aliyun metadata for devices with MAC addresses "{mac0}" and "{mac1}"')
def aliyun_macs(context, mac0, mac1):
    mac_addr0 = context.noted[mac0].strip()
    mac_addr1 = context.noted[mac1].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/ --data '{mac_addr0}\n{mac_addr1}'"
    )


@step(
    'Mock Aliyun IP address "{ip_addr}" with mask "{netmask}" for device with MAC address "{mac}"'
)
def aliyun_ip(context, ip_addr, netmask, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/private-ipv4s --data '{ip_addr}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/primary-ip-address --data '{ip_addr}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/netmask --data '{netmask}'"
    )


@step(
    'Mock Aliyun IP addresses "{ip_addr1}" and "{ip_addr2}" with mask "{netmask}" for device with MAC address "{mac}"'
)
def aliyun_ip(context, ip_addr1, ip_addr2, netmask, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/private-ipv4s --data '{ip_addr1},{ip_addr2}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/primary-ip-address --data '{ip_addr1}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/netmask --data '{netmask}'"
    )


@step('Mock Aliyun CIDR block "{cidr}" for device with MAC address "{mac}"')
def aliyun_cidr(context, cidr, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/vpc-cidr-block --data '{cidr}'"
    )


@step('Mock Aliyun Gateway "{gw_addr}" for device with MAC address "{mac}"')
def aliyun_ip(context, gw_addr, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT http://localhost/2016-01-01/meta-data/network/interfaces/macs/{mac_addr}/gateway --data '{gw_addr}'"
    )


@step('Mock Azure metadata for device "{dev}" with MAC address "{mac}"')
def azure_mac(context, dev, mac):
    mac_addr = context.noted[mac].strip()
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/?format=text&api-version=2017-04-02' --data '0'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/macAddress?format=text&api-version=2017-04-02' --data '{mac_addr}'"
    )


@step('Mock Azure IP address "{ip_addr}" with for device "{dev}"')
def azure_ip(context, ip_addr, dev):
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/ipAddress/?format=text&api-version=2017-04-02' --data '0\n'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/ipAddress/0/privateIpAddress?format=text&api-version=2017-04-02' --data '{ip_addr}'"
    )


@step('Mock Azure IP addresses "{ip_addr1}" and "{ip_addr2}" with for device "{dev}"')
def azure_ip(context, ip_addr1, ip_addr2, dev):
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/ipAddress/?format=text&api-version=2017-04-02' --data '0\n1\n'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/ipAddress/0/privateIpAddress?format=text&api-version=2017-04-02' --data '{ip_addr1}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/ipAddress/1/privateIpAddress?format=text&api-version=2017-04-02' --data '{ip_addr2}'"
    )


@step('Mock Azure subnet "{subnet}" with prefix "{prefix}" for device "{dev}"')
def azure_cidr(context, subnet, prefix, dev):
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/subnet/0/address?format=text&api-version=2017-04-02' --data '{subnet}'"
    )
    nmci.process.run_stdout(
        f"curl -s -X PUT 'http://localhost/metadata/instance/network/interface/{dev}/ipv4/subnet/0/prefix?format=text&api-version=2017-04-02' --data '{prefix}'"
    )
