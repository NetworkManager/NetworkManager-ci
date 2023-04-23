# pylint: disable=no-name-in-module
from behave import step

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
def execute_cloud_setup(context, provider, map_interfaces=None):

    provider = provider.lower()

    assert provider in nmci.nmutil.NMCS_PROVIDERS

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

    context.process.run_stdout(
        "/usr/libexec/nm-cloud-setup",
        env_extra=env,
        timeout=120,
    )


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
