#!/usr/bin/python3l
import optparse
import brainstem
import sys

USB2_BIT_MASK = 0x800
USB3_BIT_MASK = 0x1000
DEVICE_BIT_MASK = 0x800000


def main():
    p = optparse.OptionParser()
    p.add_option(
        "-s", "--status", action="store_true", dest="status", help="Show USB HUB status"
    )
    p.add_option("-p", "--port", type="int", dest="port", help="USB port number")
    p.add_option(
        "-e", "--enable", action="store_true", dest="enable", help="Enable USB port"
    )
    p.add_option(
        "-d", "--disable", action="store_true", dest="disable", help="Disable USB port"
    )
    p.add_option(
        "-c",
        "--cycle",
        action="store_true",
        dest="cycle",
        help="Disables then Enables USB port",
    )

    options, arguments = p.parse_args()

    # connect to the USBHub3+
    stem = brainstem.stem.USBHub3p()

    # retry connecting to hub
    for i in range(0, 100):
        gotResult = False
        while not gotResult:
            try:
                result = stem.discoverAndConnect(brainstem.link.Spec.USB)
                if result == brainstem.result.Result.NO_ERROR:
                    result = stem.system.getSerialNumber()
                    print(
                        "Connected to USBHub3+ with serial number: 0x%08X"
                        % result.value
                    )
                    gotResult = True
                    break
            except result != brainstem.result.Result.NO_ERROR:
                continue
        if gotResult:
            break

    # turn on the user led for a nice visual indicator that we're talking
    # to the USBHub3+
    stem.system.setLED(1)

    # do the user requested action and log any brainstem errors
    if options.enable == True:
        sys.stdout.write("Enabling Hub Port: %s" % options.port)
        # result = stem.usb.setPowerEnable(options.port)
        result = stem.usb.setPortEnable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" failed with error %d" % result)
    elif options.disable == True:
        sys.stdout.write("Disable Hub Port: %s" % options.port)
        # result = stem.usb.setPowerDisable(options.port)
        result = stem.usb.setPortDisable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" failed with error %d" % result)
    elif options.cycle == True:
        sys.stdout.write("Cycling Hub Port: %s" % options.port)
        sys.stdout.flush()
        # result = stem.usb.setPowerDisable(options.port)
        result = stem.usb.setPortDisable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" disabling failed with error %d" % result)
        from time import sleep

        sleep(2)
        # result = stem.usb.setPowerEnable(options.port)
        result = stem.usb.setPortEnable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" enabling failed with error %d" % result)
    elif options.status == True:
        print("Getting state for all ports:\n")
        for port in range(0, 8):
            port_state_raw = stem.usb.getPortState(port)
            port_state = port_state_raw.value
            print(f"port {port} state is: {hex(port_state)}")
            device_attached = bool((port_state & DEVICE_BIT_MASK) >> 23)
            usb2_device_attached = bool((port_state & USB2_BIT_MASK) >> 11)
            usb3_device_attached = bool((port_state & USB3_BIT_MASK) >> 12)
            print("Device attached on port %d: %s" % (port, device_attached))
            print("USB2 device attached on port %d: %s" % (port, usb2_device_attached))
            print("USB3 device attached on port %d: %s" % (port, usb3_device_attached))
    else:
        print(
            "You must specify a port state with the --enable, --disable, or --cycle option"
        )

    # clear out any stdout buffer and make a new line

    sys.stdout.flush()
    print("")

    # turn off the user led to show we're done
    stem.system.setLED(0)
    stem.disconnect()


if __name__ == "__main__":
    main()
