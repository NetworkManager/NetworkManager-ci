import sys

from . import process


class _Git:
    def call_rev_parse(self, rev):
        r = process.run_check(["git", "rev-parse", rev])
        r = r.strip("\n")
        if not r:
            raise Exception(f"failure to parse {rev}")
        return r

    def config_get_origin_url(self):
        r = process.run_check(["git", "config", "--get", "remote.origin.url"])
        r = r.strip("\n")
        if r.endswith(".git"):
            r = r[:-4]
        if r.startswith("git@"):
            r = r.replace(":", "/").replace("git@", "https://")
        return r


sys.modules[__name__] = _Git()
