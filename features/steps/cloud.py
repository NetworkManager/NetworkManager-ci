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
