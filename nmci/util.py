import collections
import os
import re
import subprocess
import sys
import time


class _Timeout:
    def __init__(self, timeout):
        if isinstance(timeout, str):
            # for convenience, allow timeout as string. We often get the timeout
            # from behave steps, they are strings there...
            timeout = float(timeout)
        now = time.monotonic()
        self._loop_sleep_called = False
        self._expired_called = False
        self.start_timestamp = now
        if timeout is None:
            self._expiry = None
            self._is_expired = False
        else:
            self._expiry = now + timeout
            self._is_expired = timeout <= 0

    def ticking_duraction(self):
        return time.monotonic() - self.start_timestamp

    def _expired(self, now):
        self._expired_called = True
        if self._is_expired:
            return True
        if self._expiry is None or now < self._expiry:
            return False
        self._is_expired = True
        return True

    def expired(self):
        return self._expired(now=time.monotonic())

    @property
    def was_expired(self):
        # This returns True, iff self.expired() ever returned True.
        # Unlike self.expired(), it does not re-evaluate the expiration
        # based on the current timestamp.
        #
        # For that reason, it is a @property and not a function. Because,
        # the result does not change if called twice in a row (without calling
        # self.expired() in between).
        return self._expired_called and self._is_expired

    def sleep(self, sleep_time):
        # sleep "sleep_time" or until the expiry (whatever
        # comes first).
        #
        # Returns False if self was already expired when calling and
        # no sleeping was done. Otherwise, we slept some time and return
        # True.
        now = time.monotonic()
        if self._expired(now):
            return False
        if self._expiry is None:
            sleep_time = sleep_time
        else:
            sleep_time = min(sleep_time, (self._expiry - now))
        time.sleep(sleep_time)
        return True

    def loop_sleep(self, sleep_time):
        # The very first call to sleep does not actually sleep. It
        # Always returns True and does nothing.
        #
        # The idea is that when used with a while loop, that the
        # loop gets run at least once:
        #
        #     timeout = nmci.util.start_timeout(0)
        #     while timeout.sleep(1):
        #         hi_there()
        if not self._loop_sleep_called:
            self._loop_sleep_called = True
            return True
        return self.sleep(sleep_time)

    def is_none(self):
        # timeout=None means no timeout (infinity). It can be useful
        # to ask @self whether timeout is disabled.
        return self._expiry is None


