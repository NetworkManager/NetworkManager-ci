# pylint: disable=unused-argument,line-too-long
import time
from behave import step  # pylint: disable=no-name-in-module
import nmci


@step('Add "{vpn}" VPN connection named "{name}" for device "{ifname}"')
def add_vpnc_connection_for_iface(context, name, ifname, vpn):
    nmci.cleanup.add_connection(name)
    command = (
        f'connection add con-name "{name}" type vpn ifname {ifname} vpn-type {vpn}'
    )
    nmci.process.nmcli(command)


@step(
    'Use certificate "{cert}" with key "{key}" and authority "{ca_file}" for gateway "{gateway}" on OpenVPN connection "{name}"'
)
def set_openvpn_connection(context, cert, key, ca_file, gateway, name):
    cert_path = nmci.util.base_dir("contrib/openvpn/")

    vpn_data = {
        "tunnel-mtu": "1400",
        "key": cert_path + key,
        "connection-type": "tls",
        "ca": cert_path + ca_file,
        "cert": cert_path + cert,
        "remote": gateway,
        "cert-pass-flags": "0",
    }

    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str}")


@step(
    'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on Libreswan connection "{name}"'
)
@step(
    'Use certificate "{cert}" for gateway "{gateway}" on Libreswan connection "{name}"'
)
@step(
    'Use certificate "{cert}" with ID "{leftid}" for gateway "{gateway}" on Libreswan connection "{name}"'
)
def set_libreswan_connection(
    context,
    gateway,
    name,
    user=None,
    password="ask",
    group="Main",
    secret="ask",
    cert=None,
    leftid=None,
):

    username_option = "leftxauthusername"
    libver = [
        int(x)
        for x in nmci.process.run_stdout(
            "rpm -q libreswan | grep -o [0-9]*", shell=True
        )
        .strip()
        .split("\n")
    ]

    NM_libver = [
        int(x)
        for x in nmci.process.run_stdout(
            "rpm -q NetworkManager-libreswan | grep -o [0-9]*", shell=True
        )
        .strip()
        .split("\n")
    ]

    if context.rh_release_num[0] != 8:
        if libver[0] >= 4:
            username_option = "leftusername"

    vpn_data = {"right": gateway}

    if user is not None:
        vpn_data = {
            **vpn_data,
            username_option: user,
            "xauthpasswordinputmodes": "ask" if password == "ask" else "save",
            "xauthpassword-flags": "2" if password == "ask" else "0",
            "pskinputmodes": "ask" if secret == "ask" else "save",
            "pskvalue-flags": "2" if secret == "ask" else "0",
            "vendor": "Cisco",
        }

    if cert is not None:
        if leftid is None:
            leftid = "%fromcert"
        vpn_data = {
            **vpn_data,
            "ikev2": "insist",
            "leftcert": cert,
            "leftid": leftid,
        }

    if libver[0] >= 5:
        if NM_libver >= [1, 2, 27] and libver <= [5, 2, 1000]:
            vpn_data["nm-auto-defaults"] = "no"
            vpn_data["left"] = "%defaultroute"
            vpn_data["leftmodecfgclient"] = "yes"
            vpn_data["rightmodecfgserver"] = "yes"
            vpn_data["modecfgpull"] = "yes"
            vpn_data["rekey"] = "yes"
            vpn_data["rightsubnet"] = "0.0.0.0/0"
        else:
            vpn_data["ike"] = "AES_CBC"
            vpn_data["esp"] = "AES_GCM"

    if group != "Main":
        vpn_data["leftid"] = group

    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {}
    if password != "ask":
        vpn_secrets["xauthpassword"] = password
    if secret != "ask":
        vpn_secrets["pskvalue"] = secret

    vpn_secrets_str = ""
    if vpn_secrets:
        vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with secret "{secret}" for gateway "{gateway}" on Strongswan connection "{name}"'
)
def set_strongswan_connection(context, user, secret, gateway, name):
    vpn_data = {
        "user": user,
        "address": gateway,
        "method": "psk",
        "virtual": "yes",
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "password": secret,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with password "{password}" and group "{group}" with secret "{secret}" for gateway "{gateway}" on VPNC connection "{name}"'
)
def set_vpnc_connection(context, user, password, group, secret, gateway, name):
    vpn_data = {
        "NAT Traversal Mode": "natt",
        "ipsec-secret-type": "save",
        "IPSec secret-flags": "0",
        "xauth-password-type": "save",
        "Vendor": "cisco",
        "Xauth username": user,
        "IPSec gateway": gateway,
        "Xauth password-flags": "0",
        "IPSec ID": group,
        "Perfect Forward Secrecy": "server",
        "IKE DH Group": "dh2",
        "Local Port": "0",
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "IPSec secret": secret,
        "Xauth password": password,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step(
    'Use user "{user}" with password "{password}" and MPPE set to "{mppe}" for gateway "{gateway}" on PPTP connection "{name}"'
)
def set_pptp_connection(context, user, password, mppe, gateway, name):
    vpn_data = {
        "password-flags": "2" if password == "file" else "0",
        "user": user,
        "require-mppe-128": mppe,
        "gateway": gateway,
    }
    vpn_data_str = f"vpn.data '{nmci.misc.format_dict(vpn_data)}'"

    vpn_secrets = {
        "password": password,
    }
    vpn_secrets_str = f"vpn.secrets '{nmci.misc.format_dict(vpn_secrets)}'"

    nmci.process.nmcli(f"con modify {name} {vpn_data_str} {vpn_secrets_str}")


@step('Connect to vpn "{vpn}" with password "{password}"')
@step('Connect to vpn "{vpn}" with password "{password}" after "{time_out}" seconds')
@step('Connect to vpn "{vpn}" with password "{password}" and secret "{secret}"')
def connect_to_vpn(context, vpn, password, secret=None, time_out=0):
    cli = nmci.pexpect.pexpect_spawn(f"nmcli -a connect up {vpn}", timeout=180)
    time.sleep(int(time_out))
    cli.expect("Password.*:")
    cli.sendline(password)
    if secret is not None:
        cli.expect("Group (p|P)assword.*:")
        cli.sendline(secret)
    if nmci.process.systemctl("-q is-active polkit").returncode == 0:
        ret = cli.expect(["Error", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF])
        assert (
            ret != 0
        ), f"Got an Error while connecting to network {vpn}\n{cli.after}{cli.buffer}"
        assert ret != 1, "nmcli vpn connect ... timed out (180s)"
    else:
        # Remove me when 1756441 is fixed
        ret = cli.expect(["Connection successfully activated", nmci.pexpect.TIMEOUT])
        assert (
            ret == 0
        ), f"Got an Error while connecting to network {vpn}\n{cli.after}{cli.buffer}"


@step('Download NM-libreswan package to "{target_dir}"')
def download_nm_libreswan_package(context, target_dir):
    """
    Download NetworkManager-libreswan package to specified directory.

    Tries two methods in order:
    1. Use dnf download with exact package version
    2. Fallback to koji_links.sh script for downloading from koji

    Args:
        target_dir: Directory where package should be downloaded
    """
    # Create target directory if not exists
    nmci.process.run(f"mkdir -p {target_dir}", shell=True)

    # 1. Try dnf download first
    libreswan_version = nmci.process.run_stdout(
        "rpm -q NetworkManager-libreswan 2>/dev/null || echo 'not-installed'",
        shell=True,
    ).strip()
    if libreswan_version != "not-installed":
        print("Using dnf download for NetworkManager-libreswan package")
        # Remove architecture suffix for dnf download
        pkg_name = (
            libreswan_version.rsplit(".", 1)[0]
            if "." in libreswan_version
            else libreswan_version
        )
        exitcode = nmci.process.run_code(
            f"cd {target_dir} && dnf download --exclude='*.src' {pkg_name}",
            shell=True,
            ignore_returncode=True,
            ignore_stderr=True,
        )
        if exitcode == 0:
            return

        print("dnf download failed, switching to koji_links")

    # 2. Fallback to koji_links.sh using NetworkManager-libreswan version
    distro_info = nmci.process.run_stdout("cat /etc/os-release", shell=True)
    is_fedora = "Fedora" in distro_info
    script_name = "koji_links.sh" if is_fedora else "brew_links.sh"

    # Get NetworkManager-libreswan version info (package is guaranteed to be installed)
    nm_libreswan_info = nmci.process.run_stdout(
        "rpm -q NetworkManager-libreswan --queryformat '%{VERSION} %{RELEASE}'",
        shell=True,
    ).strip()
    version, release = nm_libreswan_info.split()

    script_path = nmci.util.base_dir(f"contrib/utils/{script_name}")
    download_urls = nmci.process.run_stdout(
        f"{script_path} NetworkManager-libreswan {version} {release}",
        shell=True,
        timeout=15,
        ignore_returncode=True,
        ignore_stderr=True,
    ).strip()
    for url in download_urls.split("\n"):
        if (
            "NetworkManager-libreswan" in url
            and f"NetworkManager-libreswan-{version}-" in url
            and not url.endswith(".src.rpm")
        ):
            nmci.process.run(
                f"wget -q --no-clobber -P {target_dir} {url}",
                shell=True,
                ignore_returncode=True,
            )
            break


@step('Setup the same distro type container with rpms from "{rpm_dir}"')
def run_container_setup(context, rpm_dir):
    """
    Set up containerized IPsec test environment with custom RPM packages.

    Determines the appropriate container distribution based on the host system
    and runs the setup script with the specified RPM directory for package installation.

    Supports RHEL (uses CentOS Stream), Fedora, and fallback to CentOS Stream 9.

    Args:
        rpm_dir: Directory containing RPM packages to install in containers
    """
    # Determine distribution based on system
    distro_info = nmci.process.run_stdout("cat /etc/os-release", shell=True)

    if "Red Hat Enterprise Linux" in distro_info or "rhel" in distro_info:
        # Extract RHEL version number
        import re

        match = re.search(r'VERSION_ID="?(\d+)', distro_info)
        if match:
            version = int(match.group(1))
            if version >= 10:
                distro = "centos:stream10"
            else:
                distro = "centos:stream9"
        else:
            distro = "centos:stream9"  # fallback
    elif "Fedora" in distro_info:
        if "Rawhide" in distro_info:
            distro = "fedora:rawhide"
        else:
            # Extract Fedora version number
            import re

            match = re.search(r"VERSION_ID=(\d+)", distro_info)
            if match:
                distro = f"fedora:{match.group(1)}"
            else:
                distro = "fedora:rawhide"  # fallback
    else:
        distro = "centos:stream9"  # fallback

    print(f"Using distribution: {distro}")

    # Run setup script
    setup_script = nmci.util.base_dir("contrib/ipsec_both_ends/setup.sh")
    setup_dir = nmci.util.base_dir("contrib/ipsec_both_ends")
    cmd = f"cd {setup_dir} && ./setup.sh --distro {distro} --rpm-dir {rpm_dir}"

    print(f"Running: {cmd}")
    nmci.process.run(cmd, shell=True, timeout=600, ignore_stderr=True)  # 10 min timeout


@step('Run test "{test_name}"')
def run_ipsec_test(context, test_name):
    """
    Execute IPsec test in the containerized environment.

    Runs the specified test script and verifies successful completion
    by checking for exit code 0.

    Args:
        test_name: Name of the test to run (e.g., 'cs-host4', 'cs-subnet6-routed')

    Raises:
        AssertionError: If test fails (non-zero exit code)
    """
    test_dir = nmci.util.base_dir("contrib/ipsec_both_ends")
    cmd = f"cd {test_dir} && ./test.sh {test_name}"
    expected_output = f"Test '{test_name}' succeeded"

    print(f"Running: {cmd}")
    result = nmci.process.run(cmd, shell=True, timeout=300, ignore_stderr=True)

    if result.returncode != 0:
        raise AssertionError(f"Test failed: exit={result.returncode}")

    if expected_output not in result.stdout:
        raise AssertionError(
            f"Test failed: expected '{expected_output}' not found in output"
        )
