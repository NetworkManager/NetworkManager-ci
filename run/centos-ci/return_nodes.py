import subprocess
import os
import json
import time

if __name__ == "__main__":
    if os.path.isfile("session_id"):
        with open("session_id") as sid:
            for line in sid.readlines():
                id = line.strip("\n")
                duffy = (
                    "duffy client --url https://duffy.ci.centos.org/api/v1"
                    " --auth-name networkmanager --auth-key $CICO_API_KEY "
                )
                cmd = duffy + f" retire-session {id}"
                tick = 5
                while tick > 0:
                    output = subprocess.run(
                        cmd,
                        shell=True,
                        stdout=subprocess.PIPE,
                        check=False,
                        encoding='utf-8',
                    ).stdout
                    data = json.loads(output)
                    if "error" in data.keys():
                        time.sleep(10)
                        tick -= 1
                    if "session" in data.keys():
                        break
