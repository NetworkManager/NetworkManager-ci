# pylint: disable=no-name-in-module
from behave import step

import nmci


@step("Start test-cloud-meta-mock.py")
def start_test_cloud_meta_mock(context):
    nmci.cleanup.add_callback(
        [
            lambda: nmci.process.run_stdout(
                "systemctl reset-failed test-cloud-meta-mock.service"
            ),
            lambda: nmci.process.run_stdout(
                "systemctl stop test-cloud-meta-mock.service"
            ),
        ],
        name="stop:test-cloud-meta-mock",
    )
    nmci.process.run_stdout(
        [
            "systemd-run",
            "--remain-after-exit",
            "--unit=test-cloud-meta-mock",
            "systemd-socket-activate",
            "-l",
            str(nmci.nmutil.NMCS_MOCK_PORT),
            "python",
            nmci.util.base_dir("contrib/cloud/test-cloud-meta-mock.py"),
        ],
        ignore_stderr=True,
    )
