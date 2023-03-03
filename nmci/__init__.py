import sys

# import mnci submodules
# first import module class
# then assign it to variable (accessible after import nmci)
# change modules so imports works even within nmci
#
# the order of imports is important because of dependencies

import nmci.run as run

# CEXT
import nmci.cext

cext = nmci.cext._module
sys.modules[f"{__name__}.cext"] = cext

# EMBED
import nmci.embed

EmbedData = nmci.embed.EmbedData
embed = nmci.embed._module
sys.modules[f"{__name__}.embed"] = embed

# CLEANUP
import nmci.cleanup as cleanup

Cleanup = cleanup.Cleanup
sys.modules[f"{__name__}.cleanup"] = cleanup

# UTIL
import nmci.util

util = nmci.util._module
sys.modules[f"{__name__}.util"] = util

# PROCESS
# should be made class, to have imports uniform
import nmci.process

process = nmci.process._module
sys.modules[f"{__name__}.process"] = process

# PEXPECT
import nmci.pexpect

pexpect = nmci.pexpect._module
sys.modules[f"{__name__}.pexpect"] = pexpect

# DBUS
import nmci.dbus

dbus = nmci.dbus._module
sys.modules[f"{__name__}.dbus"] = dbus

# SDRESOLVED
import nmci.sdresolved

sdresolved = nmci.sdresolved._module
sys.modules[f"{__name__}.sdresolved"] = sdresolved

# IP
import nmci.ip

ip = nmci.ip._module
sys.modules[f"{__name__}.ip"] = ip

# GIT
import nmci.git

git = nmci.git._module
sys.modules[f"{__name__}.git"] = git

# MISC
import nmci.misc

misc = nmci.misc._module
sys.modules[f"{__name__}.misc"] = misc

# NMUTIL
import nmci.nmutil

nmutil = nmci.nmutil._module
sys.modules[f"{__name__}.nmutil"] = nmutil

# VETH
import nmci.veth

veth = nmci.veth._module
sys.modules[f"{__name__}.veth"] = veth

import nmci.gsm as gsm
import nmci.prepare as prepare
import nmci.crash as crash
import nmci.tags as tags
