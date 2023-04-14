import nmci
import subprocess
import os
import time
import glob

COREDUMP_TYPE_SYSTEMD_COREDUMP = "systemd-coredump"
COREDUMP_TYPE_ABRT = "abrt"


def check_dump_package(pkg_name):
    """Helper function to check if package name is relevant.

    :param pkg_name: name of the package
    :type pkg_name: ste
    :return: True if NetworkManager or ModemManager, False otherwise
    :rtype: bool
    """
    if (
        pkg_name in ["NetworkManager", "ModemManager"]
        or "ovs" in pkg_name
        or "openvswitch" in pkg_name
    ):
        return True
    return False


def check_crash(context, crashed_step):
    """Check if crash hapenned (by NM PID change), remember step when crash occured in context.

    :param context: behave Context object
    :type context: behave.Context
    :param crashed_step: Name of the crashed step
    :type crashed_step: str
    """
    pid_refresh_count = getattr(context, "nm_pid_refresh_count", 0)
    if pid_refresh_count > 0:
        context.pid_refresh_count = pid_refresh_count - 1
        context.nm_pid = nmci.nmutil.nm_pid()
    elif not context.crashed_step:
        new_pid = nmci.nmutil.nm_pid()
        if new_pid != context.nm_pid:
            print(
                "NM Crashed as new PID %s is not old PID %s" % (new_pid, context.nm_pid)
            )
            context.crashed_step = crashed_step
            if not context.crashed_step:
                context.crashed_step = "crash during scenario (NM restarted)"


def check_coredump(context):
    """Check for crashes reported to coredump

    :param context: behave Context object
    :type context: behave.Context
    """
    for dump_dir in coredump_list_on_disk(COREDUMP_TYPE_SYSTEMD_COREDUMP):
        print("Examining crash: " + dump_dir)
        dump_dir_split = dump_dir.split(".")
        if len(dump_dir_split) < 6:
            print("Some garbage in %s" % (dump_dir))
            continue
        if not check_dump_package(dump_dir_split[1]):
            continue
        try:
            pid, _ = int(dump_dir_split[4]), int(dump_dir_split[5])
        except Exception as e:
            print("Some garbage in %s: %s" % (dump_dir, str(e)))
            continue
        if not coredump_is_reported(dump_dir):
            # 'coredumpctl debug' not available in RHEL7
            if "Maipo" in context.rh_release:
                timeout = nmci.util.start_timeout(60)
                while timeout.loop_sleep(5):
                    e = False
                    try:
                        dump = nmci.process.run_stdout(
                            f"echo backtrace | coredumpctl -q -batch gdb {pid}",
                            shell=True,
                            stderr=subprocess.STDOUT,
                            ignore_stderr=True,
                            timeout=120,
                            embed_combine_tag=nmci.embed.NO_EMBED,
                        )
                    except Exception as ex:
                        e = ex
                    if not e:
                        break
                if e:
                    raise e
            else:
                timeout = nmci.util.start_timeout(60)
                while timeout.loop_sleep(5):
                    e = False
                    try:
                        dump = nmci.process.run_stdout(
                            f"echo backtrace | coredumpctl debug {pid}",
                            shell=True,
                            stderr=subprocess.STDOUT,
                            ignore_stderr=True,
                            timeout=120,
                            embed_combine_tag=nmci.embed.NO_EMBED,
                        )
                    except Exception as ex:
                        e = ex
                    if not e:
                        break
                if e:
                    raise e

            nmci.embed.embed_dump("COREDUMP", dump_dir, data=dump)


def _coredump_reported_file():
    """Cache file of already reported crashes

    :return: Filename of cache file
    :rtype: str
    """
    return nmci.util.tmp_dir("reported_crashes")


def coredump_is_reported(dump_id):
    """Check if crash is already reported, to not spam repeatedly the same crash.

    :param dump_id: unique ID of the crash, should differ across distinct crashes
    :type dump_id: str
    :return: True if already reported, False otherwise
    :rtype: bool
    """
    filename = _coredump_reported_file()
    if os.path.isfile(filename):
        dump_id += "\n"
        with open(filename) as f:
            for line in f:
                if dump_id == line:
                    return True
    return False


