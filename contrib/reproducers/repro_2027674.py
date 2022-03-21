#!/usr/bin/python3

import os

os.environ["G_DEBUG"] = "fatal-warnings"

import sys
import random
import gi

gi.require_version("NM", "1.0")
from gi.repository import GLib, Gio, GObject, NM

dbus_connection = Gio.bus_get_sync(Gio.BusType.SYSTEM)

for i in range(1, 300):

    use_plain_object = random.random() < 0.5
    use_prepared_dbus_connection = use_plain_object and (random.random() < 0.5)

    if True:
        # Without patch https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/commit/ae0cc9618c49bb74bbe54a073dc337e9a3b0005b
        # we will hit an assertion. Avoid that, by uncommenting the following line.
        #
        # If you do that, then the reproducer script cannot hit the bug fixed by
        # https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/commit/a9d521bf8c183b9bb95375545ac514de170e3484

        # use_prepared_dbus_connection = False
        pass

    print("")
    print(
        f"run {i} (use-plain-object:{use_plain_object}, use-prepared-dbus-connection={use_prepared_dbus_connection})"
    )

    context = GLib.MainContext.default()

    cancellable = Gio.Cancellable()

    ready = []

    if random.random() < 0.1:
        print(">>> cancel early!")
        cancellable.cancel()

    def cb(nmc, res):
        try:
            if use_plain_object:
                if not nmc.init_finish(res):
                    assert False
                nmc2 = nmc
            else:
                nmc2 = NM.Client.new_finish(res)
        except Exception as e:
            print(f">>> new: failed ({e})")
            nmc2 = None
        except:
            print(f">>> new: abort")
            sys.exit(0)
        else:
            assert nmc == nmc2
            print(f">>> new: success ({nmc})")

        ready.append(nmc2)

    if use_plain_object:
        if use_prepared_dbus_connection:
            nmc = GObject.new(NM.Client, dbus_connection=dbus_connection)
        else:
            nmc = NM.Client()
        nmc.init_async(GLib.PRIORITY_DEFAULT, cancellable, cb)
    else:
        NM.Client.new_async(cancellable, cb)
        nmc = None

    j = 0
    while not ready:
        j += 1
        print(f">>> iterate ({j})")

        if random.random() < 0.1:
            print(">>> cancel!")
            cancellable.cancel()
        context.iteration()

    if ready == [None]:
        print(f">>> creation failed")
    elif use_plain_object:
        assert ready == [nmc]

print(f"done")
