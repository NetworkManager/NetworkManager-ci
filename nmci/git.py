from functools import lru_cache

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _Git:
    # maxsize must be specified in python3.6
    @lru_cache(maxsize=32)
    def rev_parse(self, rev):
        """Return commit hash for given revision.
        This is cached, :code:`git` is called at most once per run.

        :param rev: git revision (e.g. 'HEAD', 'HEAD~7' or branch name)
        :type rev: str
        :raises Exception: If git command fails
        :return: commit hash
        :rtype: str
        """
        r = nmci.process.run_stdout(["git", "rev-parse", rev])
        r = r.strip("\n")
        if not r:
            raise Exception(f"failure to parse {rev}")
        return r

    # maxsize must be specified in python3.6
    @lru_cache(maxsize=32)
    def config_get_origin_url(self):
        """Return git origin URL, converted to HTTPS.
        This is cached, :code:`git` is called at most once per run.

        :return: git origin URL as HTTPS
        :rtype: str
        """
        r = nmci.process.run_stdout(["git", "config", "--get", "remote.origin.url"])
        r = r.strip("\n")
        if r.endswith(".git"):
            r = r[:-4]
        if r.startswith("git@"):
            r = r.replace(":", "/").replace("git@", "https://")
        return r


_module = _Git()
