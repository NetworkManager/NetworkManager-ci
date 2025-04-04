import sys
import time
import yaml
from nmstate.tests.integration.testlib.ipsec import IpsecTestEnv

print("env setup")

IpsecTestEnv.setup()

if len(sys.argv) > 1:
    env = sys.argv[1]

if env == "psk":
    IpsecTestEnv.start_ipsec_srv_psk_gw()
if env == "rsa":
    IpsecTestEnv.start_ipsec_srv_rsa_gw()
if env == "cert":
    IpsecTestEnv.start_ipsec_srv_cert_gw()
if env == "p2p":
    IpsecTestEnv.start_ipsec_srv_p2p()
if env == "site_site":
    IpsecTestEnv.start_ipsec_srv_site_to_site()
if env == "host_site":
    IpsecTestEnv.start_ipsec_srv_host_to_site()


IpsecTestEnv.load_both_srv_cli_keys()

# Save attributes to yaml
attributes = [
    "CLI_ADDR_V4",
    "SRV_ADDR_V4",
    "CLI_ADDR_V6",
    "SRV_ADDR_V6",
    "CLI_KEY_ID",
    "SRV_KEY_ID",
    "CLI_NIC",
    "PSK",
    "CLI_RSA",
    "SRV_RSA",
    "SRV_SUBNET_V4",
    "CLI_SUBNET_V4",
    "SRV_SUBNET_V6",
    "CLI_SUBNET_V6",
    "SRV_POOL_PREFIX_V4",
    "SRV_POOL_PREFIX_V6",
]

print(IpsecTestEnv)  # Debugging: check if object exists

data = {attr: getattr(IpsecTestEnv, attr) for attr in attributes}

with open("/tmp/ipsec_config.yaml", "w") as f:
    yaml.dump(data, f, default_flow_style=False)

# Let's wait for some time to settle things up.
time.sleep(1)
print("env ready")
input()  # this pauses and waits for ENTER key send by NM-ci after test finishes
print("env cleanup")
IpsecTestEnv.cleanup()
print("env exit")