def coredump_report(dump_id):
    """Save crash ID in cache, to be reported only once.

    :param dump_id: unique ID of the crash, should differ across distinct crashes
    :type dump_id: str
    """
    with open(_coredump_reported_file(), "a") as f:
        f.write(dump_id + "\n")


def coredump_list_on_disk(dump_type=None):
    """List coredumps on disk.

    :param dump_type: one of COREDUMP_TYPE_SYSTEMD_COREDUMP or COREDUMP_TYPE_ABRT, defaults to None
    :type dump_type: obj, optional
    :return: list of filenames
    :rtype: list of filename
    """
    if dump_type == COREDUMP_TYPE_SYSTEMD_COREDUMP:
        g = "/var/lib/systemd/coredump/*"
    elif dump_type == COREDUMP_TYPE_ABRT:
        g = "/var/spool/abrt/ccpp*"
    else:
        assert False, f"Invalid dump_type {dump_type}"
    return glob.glob(g)


def wait_faf_complete(context, dump_dir):
    """Waits until given FAF is uploaded and reported correctly.

    :param context: behave Context object
    :type context: behave.Context
    :param dump_dir: FAF dir to wait for
    :type dump_dir: ste
    :return: True if wait succeded, False, if report still not complete
    :rtype: bool
    """
    NM_pkg = False
    last = False
    last_timestamp = 0
    backtrace = False
    reported_bordell = False
    for i in range(context.faf_countdown):
        if not os.path.isdir(dump_dir):
            # Seems like FAF found it to be a duplicate one
            context.abrt_dir_change = True
            print("* report dir went away, skipping.")
            return False

        if not NM_pkg and os.path.isfile(f"{dump_dir}/psubprockg_name"):
            pkg = nmci.util.file_get_content_simple(f"{dump_dir}/pkg_name")
            if not check_dump_package(pkg):
                print("* not NM related FAF")
                context.faf_countdown -= i
                context.faf_countdown = max(10, context.faf_countdown)
                return False
            else:
                NM_pkg = True

        last = last or os.path.isfile(f"{dump_dir}/last_occurrence")
        if last and not last_timestamp:
            last_timestamp = nmci.util.file_get_content_simple(
                f"{dump_dir}/last_occurrence"
            )
            if coredump_is_reported(f"{dump_dir}-{last_timestamp}"):
                print("* Already reported")
                context.faf_countdown -= i
                context.faf_countdown = max(5, context.faf_countdown)
                return False
            print("* not yet reported, new crash")

        backtrace = backtrace or os.path.isfile(f"{dump_dir}/backtrace")

        if not reported_bordell and os.path.isfile(f"{dump_dir}/reported_to"):
            # embed content of reported_to for debug purposes
            nmci.process.run_stdout(f"cat {dump_dir}/reported_to", shell=True)
            reported_bordell = "bordell" in nmci.util.file_get_content_simple(
                f"{dump_dir}/reported_to"
            )
            # if there is no sosreport.log file, crash is already reported in FAF server
            # give it 5s to be 100% sure it is not starting
            time.sleep(5)
            if not reported_bordell and not os.path.isfile(f"{dump_dir}/sosreport.log"):
                reported_bordell = True

        if NM_pkg and last and backtrace and reported_bordell:
            print(f"* all FAF files exist in {i} seconds, should be complete")
            context.faf_countdown -= i
            context.faf_countdown = max(5, context.faf_countdown)
            return True
        print(f"* report not complete yet, try #{i}")
        nmci.process.run(
            f"ls -l {dump_dir}/{{backtrace,coredump,last_occurrence,pkg_name,reported_to}}",
            ignore_stderr=True,
        )
        time.sleep(1)
    if backtrace:
        print("* inclomplete report, but we have backtrace")
        return True
    # give other FAF 5 seconds (already waited 300 seconds)
    context.faf_countdown = 5
    print(
        f"* incomplete FAF report in {context.faf_countdown}s, skipping in this test."
    )
    return False


