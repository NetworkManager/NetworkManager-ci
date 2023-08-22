# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
from behave import step
import os

import nmci


def http_put(url, data):
    if not isinstance(data, bytes):
        data = str(data)
    nmci.process.run_stdout(
        [
            "curl",
            "-s",
            "-X",
            "PUT",
            f"{nmci.nmutil.NMCI_MOCK_BASE_URL}/{url}",
            "--data",
            data,
        ]
    )


def http_put_aliyun(url, data):
    http_put(url, data)


def http_put_azure(url, data):
    http_put(url, data)


def http_put_ec2(url, data):
    http_put(url, data)


def http_put_gcp(url, data):
    http_put(url, data)


@step("Start test-cloud-meta-mock.py")
def start_test_cloud_meta_mock(context):
    nmci.cleanup.add_callback(
        [
            lambda: nmci.process.run_stdout(
                "systemctl reset-failed test-cloud-meta-mock.service"
            ),
            lambda: nmci.process.run_stdout(
                "systemctl stop test-cloud-meta-mock.service"
            ),
        ],
        name="stop:test-cloud-meta-mock",
    )
    nmci.process.run_stdout(
        [
            "systemd-run",
            "--remain-after-exit",
            "--unit=test-cloud-meta-mock",
            "systemd-socket-activate",
            "-l",
            str(nmci.nmutil.NMCS_MOCK_PORT),
            "python",
            nmci.util.base_dir("contrib/cloud/test-cloud-meta-mock.py"),
        ],
        ignore_stderr=True,
    )


@step(
    'Execute nm-cloud-setup for "{provider}" with mapped interfaces "{map_interfaces}"'
)
def execute_cloud_setup(context, provider, map_interfaces=None, background=False):

    provider = provider.lower()

    assert provider in nmci.nmutil.NMCS_PROVIDERS

    map_interfaces = nmci.misc.str_replace_dict(map_interfaces, context.noted)

    env = {
        "NM_CLOUD_SETUP_LOG": "trace",
        "NM_CLOUD_SETUP_MAP_INTERFACES": map_interfaces,
    }

    for p, info in nmci.nmutil.NMCS_PROVIDERS.items():

        required = p == provider

        # Randomly also enable other providers. Those shall not be
        # detected.
        enabled = required or nmci.util.random_bool(p + "/4220436421/1")

        # Randomly set a suitable MOCK URL
        r = nmci.util.random_int(p + "/4220436421/2", 0, 3)
        if required or r == 0:
            url = nmci.nmutil.NMCI_MOCK_BASE_URL
        elif enabled or r == 1:
            url = nmci.nmutil.NMCI_MOCK_BASE_URL_NOWHERE
        elif r == 2:
            url = ""
        else:
            url = None

        env[info["env_enable"]] = "yes" if enabled else "no"
        if url:
            env[info["env_mock"]] = url

    nmci.embed.embed_data("environment", str(env))

    http_put(".nmtest/providers", provider)

    if background:
        nmci.pexpect.pexpect_service(
            "/usr/libexec/nm-cloud-setup", label="child", env={**os.environ, **env}
        )
    else:
        context.process.run_stdout(
            "/usr/libexec/nm-cloud-setup",
            env_extra=env,
            timeout=120,
        )


@step(
    'Execute nm-cloud-setup for "{provider}" with mapped interfaces "{map_interfaces}" in background'
)
def execute_cloud_setup_in_bg(context, provider, map_interfaces=None, background=True):
    execute_cloud_setup(context, provider, map_interfaces, background)


def _resolve_mac(context, mac):
    if mac in context.noted:
        mac = context.noted[mac].strip()
    return nmci.ip.mac_norm(mac, force_len=6)


@step('Mock Aliyun metadata for device with MAC address "{mac}"')
def mock_aliyun_mac(context, mac):
    mac = _resolve_mac(context, mac)
    http_put_aliyun("2016-01-01/meta-data/network/interfaces/macs/", mac)


@step('Mock Aliyun metadata for devices with MAC addresses "{mac0}" and "{mac1}"')
def mock_aliyun_macs(context, mac0, mac1):
    mac0 = _resolve_mac(context, mac0)
    mac1 = _resolve_mac(context, mac1)
    http_put_aliyun(
        "2016-01-01/meta-data/network/interfaces/macs/",
        f"{mac0}\n{mac1}",
    )


@step(
    'Mock Aliyun IP address "{ip_addr}" with mask "{netmask}" for device with MAC address "{mac}"'
)
def mock_aliyun_ip(context, ip_addr, netmask, mac):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/private-ipv4s",
        ip_addr,
    )
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/primary-ip-address",
        ip_addr,
    )
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/netmask",
        netmask,
    )


