import sys

from . import util


class _Git:
    def call_rev_parse(self, rev):
        r = util.process_run(["git", "rev-parse", rev], as_utf8=True)
        r = r.strip("\n")
        if not r:
            raise Exception(f"failure to parse {rev}")
        return r

    def config_get_origin_url(self):
        r = util.process_run(
            ["git", "config", "--get", "remote.origin.url"], as_utf8=True
        )
        r = r.strip("\n")
        if r.endswith(".git"):
            r = r[:-4]
        if r.startswith("git@"):
            r = r.replace(":", "/").replace("git@", "https://")
        return r


sys.modules[__name__] = _Git()