class _Util:

    # like time.CLOCK_BOOTTIME, which only exists since Python 3.7
    CLOCK_BOOTTIME = 7

    class ExpectedException(Exception):
        # We don't want to just catch blindly all "Exception" types
        # but rather only those exceptions where an API is known that
        # it might fail and fails with a particular exception type.
        #
        # Usually, we would thus add various Exception classes that
        # carry specific information about the failure reason. However,
        # that is sometimes just cumbersome.
        #
        # This exception type fills this purpose. It's not very specific
        # but it's specific enough that we can catch it for functions that
        # are known to have certain failures -- while not needing to swallow
        # all exceptions.
        pass

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

    def util_dir(self, *args):
        if not hasattr(self, "_util_dir"):
            self._util_dir = os.path.dirname(
                os.path.realpath(os.path.abspath(__file__))
            )
        return os.path.join(self._util_dir, *args)

    @property
    def BASE_DIR(self):
        if not hasattr(self, "_base_dir"):
            self._base_dir = os.path.realpath(self.util_dir(".."))
        return self._base_dir

    def base_dir(self, *args):
        return os.path.join(self.BASE_DIR, *args)

    def tmp_dir(self, *args, create_base_dir=True):
        d = self.base_dir(".tmp")
        if create_base_dir and not os.path.isdir(d):
            os.mkdir(d)
        return os.path.join(d, *args)

    def gvariant_to_dict(self, variant):
        import json

        JsonGLib = self.JsonGLib
        j = JsonGLib.gvariant_serialize(variant)
        return json.loads(JsonGLib.to_string(j, 0))

    def consume_list(self, lst):
        # consumes the list (removing all elements, from the beginning)
        # and returns an iterator for the elements.
        while True:
            # Popping at the beginning is probably O(n) so this
            # is not really efficient. Doesn't matter for our uses.
            try:
                v = lst.pop(0)
            except IndexError:
                break
            yield v

    def binary_to_str(self, b, binary=None):
        assert binary is None or binary is False or binary is True
        if isinstance(b, bytes):
            if binary is True:
                # The caller requested binary. Just return it.
                return b
            try:
                return b.decode("utf-8", errors="strict")
            except UnicodeError:
                if binary is False:
                    # The caller requested a string. We fail.
                    raise

                # The caller accepts both. Return binary.
                return b
        raise ValueError("Expects bytes")

    def bytes_to_str(self, s, errors="strict"):
        if isinstance(s, bytes):
            return s.decode("utf-8", errors=errors)
        if isinstance(s, str):
            return s
        raise ValueError("Expects either a str or bytes")

    def str_to_bytes(self, s):
        if isinstance(s, str):
            return s.encode("utf-8")
        if isinstance(s, bytes):
            return s
        raise ValueError("Expects either a str or bytes")

    FileGetContentResult = collections.namedtuple(
        "FileGetContentResult", ["data", "full_file"]
    )

    def start_timeout(self, *a, **kw):
        return _Timeout(*a, **kw)

    def fd_get_content(
        self,
        file,
        max_size=None,
        warn_max_size=True,
    ):
        if max_size is None:
            max_size = 50 * 1024 * 1024

        data = file.read(max_size)
        full_file = not file.read(1)

        if not full_file and warn_max_size:
            try:
                size = str(os.fstat(file.fileno()).st_size)
            except Exception:
                size = "???"
            m = f"\n\nWARNING: size limit reached after reading {max_size} of {size} bytes. Output is truncated"
            if isinstance(data, bytes):
                data += self.str_to_bytes(m)
            else:
                data += m

        return self.FileGetContentResult(data, full_file)

    def file_get_content(
        self,
        file_name,
        encoding="utf-8",
        errors="strict",
        max_size=None,
        warn_max_size=True,
    ):
        # Set "encoding" to None to get bytes.
        if encoding is None:
            file = open(file_name, mode="rb")
        else:
            file = open(file_name, mode="r", encoding=encoding, errors=errors)
        with file:
            return self.fd_get_content(
                file, max_size=max_size, warn_max_size=warn_max_size
            )

    def file_get_content_simple(self, file_name, as_bytes=False):
        if as_bytes:
            encoding = None
        else:
            encoding = "utf-8"
        return self.file_get_content(
            file_name, encoding=encoding, errors="replace"
        ).data

    def file_set_content(self, file_name, data="", context_hook=None):
        if isinstance(data, str):
            data = data.encode("utf-8")
        elif isinstance(data, bytes):
            pass
        else:
            # append [""] to add "\n" after last line, note the number of added "\n" is len(data)
            data = b"\n".join((self.str_to_bytes(line) for line in list(data) + [""]))

        if context_hook:
            context_hook("file_set_content", file_name, data)

        with open(file_name, "wb") as f:
            f.write(data)

    def gvariant_type(self, s):

        if s is None:
            return None

        if isinstance(s, str):
            return self.GLib.VariantType(s)

        if isinstance(s, self.GLib.VariantType):
            return s

        raise ValueError("cannot get the GVariantType for %r" % (s))

    def compare_strv_list(
        self,
        expected,
        strv,
        match_mode="auto",
        ignore_extra_strv=True,
        ignore_order=True,
    ):
        # Compare the "@strv" list of strings with "@expected". If the list differs,
        # a ValueError gets raised. Otherwise it return True.
        #
        # @expected: the list of expected items. It can be a plain string,
        #   or a regex string (see @match_mode).
        # @strv: the string list that we check.
        # @match_mode: how the elements in @expected are compared against @strv
        #    - "plain": direct string comparison
        #    - "regex": regular expression using re.search(e, s)
        #    - "auto": each element can encode whether to be an optional match (starting
        #        with '?'), and whether to use regex/plain mode ('/' vs. '=').
        # @ignore_extra_strv: if True, extra non-matched elementes in strv are silently accepted
        # @ignore_order: if True, the order is not checked. Otherwise, the
        #   elements in @expected must match in the right order.
        #   For example, with match_mode='plain', expected=['a', '.'], strv=['b', 'a'], this
        #   matches when ignoring the order, but fails to match otherwise.
        #   An element in @expected only can match exactly once.
        expected = list(expected)
        strv = list(strv)

        expected_match_idxes = []
        strv_matched = [False for s in strv]
        expected_required = [True for s in expected]
        for (i, e) in enumerate(expected):
            e0 = e
            idxes = []

            # With "match_mode=auto", we detect the match mode based on the string.
            #
            # If the string starts with '?', it means that the element is
            # optional. That means it may match not at all or once.
            # The leading "?" gets stripped first.
            if match_mode == "auto" and e[0] == "?":
                e = e[1:]
                expected_required[i] = False

            # With "match_mode=auto", if the string starts with a '/' it
            # is a regex (the '/' gets stripped).
            # With "match_mode=auto", if the string starts with a '=' it
            # is a plain string (the '=' gets stripped). "plain" is also
            # the default otherwise (the '=' is only to escape strings).
            if match_mode == "auto" and e[0] == "/":
                f_match = lambda s: bool(re.search(e[1:], s))
            elif match_mode == "auto" and e[0] == "=":
                f_match = lambda s: (s == e[1:])
            elif match_mode in ["auto", "plain"]:
                f_match = lambda s: (s == e)
            else:
                assert match_mode == "regex"
                f_match = lambda s: bool(re.search(e, s))

            for (j, s) in enumerate(strv):
                if f_match(s):
                    strv_matched[j] = True
                    idxes.append(j)

            if not idxes:
                if expected_required[i]:
                    raise ValueError(
                        f'Could not find #{i} "{e0}" in list {str(strv)} (expected {str(expected)})'
                    )
            expected_match_idxes.append(idxes)

        if not ignore_extra_strv:
            for (j, s) in enumerate(strv):
                if not strv_matched[j]:
                    raise ValueError(
                        f'List {str(strv)} contains non expected element #{j} "{s}" (expected {str(expected)})'
                    )

        # We now have a mapping of `expected_match_idxes[i]` where each element at position `i` contains
        # a list of indexes for `strv` which matched. Note that this list of indexes might be
        # empty (with `not expected_required[i]`) or contain multiple indexes (with regular
        # expression that can match multiple strings.
        #
        # Depending on `ignore_order`, we need to find a combination of matches that
        # satisfies the requirement. E.g. every `expected[i]` must match zero or
        # one time (depending on `expected_required[i]`). With `not ignore_order`,
        # the matches must all have indexes in ascending order.
        def _has_unique_permuation(lst, base_idx, seen_idx):

            if base_idx >= len(lst):
                return True

            if not expected_required[base_idx]:
                # Try without a match first.
                good = _has_unique_permuation(lst, base_idx + 1, seen_idx)
                if good:
                    return True

            for i in lst[base_idx]:
                if i in seen_idx:
                    # already visited
                    continue
                if not ignore_order and seen_idx and i < max(seen_idx):
                    # the increasing order (of indexes) would be violated.
                    continue
                seen_idx.add(i)
                good = _has_unique_permuation(lst, base_idx + 1, seen_idx)
                seen_idx.remove(i)
                if good:
                    return True
            return False

        rl = sys.getrecursionlimit()
        sys.setrecursionlimit(rl + len(expected))
        try:
            has = _has_unique_permuation(
                [idxes for idxes in expected_match_idxes if idxes], 0, set()
            )
        finally:
            sys.setrecursionlimit(rl)

        if not has:
            raise ValueError(
                f"List {str(strv)} unexpectedly could not match expected list in a unique way {'ignoring' if ignore_order else 'requiring'} the order (expected {str(expected)})"
            )

        return True


sys.modules[__name__] = _Util()
