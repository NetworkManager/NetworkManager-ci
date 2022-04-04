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
        #    - "auto": if string starts with "/", use "regex" otherwise "plain" (the default).
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
        for (i, e) in enumerate(expected):
            idxes = []

            if match_mode == "auto" and e[0] == "/":
                f_match = lambda s: bool(re.search(e[1:], s))
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
                raise ValueError(
                    f'Could not find #{i} "{e}" in list {str(strv)} (expected {str(expected)})'
                )
            expected_match_idxes.append(idxes)

        if not ignore_extra_strv:
            for (j, s) in enumerate(strv):
                if not strv_matched[j]:
                    raise ValueError(
                        f'List {str(strv)} contains non expected element #{j} "{s}" (expected {str(expected)})'
                    )

        # OK, some strings in @strv might have been matched multiple times
        # (the indexes are now in @expected_match_idxes). This happens with regular expressions.
        # For example, expected=[".*", "aa"] should match strv=["aa", "b"] correctly.
        #
        # With (not ignore_order) that is simple. We must keep always the lowest index.
        # With (ignore_order) it is more complicated, because we need to find one combination
        # that satisfies a one-to-one match of the expected list.
        if ignore_order:

            # we want to find at least one permutation, so that
            # each pattern in expected matches exactly once.
            def has_unique_permuation(lst, start, seen_idx):

                if start >= len(lst):
                    return True

                for i in lst[start]:
                    if i in seen_idx:
                        continue
                    seen_idx.add(i)
                    good = has_unique_permuation(lst, start + 1, seen_idx)
                    seen_idx.remove(i)
                    if good:
                        return True
                return False

            rl = sys.getrecursionlimit()
            sys.setrecursionlimit(rl + 100 + len(expected))
            try:
                has = has_unique_permuation(expected_match_idxes, 0, set())
            finally:
                sys.setrecursionlimit(rl)

            if not has:
                raise ValueError(
                    f"List {str(strv)} unexpectedly could not match expected list in a unique way ignoring the order (expected {str(expected)})"
                )

        else:
            # if we require that the expected elements match in the same order
            # as they are in the strv array. That is simple, it means we track
            # the highest index that we already matched and require that it increases.
            for i, idxes in enumerate(expected_match_idxes):
                if i == 0:
                    # First iteration. The highest index is the minimum of
                    # expected_match_idxes[0].
                    j_highest = min(idxes)
                    continue
                # only consider indexes higher than j_highest
                l2 = [j for j in idxes if j > j_highest]
                if not l2:
                    # There is no such index. The match is out of order.
                    raise ValueError(
                        f'List {str(strv)} unexpectedly contains #{min(idxes)} "{strv[min(idxes)]}" before #{j_highest} "{strv[j_highest]}" (expected {str(expected)})'
                    )
                j_highest = min(l2)

        return True


sys.modules[__name__] = _Util()
