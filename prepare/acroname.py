#!/usr/bin/python3
import optparse
import brainstem
import sys


def main():
    p = optparse.OptionParser()
    p.add_option("--port", type="int", dest="port", help="USB port number")
    p.add_option("--enable", action="store_true", dest="enable", help="Enable USB port")
    p.add_option(
        "--disable", action="store_true", dest="disable", help="Disable USB port"
    )
    p.add_option(
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
                    gotResult = True
                    break
            except (result != brainstem.result.Result.NO_ERROR):
                continue

        if gotResult:
            break

    # turn on the user led for a nice visual indicator that we're talking
    # to the USBHub3+
    stem.system.setLED(1)

    # do the user requested action and log any brainstem errors
    if options.enable == True:
        sys.stdout.write("Enabling Hub Port: %s" % options.port)
        result = stem.usb.setPortEnable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" failed with error %d" % result)
    elif options.disable == True:
        sys.stdout.write("Disable Hub Port: %s" % options.port)
        result = stem.usb.setPortDisable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" failed with error %d" % result)
    elif options.cycle == True:
        sys.stdout.write("Cycling Hub Port: %s" % options.port)
        sys.stdout.flush()

        result = stem.usb.setPortDisable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" disabling failed with error %d" % result)
        from time import sleep

        sleep(2)

        result = stem.usb.setPortEnable(options.port)
        if result != brainstem.result.Result.NO_ERROR:
            sys.stdout.write(" enabling failed with error %d" % result)
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
