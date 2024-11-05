# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
from behave import step
import os
import json

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


def http_put_oci(url, data):
    http_put(url, data)


@step("Start test-cloud-meta-mock.py")
def start_test_cloud_meta_mock(context):
    nmci.pexpect.pexpect_service(
        " ".join(
            [
                "python",
                nmci.util.base_dir("contrib/cloud/test-cloud-meta-mock.py"),
                "--empty",
                f"{nmci.nmutil.NMCS_MOCK_PORT}",
            ]
        ),
        shell=True,
        env={"NM_TEST_CLOUD_SETUP_MOCK_DEBUG": "1"},
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


@step(
    'Mock Aliyun device with MAC "{mac}", IP "{ip_addr}", netmask "{netmask}", subnet "{cidr}" and gateway "{gw_addr}"'
)
def mock_aliyun_dev(context, mac, ip_addr, netmask, cidr, gw_addr):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}",
        json.dumps(
            {
                "private-ipv4s": ip_addr,
                "primary-ip-address": ip_addr,
                "netmask": netmask,
                "vpc-cidr-block": cidr,
                "gateway": gw_addr,
            }
        ),
    )


@step(
    'Mock Aliyun device with MAC "{mac}", IPs "{ip_addr1}" and "{ip_addr2}", netmask "{netmask}", subnet "{cidr}" and gateway "{gw_addr}"'
)
def mock_aliyun_dev(context, mac, ip_addr1, ip_addr2, netmask, cidr, gw_addr):
    mac = _resolve_mac(context, mac)
    http_put_aliyun(
        f"2016-01-01/meta-data/network/interfaces/macs/{mac}",
        json.dumps(
            {
                "private-ipv4s": f"{ip_addr1},{ip_addr2}",
                "primary-ip-address": ip_addr1,
                "netmask": netmask,
                "vpc-cidr-block": cidr,
                "gateway": gw_addr,
            }
        ),
    )


@step("Clean Aliyun mocks")
def mock_aliyun_clean(context):
    http_put_aliyun("2016-01-01/meta-data/network/interfaces/macs/", "{}")


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


@step(
    'Mock Azure device "{num}" with MAC "{mac}", IP "{ip_addr}" and subnet "{subnet}/{prefix}"'
)
def mock_azure_dev(context, num, mac, ip_addr, subnet, prefix):
    mac = _resolve_mac(context, mac)
    http_put_azure(
        f"metadata/instance/network/interface/{num}?format=text&api-version=2017-04-02",
        json.dumps(
            {
                "macAddress": mac,
                "ipv4": {
                    "ipAddress": [{"privateIpAddress": ip_addr}],
                    "subnet": [{"address": subnet, "prefix": prefix}],
                },
            }
        ),
    )


@step(
    'Mock Azure device "{num}" with MAC "{mac}", IPs "{ip_addr1}" and "{ip_addr2}" and subnet "{subnet}/{prefix}"'
)
def mock_azure_dev(context, num, mac, ip_addr1, ip_addr2, subnet, prefix):
    mac = _resolve_mac(context, mac)
    http_put_azure(
        f"metadata/instance/network/interface/{num}?format=text&api-version=2017-04-02",
        json.dumps(
            {
                "macAddress": mac,
                "ipv4": {
                    "ipAddress": [
                        {"privateIpAddress": ip_addr1},
                        {"privateIpAddress": ip_addr2},
                    ],
                    "subnet": [{"address": subnet, "prefix": prefix}],
                },
            }
        ),
    )
    # Delay the secondary address a bit to prevent fail due to possible race
    http_put(
        ".nmtest/delay",
        f'["metadata/instance/network/interface/{num}/ipv4/ipAddress/1/privateIpAddress"]',
    )


@step("Clean Azure mocks")
def mock_azure_clean(context):
    http_put_azure(
        "metadata/instance/network/interface?format=text&api-version=2017-04-02", "[]"
    )
    http_put(".nmtest/delay", "{}")


@step('Mock Azure MAC address "{mac}" for device "{num}"')
def mock_azure_mac(context, mac, num):
    mac = _resolve_mac(context, mac)
    http_put_azure(
        f"metadata/instance/network/interface/{num}/macAddress?format=text&api-version=2017-04-02",
        mac,
    )


@step('Mock Azure IP address "{ip_addr}" for device "{num}"')
def mock_azure_ip(context, ip_addr, num):
    http_put_azure(
        f"metadata/instance/network/interface/{num}/ipv4/ipAddress?format=text&api-version=2017-04-02",
        json.dumps([{"privateIpAddress": ip_addr}]),
    )


@step('Mock Azure IP addresses "{ip_addr1}" and "{ip_addr2}" for device "{num}"')
def mock_azure_ip(context, ip_addr1, ip_addr2, num):
    http_put_azure(
        f"metadata/instance/network/interface/{num}/ipv4/ipAddress?format=text&api-version=2017-04-02",
        json.dumps([{"privateIpAddress": ip_addr1}, {"privateIpAddress": ip_addr2}]),
    )
    # Delay the secondary address a bit to prevent fail due to possible race
    http_put(
        ".nmtest/delay",
        f'["metadata/instance/network/interface/{num}/ipv4/ipAddress/1/privateIpAddress"]',
    )


