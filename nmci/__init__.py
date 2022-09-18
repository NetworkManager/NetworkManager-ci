import sys

# import mnci submodules
# first import module class
# then assign it to variable (accessible after import nmci)
# change modules so imports works even within nmci
#
# the order of imports is important because of dependencies

# obsolete will be replaced by nmci.process
from nmci.run import *

# CEXT
from nmci.cext import _CExt

cext = _CExt()
sys.modules[f"{__name__}.cext"] = cext

# EMBED
import nmci.embed

EmbedData = nmci.embed.EmbedData
embed = nmci.embed._Embed()
sys.modules[f"{__name__}.embed"] = embed

# CLEANUP
import nmci.cleanup

Cleanup = nmci.cleanup.Cleanup

cleanup = nmci.cleanup._Cleanup()
sys.modules[f"{__name__}.cleanup"] = cleanup

# UTIL
import nmci.util as util

util = util._Util()
sys.modules[f"{__name__}.util"] = util

# PROCESS
# should be made class, to have imports uniform
import nmci.process as process

# PEXPECT
from nmci.pexpect import _PExpect

pexpect = _PExpect()
sys.modules[f"{__name__}.pexpect"] = pexpect

# DBUS
from nmci.dbus import _DBus

dbus = _DBus()
sys.modules[f"{__name__}.dbus"] = dbus

# SDRESOLVED
from nmci.sdresolved import _SDResolved

sdresolved = _SDResolved()
sys.modules[f"{__name__}.sdresolved"] = sdresolved

# IP
from nmci.ip import _IP

ip = _IP()
sys.modules[f"{__name__}.ip"] = ip

# GIT
from nmci.git import _Git

git = _Git()
sys.modules[f"{__name__}.git"] = git

# MISC
from nmci.misc import _Misc

misc = _Misc()
sys.modules[f"{__name__}.misc"] = misc

# NMUTIL
from nmci.nmutil import _NMUtil

nmutil = _NMUtil()
sys.modules[f"{__name__}.nmutil"] = nmutil

import nmci.ctx as ctx
import nmci.tags as tags
