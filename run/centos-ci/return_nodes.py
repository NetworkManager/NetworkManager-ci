import subprocess
import os

if __name__ == "__main__":
    if os.path.isfile("machines"):
        with open("machines") as mf:
            for line in mf.readlines():
                ssid = line.strip("\n").split(":")[-1]
                if subprocess.call("cico node done " + ssid) != 0:
                    print("!!! Unable to return machine " + line)
