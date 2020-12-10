#!/usr/bin/python
# author: Gris Ge <fge@redhat.com>
# https://bugzilla.redhat.com/show_bug.cgi?id=1689054

import gi  # pylint: disable=import-error
import time
from subprocess import check_output

gi.require_version("NM", "1.0")  # NOQA: F402
from gi.repository import Gio, GLib, NM  # pylint: disable=import-error

nmclient = NM.Client.new()

print(nmclient.props.dns_configuration)
