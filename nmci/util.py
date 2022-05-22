import os
import re
import subprocess
import sys


class _Util:

    # like time.CLOCK_BOOTTIME, which only exists since Python 3.7
    CLOCK_BOOTTIME = 7

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

    def file_set_content(self, file_name, data=""):
        if isinstance(data, str):
            data = data.encode("utf-8")
        elif isinstance(data, bytes):
            pass
        else:
            # append [""] to add "\n" after last line, note the number of added "\n" is len(data)
            data = b"\n".join((self.str_to_bytes(line) for line in list(data) + [""]))
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
