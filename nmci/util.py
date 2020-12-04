import os
import subprocess
import sys


class _Util:
    @property
    def GLib(self):

        m = getattr(self, "_GLib", None)
        if m is None:
            import gi
            from gi.repository import GLib

            m = GLib
            self._GLib = m
        return m

    @property
    def Gio(self):
        m = getattr(self, "_Gio", None)
        if m is None:
            import gi
            from gi.repository import Gio

            m = Gio
            self._Gio = m
        return m

    @property
    def NM(self):
        m = getattr(self, "_NM", None)
        if m is None:
            import gi

            gi.require_version("NM", "1.0")
            from gi.repository import NM

            m = NM
            self._NM = m
        return m

    @property
    def JsonGLib(self):
        m = getattr(self, "_JsonGLib", None)
        if m is None:
            import gi

            gi.require_version("Json", "1.0")
            from gi.repository import Json

            m = Json
            self._JsonGLib = m
        return m

    def _dir(self):
        return os.path.dirname(os.path.realpath(os.path.abspath(__file__)))

    def util_dir(self, *args):
        return os.path.join(self._dir(), *args)

    def base_dir(self, *args):
        d = os.path.realpath(os.path.join(self._dir(), ".."))
        return os.path.join(d, *args)

    def gvariant_to_dict(self, variant):
        import json

        JsonGLib = self.JsonGLib
        j = JsonGLib.gvariant_serialize(variant)
        return json.loads(JsonGLib.to_string(j, 0))

    def gvariant_type(self, s):

        if s is None:
            return None

        if isinstance(s, str):
            return self.GLib.VariantType(s)

        if isinstance(s, self.GLib.VariantType):
            return s

        raise ValueError("cannot get the GVariantType for %r" % (s))

    def process_run(self, argv, as_utf8=False, timeout=30):

        argv = list(argv)

        proc = subprocess.run(
            argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout
        )

        if proc.stderr:
            # if anything was printed to stderr, we consider that
            # a fail.
            raise Exception(
                "`%s` printed something on stderr: %s"
                % (" ".join(argv), proc.stderr.decode("utf-8", "replace"))
            )

        if proc.returncode != 0:
            raise Exception(
                "`%s` returned exit code %s" % (" ".join(argv), proc.returncode)
            )

        out = proc.stdout

        if as_utf8:
            out = out.decode("utf-8", errors="strict")

        return out


sys.modules[__name__] = _Util()