@step(
    'Mock Aliyun IP addresses "{ip_addr1}" and "{ip_addr2}" with mask "{netmask}" for device with MAC address "{mac}"'
)
def mock_aliyun_ip(context, ip_addr1, ip_addr2, netmask, mac):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/private-ipv4s",
        f"{ip_addr1},{ip_addr2}",
    )
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/primary-ip-address",
        ip_addr1,
    )
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/netmask",
        netmask,
    )


@step('Mock Aliyun CIDR block "{cidr}" for device with MAC address "{mac}"')
def mock_aliyun_cidr(context, cidr, mac):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/vpc-cidr-block",
        cidr,
    )


@step('Mock Aliyun Gateway "{gw_addr}" for device with MAC address "{mac}"')
def mock_aliyun_ip(context, gw_addr, mac):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}/gateway",
        gw_addr,
    )


@step('Mock Azure metadata for device "{dev}" with MAC address "{mac}"')
def mock_azure_mac(context, dev, mac):
    mac = _resolve_mac(context, mac)
    http_put_azure(
        f"metadata/instance/network/interface/?format=text&api-version=2017-04-02",
        "0",
    )
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/macAddress?format=text&api-version=2017-04-02",
        mac,
    )


@step('Mock Azure IP address "{ip_addr}" with for device "{dev}"')
def mock_azure_ip(context, ip_addr, dev):
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/ipAddress/?format=text&api-version=2017-04-02",
        "0\n",
    )
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/ipAddress/0/privateIpAddress?format=text&api-version=2017-04-02",
        ip_addr,
    )


@step('Mock Azure IP addresses "{ip_addr1}" and "{ip_addr2}" with for device "{dev}"')
def mock_azure_ip(context, ip_addr1, ip_addr2, dev):
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/ipAddress/?format=text&api-version=2017-04-02",
        "0\n1\n",
    )
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/ipAddress/0/privateIpAddress?format=text&api-version=2017-04-02",
        ip_addr1,
    )
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/ipAddress/1/privateIpAddress?format=text&api-version=2017-04-02",
        ip_addr2,
    )


@step('Mock Azure subnet "{subnet}" with prefix "{prefix}" for device "{dev}"')
def mock_azure_cidr(context, subnet, prefix, dev):
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/subnet/0/address?format=text&api-version=2017-04-02",
        subnet,
    )
    http_put_azure(
        f"metadata/instance/network/interface/{dev}/ipv4/subnet/0/prefix?format=text&api-version=2017-04-02",
        prefix,
    )


@step('Mock EC2 metadata for device with MAC address "{mac}"')
def mock_ec2_mac(context, mac):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        "2018-09-24/meta-data/network/interfaces/macs/",
        mac,
    )


@step('Mock EC2 metadata for devices with MAC addresses "{macs}"')
def mock_ec2_macs(context, macs):
    splitter = " " if " " in macs else ","
    macs = "\n".join(_resolve_mac(context, mac) for mac in macs.split(splitter))
    http_put_ec2(
        "2018-09-24/meta-data/network/interfaces/macs/",
        f"{macs}",
    )


@step('Mock EC2 IP address "{ip_addr}" for device with MAC address "{mac}"')
def mock_ec2_ip(context, ip_addr, mac):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        f"2018-09-24/meta-data/network/interfaces/macs/{mac}/local-ipv4s",
        ip_addr,
    )


@step(
    'Mock EC2 IP addresses "{ip_addr1}" and "{ip_addr2}" for device with MAC address "{mac}"'
)
def mock_ec2_ip(context, ip_addr1, ip_addr2, mac):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        f"2018-09-24/meta-data/network/interfaces/macs/{mac}/local-ipv4s",
        f"{ip_addr1}\n{ip_addr2}",
    )


@step('Mock EC2 CIDR block "{cidr}" for device with MAC address "{mac}"')
def mock_ec2_cidr(context, cidr, mac):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        f"2018-09-24/meta-data/network/interfaces/macs/{mac}/subnet-ipv4-cidr-block",
        cidr,
    )


@step('Mock GCP metadata for device "{dev}" with MAC address "{mac}"')
def mock_gcp_mac(context, dev, mac):
    mac = _resolve_mac(context, mac)
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/",
        "0",
    )
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/mac",
        mac,
    )


@step('Mock GCP IP address "{ip_addr}" with for device "{dev}"')
def mock_gcp_ip(context, ip_addr, dev):
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/forwarded-ips/",
        "0",
    )
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/forwarded-ips/0",
        ip_addr,
    )


@step('Mock GCP IP addresses "{ip_addr1}" and "{ip_addr2}" with for device "{dev}"')
def mock_gcp_ip2(context, ip_addr1, ip_addr2, dev):
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/forwarded-ips/",
        "0\n1\n",
    )
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/forwarded-ips/0",
        ip_addr1,
    )
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{dev}/forwarded-ips/1",
        ip_addr2,
    )
