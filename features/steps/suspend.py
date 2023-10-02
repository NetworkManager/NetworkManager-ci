# pylint: disable=function-redefined,no-name-in-module
# type: ignore [no-redef]
import time
from behave import step

import nmci


@step("Mock systemd-logind service")
def mock_logind(context):
    def _cleanup_proc():
        context.logind_proc.kill(15)
        context.logind_proc.expect(nmci.pexpect.EOF)

    assert getattr(context, "logind_proc", None) is None, "logind is already mocked"

    nmci.cleanup.add_callback(
        lambda: nmci.process.systemctl("start systemd-logind"),
        name="start_systemd-logind",
    )
    nmci.cleanup.add_callback(
        lambda: nmci.process.systemctl("unmask systemd-logind"),
        name="unmask_systemd-logind",
    )
    nmci.cleanup.add_callback(_cleanup_proc, name="stop mocked logind")

    nmci.process.systemctl("stop systemd-logind")
    nmci.process.systemctl("mask systemd-logind")

    context.logind_proc = nmci.pexpect.pexpect_service(
        "python3 -m dbusmock --template logind"
    )
    with nmci.util.start_timeout(10, "mock suspend signal") as t:
        while t.loop_sleep(0.2):
            if (
                nmci.process.run(
                    [
                        "gdbus",
                        "call",
                        "--system",
                        "-d",
                        "org.freedesktop.login1",
                        "-o",
                        "/org/freedesktop/login1",
                        "-m",
                        "org.freedesktop.DBus.Mock.AddMethod",
                        "org.freedesktop.login1.Manager",
                        "Suspend",
                        "b",
                        "",
                        'self.EmitSignal("", "PrepareForSleep", "b", args)',
                    ],
                    ignore_stderr=True,
                ).returncode
                == 0
            ):
                break


@step('Send "{signal}" signal to mocked logind')
def mock_suspend_wakeup(context, signal):
    assert getattr(context, "logind_proc", None) is not None, "logind is not mocked"
    assert signal.lower() in [
        "suspend",
        "wakeup",
    ], f"Unexpected signal `{signal}`, expected `suspend` or `wakeup`."
    # signal_b is "true" for "suspend", "false" otherwise
    signal_b = str(signal.lower() == "suspend").lower()
    nmci.process.run(
        [
            "gdbus",
            "call",
            "--system",
            "-d",
            "org.freedesktop.login1",
            "-o",
            "/org/freedesktop/login1",
            "-m",
            "org.freedesktop.login1.Manager.Suspend",
            signal_b,
        ]
    )


@step("Suspend and resume via /sys/power")
def suspend_hw(context):
    # backup pm

    def read_val(file_name):
        return nmci.process.run_stdout(
            rf"grep -o '\[.*\]' /sys/power/{file_name} | tr -d '[]' ", shell=True
        ).strip("\n")

    def assure_val(file_name, value):
        nmci.process.run_stdout(f"echo {value} > /sys/power/{file_name}", shell=True)
        # Wait for param to be applied
        # Without the delay, system might ignore "test_resume" and hibernate
        with nmci.util.start_timeout(5) as t:
            while t.loop_sleep(0.1):
                if read_val(file_name) == value:
                    break

    context.pm_backup = getattr(context, "pm_backup", {"disk": None, "pm_test": None})
    for file_name, value in context.pm_backup.items():
        if value is None:
            value = read_val(file_name)
            context.pm_backup[file_name] = value

    def restore_pm():
        for file_name, value in context.pm_backup.items():
            if value is not None:
                assure_val(file_name, value)
            context.pm_backup[file_name] = None

    nmci.cleanup.add_callback(
        restore_pm, name="restore-/sys/power", unique_tag=(context.pm_backup)
    )
    # do suspend
    assure_val("pm_test", "devices")
    assure_val("disk", "test_resume")
    # do not use assure_val here, as it is not state file
    nmci.process.run_stdout("echo disk > /sys/power/state", shell=True, timeout=60)
