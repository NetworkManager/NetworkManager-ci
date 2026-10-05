#!/usr/bin/env python3

import ast
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, call, patch

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_REPO = "https://github.com/nmstate/nmstate.git"
BASES = {
    "KOJI": "https://kojipkgs.fedoraproject.org/packages",
    "BREW": "http://download.devel.redhat.com/brewroot/vol",
    "FEDP": "https://vbenes.fedorapeople.org/NM",
    "CBSC": "https://cbs.centos.org/kojifiles/packages",
    "KHUB": "https://kojihub.stream.centos.org/kojifiles/packages",
    "MBOX": "https://koji.mbox.centos.org/pkgs/packages",
}


class SourceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="nmci-sources-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.env = {
            "PATH": os.environ["PATH"],
            "HOME": os.environ["HOME"],
            "LC_ALL": "C",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_ALLOW_PROTOCOL": "file",
            "GIT_TERMINAL_PROMPT": "0",
        }

    def run_command(self, args, env=None, **kwargs):
        environment = dict(self.env)
        environment.update(env or {})
        return subprocess.run(
            args,
            env=environment,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            **kwargs
        )

    def test_python_clones(self):
        for filename, name, args, destination, cwd in (
            ("commands.py", "run_nmstate", ("log",), "/tmp/nmstate", None),
            (
                "commands.py",
                "run_nmstate_from_copr",
                ("repo", "log"),
                "/tmp/nmstate",
                None,
            ),
            (
                "prepare.py",
                "libreswan_ng_setup",
                ("psk",),
                "nmstate",
                "contrib/ipsec",
            ),
        ):
            path = ROOT / "features/steps" / filename
            tree = ast.parse(path.read_text())
            function = next(
                node
                for node in tree.body
                if isinstance(node, ast.FunctionDef) and node.name == name
            )
            function.decorator_list = []
            module = ast.parse("")
            module.body = [function]
            for value, fail in (
                (None, False),
                ("", False),
                ("/tmp/mirror with spaces/different-name.git", False),
                ("/tmp/absent-nmstate-mirror.git", True),
            ):
                with self.subTest(function=name, repository=value):
                    expected_repo = value or PUBLIC_REPO
                    calls = []

                    def capture(command, default_ignore, **kwargs):
                        calls.append((command, kwargs))
                        is_clone = isinstance(command, list) and command[:2] == [
                            "git",
                            "clone",
                        ]
                        if is_clone and fail:
                            if not kwargs.get("ignore_returncode", default_ignore):
                                raise subprocess.CalledProcessError(128, command)
                        return ""

                    nmci = MagicMock()
                    nmci.process.run.side_effect = lambda command, **kwargs: capture(
                        command, True, **kwargs
                    )
                    nmci.process.run_stdout.side_effect = (
                        lambda command, **kwargs: capture(command, False, **kwargs)
                    )
                    nmci.util.file_get_content_simple.return_value = ""
                    nmci.util.start_timeout.return_value.__enter__.return_value.elapsed_time.return_value = (
                        0.0
                    )
                    namespace = {
                        "os": os,
                        "nmci": nmci,
                        "time": MagicMock(),
                        "print": lambda *args, **kwargs: None,
                    }
                    exec(compile(module, str(path), "exec"), namespace)
                    context = SimpleNamespace(
                        rh_release_num=[10, 1], rh_release="CentOS", noted={}
                    )
                    with patch.dict(
                        os.environ,
                        {} if value is None else {"NMSTATE_REPO": value},
                        clear=True,
                    ), patch("os.path.isfile", return_value=False), patch(
                        "os.path.exists", side_effect=lambda path: path == "/root/rpms/"
                    ), patch.dict(
                        sys.modules,
                        {"yaml": SimpleNamespace(safe_load=lambda text: {})},
                    ):
                        if fail:
                            with self.assertRaises(
                                subprocess.CalledProcessError
                            ) as error:
                                namespace[name](context, *args)
                            self.assertEqual(error.exception.returncode, 128)
                        else:
                            namespace[name](context, *args)
                    clones = [
                        call
                        for call in calls
                        if isinstance(call[0], list) and call[0][:2] == ["git", "clone"]
                    ]
                    attempts = 3 if fail and name == "libreswan_ng_setup" else 1
                    self.assertEqual(len(clones), attempts)
                    for command, kwargs in clones:
                        self.assertEqual(
                            command, ["git", "clone", "--", expected_repo, destination]
                        )
                        self.assertEqual(kwargs.get("cwd"), cwd)
                    if name == "libreswan_ng_setup":
                        self.assertEqual(
                            namespace["time"].sleep.call_args_list,
                            [call(60)] * (attempts - 1),
                        )
                        self.assertEqual(
                            nmci.pexpect.pexpect_service.call_count, not fail
                        )
                    else:
                        self.assertEqual(len(calls), 1 if fail else 2)

    def test_artifact_bases(self):
        script = 'source "$1"; printf "%s\\0" "$KOJI" "$BREW" "$FEDP" "$CBSC" "$KHUB" "$MBOX"'
        for overrides in (
            {},
            dict.fromkeys(BASES, ""),
            {name: "https://mirror.invalid/" + name for name in BASES},
        ):
            with self.subTest(overrides=overrides):
                result = self.run_command(
                    [
                        "bash",
                        "-c",
                        script,
                        "bash",
                        str(ROOT / "prepare/envsetup/utils.sh"),
                    ],
                    env=overrides,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    result.stdout.split("\0")[:-1],
                    [overrides.get(name) or default for name, default in BASES.items()],
                )

    def test_bootstrap(self):
        wrapper = r"""
rm() { return 0; }
cp() { return 0; }
systemctl() { return 0; }
touch() { printf '%s' "$1" > "$NMCI_TEST_DIR/failed"; }
wget() {
    printf '%s\0' "$@" > "$NMCI_TEST_DIR/download"
    return "$NMCI_TEST_DOWNLOAD_RC"
}
bash() {
    printf '%s' "$BUILD_REPO" > "$NMCI_TEST_DIR/build-repo"
    return "$NMCI_TEST_BUILD_RC"
}
source "$1" main snapshot
"""
        for index, (repo, url, download_rc, build_rc) in enumerate(
            (
                (None, None, 0, 0),
                ("", "", 0, 0),
                (
                    "ssh://mirror.invalid/nm.git",
                    "https://mirror.invalid/raw/build script?ref=automation&x=1",
                    0,
                    0,
                ),
                ("ssh://mirror.invalid/nm.git", "https://mirror.invalid/missing", 1, 0),
                ("ssh://mirror.invalid/nm.git", "https://mirror.invalid/build", 0, 42),
            )
        ):
            with self.subTest(
                repository=repo, download_rc=download_rc, build_rc=build_rc
            ):
                work = self.directory / ("build-" + str(index))
                work.mkdir()
                env = {
                    "NMCI_TEST_DIR": str(work),
                    "NMCI_TEST_DOWNLOAD_RC": str(download_rc),
                    "NMCI_TEST_BUILD_RC": str(build_rc),
                }
                if repo is not None:
                    env["BUILD_REPO"] = repo
                if url is not None:
                    env["BUILD_SCRIPT_URL"] = url
                result = self.run_command(
                    [
                        "bash",
                        "-c",
                        wrapper,
                        "bash",
                        str(ROOT / "run/centos-ci/scripts/build.sh"),
                    ],
                    cwd=str(work),
                    env=env,
                )
                expected_repo = (
                    repo or "https://github.com/NetworkManager/NetworkManager.git"
                )
                expected_url = (
                    url
                    or (
                        expected_repo[:-4]
                        if expected_repo.endswith(".git")
                        else expected_repo
                    )
                    + "/raw/automation/contrib/rh-bkr/build-from-source.sh"
                )
                self.assertEqual(
                    (work / "download").read_text().split("\0")[:-1],
                    [expected_url, "-O", "/root/nm-build-from-source.sh"],
                )
                failed = bool(download_rc or build_rc)
                self.assertEqual(result.returncode, int(failed), result.stderr)
                self.assertEqual((work / "failed").exists(), failed)
                self.assertEqual((work / "build-repo").exists(), not download_rc)
                if not download_rc:
                    self.assertEqual((work / "build-repo").read_text(), expected_repo)


if __name__ == "__main__":
    unittest.main()