def check_faf(context):
    """Check for new FAF reports

    :param context: behave COntext object
    :type context: behave.Context
    """
    context.abrt_dir_change = True
    context.faf_countdown = 300
    while context.abrt_dir_change:
        context.abrt_dir_change = False
        for dump_dir in coredump_list_on_disk(COREDUMP_TYPE_ABRT):
            print("Entering crash dir: " + dump_dir)
            if not wait_faf_complete(context, dump_dir):
                if context.abrt_dir_change:
                    break
                continue
            reports = []
            if os.path.isfile("%s/reported_to" % (dump_dir)):
                reports = (
                    nmci.util.file_get_content_simple("%s/reported_to" % (dump_dir))
                    .strip("\n")
                    .split("\n")
                )
            urls = []
            for report in reports:
                if "URL=" in report:
                    label, url = report.replace("URL=", "", 1).split(":", 1)
                    urls.append([url.strip(), label.strip()])

            last_timestamp = nmci.util.file_get_content_simple(
                f"{dump_dir}/last_occurrence"
            )
            dump_id = f"{dump_dir}-{last_timestamp}"
            if urls:
                nmci.embed.embed_dump("FAF", dump_id, links=urls)
            else:
                if os.path.isfile("%s/backtrace" % (dump_dir)):
                    data = "Report not yet uploaded, please check FAF portal.\n\nBacktrace:\n"
                    data += nmci.util.file_get_content_simple(
                        "%s/backtrace" % (dump_dir)
                    )
                    nmci.embed.embed_dump("FAF", dump_id, data=data)
                else:
                    nmci.embed.embed_dump(
                        "FAF",
                        dump_id,
                        data="Report not yet uploaded, no backtrace yet, please check FAF portal.",
                    )


def after_crash_reset(context):
    """Do the reset of NetworkManager config and envionment, to prevent NetworkManager crashing again.

    :param context: behave Context object
    :type context: behave.Context
    """
    print("@after_crash_reset")

    print("Stop NM")
    nmci.nmutil.stop_NM_service()

    print("Remove all links except eth*")
    allowed_links = (
        [b"lo"] + [b"wwan0"] + [f"eth{i}".encode("utf-8") for i in range(0, 11)]
    )
    for link in nmci.ip.link_show_all(binary=True):
        if link["ifname"] in allowed_links or link["ifname"].startswith(b"orig-"):
            continue
        nmci.process.run(
            [b"ip", b"link", b"delete", nmci.util.str_to_bytes(link["ifname"])],
            ignore_returncode=True,
            ignore_stderr=True,
        )

    print("Remove all ifcfg files")
    dir = "/etc/sysconfig/network-scripts"
    ifcfg_files = glob.glob(dir + "/ifcfg-*")
    nmci.process.run_stdout("rm -vrf " + " ".join(ifcfg_files))

    print("Remove all keyfiles in /etc")
    dir = "/etc/NetworkManager/system-connections"
    key_files = glob.glob(dir + "/*")
    nmci.process.run_stdout("rm -vrf " + " ".join(key_files))

    print("Remove all config in /etc except 99-test.conf")
    dir = "/etc/NetworkManager/conf.d"
    conf_files = [
        f
        for f in glob.glob(dir + "/*")
        if not f.endswith("/99-test.conf") and not f.endswith("/99-unmanage-orig.conf")
    ]
    nmci.process.run_stdout(["rm", "-vrf", *conf_files])

    print("Remove /run/NetworkManager/")
    if os.path.isdir("/run/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /run/NetworkManager/*")
    elif os.path.isdir("/var/run/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /var/run/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager run directory")

    print("Remove /var/lib/NetworkManager/")
    if os.path.isdir("/var/lib/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /var/lib/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager in /var/lib directory")

    print("Flush eth0 IP")
    nmci.process.run_stdout("ip addr flush dev eth0")
    nmci.process.run_stdout("ip -6 addr flush dev eth0")

    nmci.nmutil.start_NM_service()

    print("Wait for testeth0")
    nmci.veth.wait_for_testeth0()

    if os.path.isfile("/tmp/nm_veth_configured"):
        nmci.veth.check_vethsetup()
    else:
        print("Up eth1-10 links")
        for link in range(1, 11):
            nmci.process.run_stdout(f"ip link set eth{link} up")
        print("Add testseth1-10 connections")
        for link in range(1, 11):
            nmci.process.nmcli(
                f"con add type ethernet ifname eth{link} con-name testeth{link} autoconnect no"
            )