@step('Mock Azure forced delay on primary address for device "{num}"')
def mock_azure_delay_primary(context, num):
    http_put(
        ".nmtest/delay",
        f'["metadata/instance/network/interface/{num}/ipv4/ipAddress/0/privateIpAddress"]',
    )


@step('Mock Azure subnet "{subnet}" with prefix "{prefix}" for device "{num}"')
def mock_azure_cidr(context, subnet, prefix, num):
    http_put_azure(
        f"metadata/instance/network/interface/{num}/ipv4/subnet/?format=text&api-version=2017-04-02",
        json.dumps([{"address": subnet, "prefix": prefix}]),
    )


@step('Mock EC2 device with MAC "{mac}", IP "{ip_addr}" and subnet "{cidr}"')
def mock_ec2_dev(context, mac, ip_addr, cidr):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        f"2018-09-24/meta-data/network/interfaces/macs/{mac}",
        json.dumps(
            {
                "subnet-ipv4-cidr-block": cidr,
                "local-ipv4s": ip_addr,
            }
        ),
    )


@step(
    'Mock EC2 device with MAC "{mac}", IPs "{ip_addr1}" and "{ip_addr2}" and subnet "{cidr}"'
)
def mock_ec2_dev(context, mac, ip_addr1, ip_addr2, cidr):
    mac = _resolve_mac(context, mac)
    http_put_ec2(
        f"2018-09-24/meta-data/network/interfaces/macs/{mac}",
        json.dumps(
            {
                "subnet-ipv4-cidr-block": cidr,
                "local-ipv4s": f"{ip_addr1}\n{ip_addr2}",
            }
        ),
    )


@step("Clear EC2 mocks")
def mock_ec2_clear(context):
    http_put_ec2("2018-09-24/meta-data/network/interfaces/macs/", "{}")


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


@step('Mock GCP device "{num}" with MAC "{mac}" and IP "{ip_addr}"')
def mock_gcp_dev(context, num, mac, ip_addr):
    mac = _resolve_mac(context, mac)
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{num}",
        json.dumps(
            {
                "mac": mac,
                "forwarded-ips": [ip_addr],
            }
        ),
    )


@step('Mock GCP device "{num}" with MAC "{mac}" and IPs "{ip_addr1}" and "{ip_addr2}"')
def mock_gcp_dev(context, num, mac, ip_addr1, ip_addr2):
    mac = _resolve_mac(context, mac)
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{num}",
        json.dumps(
            {
                "mac": mac,
                "forwarded-ips": [ip_addr1, ip_addr2],
            }
        ),
    )


@step("Clean GCP mocks")
def mock_gcp_clean(context):
    http_put_gcp("computeMetadata/v1/instance/network-interfaces", "[]")


@step('Mock GCP MAC address "{mac}" for device "{num}"')
def mock_gcp_mac(context, mac, num):
    mac = _resolve_mac(context, mac)
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{num}/mac",
        mac,
    )


@step('Mock GCP IP address "{ip_addr}" for device "{num}"')
def mock_gcp_ip(context, ip_addr, num):
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{num}/forwarded-ips",
        json.dumps([ip_addr]),
    )


@step('Mock GCP IP addresses "{ip_addr1}" and "{ip_addr2}" for device "{num}"')
def mock_gcp_ip2(context, ip_addr1, ip_addr2, num):
    http_put_gcp(
        f"computeMetadata/v1/instance/network-interfaces/{num}/forwarded-ips",
        json.dumps([ip_addr1, ip_addr2]),
    )


@step(
    'Mock OCI device "{num}" with MAC "{mac}", IP "{ip_addr}", subnet "{cidr}" and gateway "{gw_addr}"'
)
def mock_oci_dev(context, num, mac, ip_addr, cidr, gw_addr):
    mac = _resolve_mac(context, mac)
    http_put_oci(
        f"opc/v2/vnics/{num}",
        json.dumps(
            {
                "vnicId": "example.id.X",
                "privateIp": ip_addr,
                "vlanTag": 1,
                "macAddr": mac,
                "virtualRouterIp": gw_addr,
                "subnetCidrBlock": cidr,
                "nicIndex": 0,
            }
        ),
    )


@step("Clear OCI mocks")
def mock_oci_clear(context):
    http_put_oci("opc/v2/vnics", "[]")


@step('Mock OCI MAC address "{mac}" for device "{num}"')
def mock_oci_mac(context, mac, num):
    mac = _resolve_mac(context, mac)
    http_put_oci(f"opc/v2/vnics/{num}/macAddr", mac)


@step('Mock OCI IP address "{ip_addr}" for device "{num}"')
def mock_oci_ip(context, ip_addr, num):
    http_put_oci(f"opc/v2/vnics/{num}/privateIp", ip_addr)


@step('Mock OCI CIDR block "{cidr}" for device "{num}"')
def mock_oci_cidr(context, cidr, num):
    http_put_oci(f"opc/v2/vnics/{num}/subnetCidrBlock", cidr)


@step('Mock OCI gateway address "{ip_addr}" for device "{num}"')
def mock_oci_gw(context, gw_addr, num):
    http_put_oci(f"opc/v2/vnics/{num}/virtualRouterIp", gw_addr)
