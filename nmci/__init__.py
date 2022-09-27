import sys

# import mnci submodules
# first import module class
# then assign it to variable (accessible after import nmci)
# change modules so imports works even within nmci
#
# the order of imports is important because of dependencies

# obsolete will be replaced by nmci.process
from nmci.run import *

import nmci.util as util

util = util._Util()
sys.modules[f"{__name__}.util"] = util

# should be made class, to have imports uniform
import nmci.process as process

from nmci.dbus import _DBus

dbus = _DBus()
sys.modules[f"{__name__}.dbus"] = dbus

from nmci.sdresolved import _SDResolved

sdresolved = _SDResolved()
sys.modules[f"{__name__}.sdresolved"] = sdresolved

from nmci.ip import _IP

ip = _IP()
sys.modules[f"{__name__}.ip"] = ip

from nmci.git import _Git

git = _Git()
sys.modules[f"{__name__}.git"] = git

from nmci.misc import _Misc

misc = _Misc()
sys.modules[f"{__name__}.misc"] = misc

from nmci.nmutil import _NMUtil

nmutil = _NMUtil()
sys.modules[f"{__name__}.nmutil"] = nmutil

import nmci.ctx as ctx

# cext alone should be separated from ctx
# it should have no other nmci dependencies,
# it should be imported fist
# and all nmci modules can use it
cext = ctx._CExt()
sys.modules[f"{__name__}.cext"] = cext

# this must be done after nmci.cext and nmci.ctx
import nmci.tags as tags
