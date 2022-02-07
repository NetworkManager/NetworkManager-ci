import os
import subprocess
import sys

from . import util


class _Process:
    def run(self, argv, as_utf8=False, timeout=30):

        argv = [util.str_to_bytes(a) for a in argv]

        proc = subprocess.run(
            argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout
        )

        if proc.stderr:
            # if anything was printed to stderr, we consider that
            # a fail.
            raise Exception(
                "`%s` printed something on stderr: %s"
                % (
                    " ".join([util.bytes_to_str(s, errors="replace") for s in argv]),
                    proc.stderr.decode("utf-8", errors="replace"),
                )
            )

        if proc.returncode != 0:
            raise Exception(
                "`%s` returned exit code %s"
                % (
                    " ".join([util.bytes_to_str(s, errors="replace") for s in argv]),
                    proc.returncode,
                )
            )

        out = proc.stdout

        if as_utf8:
            out = out.decode("utf-8", errors="strict")

        return out


sys.modules[__name__] = _Process()
