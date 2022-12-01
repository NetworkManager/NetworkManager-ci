import re
import os
import time
import fcntl

import nmci


def reset_usb_devices():
    USBDEVFS_RESET = 21780

    def getfile(dirname, filename):
        f = open("%s/%s" % (dirname, filename), "r")
        contents = f.read().encode("utf-8")
        f.close()
        return contents

    USB_DEV_DIR = "/sys/bus/usb/devices"
    dirs = os.listdir(USB_DEV_DIR)
    for d in dirs:
        # Skip interfaces, we only care about devices
        if d.count(":") >= 0:
            continue

        busnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "busnum"))
        devnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "devnum"))
        f = open("/dev/bus/usb/%03d/%03d" % (busnum, devnum), "w", os.O_WRONLY)
        try:
            fcntl.ioctl(f, USBDEVFS_RESET, 0)
        except Exception as msg:
            print(("failed to reset device:", msg))
        f.close()


def reinitialize_devices():
    if (
        nmci.process.systemctl(
            "is-active ModemManager", embed_combine_tag=nmci.embed.NO_EMBED
        ).returncode
        != 0
    ):
        nmci.process.systemctl(
            "restart ModemManager", embed_combine_tag=nmci.embed.NO_EMBED
        )
        timer = 40
        while "gsm" not in nmci.process.nmcli(
            "device", embed_combine_tag=nmci.embed.NO_EMBED
        ):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                break
    if "gsm" not in nmci.process.nmcli("device", embed_combine_tag=nmci.embed.NO_EMBED):
        print("reinitialize devices")
        reset_usb_devices()
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done",
            shell=True,
            embed_combine_tag=nmci.embed.NO_EMBED,
        )
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done",
            shell=True,
            embed_combine_tag=nmci.embed.NO_EMBED,
        )
        nmci.process.systemctl(
            "restart ModemManager", embed_combine_tag=nmci.embed.NO_EMBED
        )
        timer = 80
        while "gsm" not in nmci.process.nmcli(
            "device", embed_combine_tag=nmci.embed.NO_EMBED
        ):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                assert False, "Cannot initialize modem"
        time.sleep(60)
    return True


def find_modem(context):
    """
    Find the 1st modem connected to a USB port or USB hub on a testing machine.
    :return: None/a string of detected modem specified in a dictionary.
    """
    # When to extract information about a modem?
    # - When the modem is initialized.
    # - When it is available in the output of 'mmcli -L'.
    # - When the device has type of 'gsm' in the output of 'nmcli dev'.

    modem_dict = {
        "413c:8118": "Dell Wireless 5510",
        "413c:81b6": "Dell Wireless EM7455",
        "0bdb:190d": "Ericsson F5521 gw",
        "0bdb:1926": "Ericsson H5321 gw",
        "0bdb:193e": "Ericsson N5321",
        "05c6:6000": "HSDPA USB Stick",
        "12d1:1001": "Huawei E1550",
        "12d1:1436": "Huawei E173",
        "12d1:1446": "Huawei E173",
        "12d1:1003": "Huawei E220",
        "12d1:1506": "Huawei E3276",
        "12d1:1465": "Huawei K3765",
        "0421:0637": "Nokia 21M-02",
        "1410:b001": "Novatel Ovation MC551",
        "0b3c:f000": "Olicard 200",
        "0b3c:c005": "Olivetti Techcenter",
        "0af0:d033": "Option GlobeTrotter Icon322",
        "04e8:6601": "Samsung SGH-Z810",
        "1199:9051": "Sierra Wireless AirCard 340U",
        "1199:68c0": "Sierra Wireless MC7608",
        "1199:a001": "Sierra Wireless EM7345",
        "1199:9041": "Sierra Wireless EM7355",
        "413c:81a4": "Sierra Wireless EM8805",
        "1199:9071": "Sierra Wireless MC7455",
        "1199:68a2": "Sierra Wireless MC7710",
        "03f0:371d": "Sierra Wireless MC8355",
        "1199:68a3": "Sierra Wireless USB 306",
        "1c9e:9603": "Zoom 4595",
        "19d2:0117": "ZTE MF190",
        "19d2:2000": "ZTE MF627",
    }

    output = nmci.process.run_stdout("lsusb")
    output = output.splitlines()

    if output:
        for line in output:
            for key, value in modem_dict.items():
                if line.find(str(key)) > 0:
                    return f"USB ID {key} {value}"

    return "USB ID 0000:0000 Modem Not in List"


def get_modem_info(context):
    """
    Get a list of connected modem via command 'mmcli -L'.
    Extract the index of the 1st modem.
    Get info about the modem via command 'mmcli -m $i'
    Find its SIM card. This optional for this function.
    Get info about the SIM card via command 'mmcli --sim $i'.
    :return: None/A string containing modem information.
    """
    output = modem_index = modem_info = sim_index = sim_info = None

    # Get a list of modems from ModemManager.
    code, output, _ = nmci.process.run("mmcli -L")
    if code != 0:
        print("Cannot get modem info from ModemManager.")
        return None

    regex = r"/org/freedesktop/ModemManager1/Modem/(\d+)"
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        code, modem_info, _ = nmci.process.run(f"mmcli -m {modem_index}")
        if code != 0:
            print(f"Cannot get modem info at index {modem_index}.")
            return None
    else:
        return None

    # Get SIM card info from modem_info.
    regex = r"/org/freedesktop/ModemManager1/SIM/(\d+)"
    mo = re.search(regex, modem_info)
    if mo:
        # Get SIM card info from ModemManager.
        sim_index = mo.groups()[0]
        code, sim_info, _ = nmci.process.run(f"mmcli --sim {sim_index}")
        if code != 0:
            print(f"Cannot get SIM card info at index {sim_index}.")

    if sim_info:
        return f"MODEM INFO\n{modem_info}\nSIM CARD INFO\n{sim_info}"
    else:
        return modem_info
