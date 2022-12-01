from functools import lru_cache

import nmci.process


class _Git:
    # maxsize must be specified in python3.6
    @lru_cache(maxsize=32)
    def rev_parse(self, rev):
        r = nmci.process.run_stdout(["git", "rev-parse", rev])
        r = r.strip("\n")
        if not r:
            raise Exception(f"failure to parse {rev}")
        return r

    # maxsize must be specified in python3.6
    @lru_cache(maxsize=32)
    def config_get_origin_url(self):
        r = nmci.process.run_stdout(["git", "config", "--get", "remote.origin.url"])
        r = r.strip("\n")
        if r.endswith(".git"):
            r = r[:-4]
        if r.startswith("git@"):
            r = r.replace(":", "/").replace("git@", "https://")
        return r
