from nmstate.tests.integration.testlib.ipsec import IpsecTestEnv
import time

print("env setup")
with IpsecTestEnv() as env:
    print("env ready")
    input()
    print("env cleanup")

print("env exit")
