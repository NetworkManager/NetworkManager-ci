from nmstate.tests.integration.testlib.ipsec import IpsecTestEnv
import time

print("env setup")
with IpsecTestEnv() as env:
    print("env ready")
    time.sleep(3)
    print("env cleanup")

print("env exit")
