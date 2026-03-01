import sys

# import mnci submodules
# first import module class
# then assign it to variable (accessible after import nmci)
# change modules so imports works even within nmci
#
# the order of imports is important because of dependencies


def _setup_module(mod_name, mod_obj, instance):
    """Copy module metadata onto the instance replacing it in sys.modules.

    This makes help() work on the instance by providing __name__,
    __file__, __loader__, __package__, __spec__, and __path__ that
    pydoc uses to locate source code and display documentation.
    """
    for attr in ("__file__", "__loader__", "__spec__", "__package__", "__path__"):
        val = getattr(mod_obj, attr, None)
        if val is not None:
            try:
                setattr(instance, attr, val)
            except AttributeError:
                pass
    instance.__name__ = f"{__name__}.{mod_name}"
    sys.modules[f"{__name__}.{mod_name}"] = instance


import nmci.run as run

# CEXT
import nmci.cext

cext = nmci.cext._module
_setup_module("cext", nmci.cext, cext)

# EMBED
import nmci.embed

EmbedData = nmci.embed.EmbedData
embed = nmci.embed._module
_setup_module("embed", nmci.embed, embed)

# CLEANUP
import nmci.cleanup

cleanup = nmci.cleanup._module
Cleanup = cleanup.Cleanup
_setup_module("cleanup", nmci.cleanup, cleanup)

# UTIL
import nmci.util

util = nmci.util._module
_setup_module("util", nmci.util, util)

# PROCESS
# should be made class, to have imports uniform
import nmci.process

process = nmci.process._module
_setup_module("process", nmci.process, process)

# PEXPECT
import nmci.pexpect

pexpect = nmci.pexpect._module
_setup_module("pexpect", nmci.pexpect, pexpect)

# DBUS
import nmci.dbus

dbus = nmci.dbus._module
_setup_module("dbus", nmci.dbus, dbus)

# SDRESOLVED
import nmci.sdresolved

sdresolved = nmci.sdresolved._module
_setup_module("sdresolved", nmci.sdresolved, sdresolved)

# IP
import nmci.ip

ip = nmci.ip._module
_setup_module("ip", nmci.ip, ip)

# GIT
import nmci.git

git = nmci.git._module
_setup_module("git", nmci.git, git)

# MISC
import nmci.misc

misc = nmci.misc._module
_setup_module("misc", nmci.misc, misc)

# NMUTIL
import nmci.nmutil

nmutil = nmci.nmutil._module
_setup_module("nmutil", nmci.nmutil, nmutil)

# VETH
import nmci.veth

veth = nmci.veth._module
_setup_module("veth", nmci.veth, veth)

import nmci.gsm as gsm
import nmci.prepare as prepare
import nmci.crash as crash
import nmci.tags as tags
