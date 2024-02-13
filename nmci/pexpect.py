import pexpect

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class PexpectData:
    """
    Data for pexpect processes spawned by pexpect_spawn() and pexpect_service().
    """

    def __init__(self, is_service, proc, logfile, embed_context, label, check):
        self.is_service = is_service
        self.proc = proc
        self.logfile = logfile
        self.embed_context = embed_context
        self.label = label
        self.check = check


class _PExpect:
    """
    Pexpect helper class for spawning processes and services.
    """

    def __init__(self):
        self._pexpect_spawn_lst = []
        self._pexpect_service_lst = []
        self.EOF = pexpect.EOF  # pylint: disable=invalid-name
        self.TIMEOUT = pexpect.TIMEOUT  # pylint: disable=invalid-name
        self.DEV_NULL = object()

    def _pexpect_complete(self, data):
        proc = data.proc
        failed = False
        if proc.isalive():
            # this will set status to 15
            proc.kill(15)
            if proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1:
                # this will set status to 9
                proc.kill(9)
        # if proc is not closed, and does not return EOF in 0.2s,
        # (it was killed -9 already, if still running)
        # it is zombie probably, return status -1 and embed `ps aufx`
        if (
            not proc.closed
            and proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1
        ):
            failed = True
            returncode = -1
            nmci.embed.embed_data(
                "DEBUG: ps aufx",
                nmci.process.run_stdout(
                    "ps aufx", embed_combine_tag=nmci.embed.NO_EMBED
                ),
            )
        else:
            proc.close()
            returncode = proc.status
        stdout = nmci.util.file_get_content_simple(data.logfile.name)
        data.logfile.close()

        argv = "pexpect:" + proc.name

        nmci.embed.embed_run(
            argv,
            True,
            returncode,
            stdout,
            None,
            embed_context=data.embed_context,
            combine_tag="Commands",
        )

        return failed, argv, returncode, stdout

    def _pexpect_service_cleanup(self, data):
        self._pexpect_service_lst.remove(data)

        (
            p_failed,
            argv,
            returncode,
            stdout,
        ) = self._pexpect_complete(data)

        if p_failed:
            raise Exception(f"Process '{argv}' could not be stopped.")

        if data.check and returncode != 0:
            raise Exception(
                f"Process '{argv}' returned {returncode}:\nSTDOUT\n{stdout}"
            )

    def _pexpect_start(
        self,
        command,
        args,
        timeout,
        maxread,
        logfile,
        cwd,
        env,
        encoding,
        codec_errors,
        shell,
    ):
        if logfile is None:
            import tempfile

            logfile = tempfile.NamedTemporaryFile(dir=nmci.util.tmp_dir(), mode="w")
        elif logfile == self.DEV_NULL:
            logfile = open("/dev/null", "w")

        if shell:
            if args:
                args = ["-c", command, "--", "/bin/bash", *args]
            else:
                args = ["-c", command]
            command = "/bin/bash"

        proc = pexpect.spawn(
            command=command,
            args=args,
            timeout=timeout,
            maxread=maxread,
            logfile=logfile,
            cwd=cwd,
            env=env,
            encoding=encoding,
            codec_errors=codec_errors,
        )

        return proc, logfile

    def pexpect_spawn(
        self,
        command,
        args=[],
        timeout=30,
        maxread=2000,
        logfile=None,
        cwd=None,
        env=None,
        encoding="utf-8",
        codec_errors="strict",
        shell=False,
        label=None,
        check=False,
    ):
        """Spawn a process and return the pexpect object. The process is killed at the end of the step.
        If the process is still running, it is killed with SIGTERM first, then with SIGKILL.

        :param command: command to execute
        :type command: str
        :param args: arguments to the command, defaults to []
        :type args: list, optional
        :param timeout: timeout in seconds, defaults to 30
        :type timeout: int, optional
        :param maxread: max bytes to read, defaults to 2000
        :type maxread: int, optional
        :param logfile: logfile to use, defaults to None
        :type logfile: file, optional
        :param cwd: current working directory, defaults to None
        :type cwd: str, optional
        :param env: environment variables, defaults to None
        :type env: dict, optional
        :param encoding: encoding to use, defaults to "utf-8"
        :type encoding: str, optional
        :param codec_errors: codec errors to use, defaults to "strict"
        :type codec_errors: str, optional
        :param shell: use shell, defaults to False
        :type shell: bool, optional
        :param label: label for the process, defaults to None
        :type label: str, optional
        :param check: check the return code, defaults to False
        :type check: bool, optional
        :return: pexpect object
        :rtype: pexpect
        """
        proc, logfile = self._pexpect_start(
            command=command,
            args=args,
            timeout=timeout,
            maxread=maxread,
            logfile=logfile,
            cwd=cwd,
            env=env,
            encoding=encoding,
            codec_errors=codec_errors,
            shell=shell,
        )

        data = PexpectData(
            False, proc, logfile, nmci.embed.get_embed_context("Commands"), label, check
        )

        # These get killed at the end of the step by process_pexpect_spawn().
        self._pexpect_spawn_lst.append(data)
        return proc

    def pexpect_service(
        self,
        command,
        args=[],
        timeout=30,
        maxread=2000,
        logfile=None,
        cwd=None,
        env=None,
        encoding="utf-8",
        codec_errors="strict",
        shell=False,
        label=None,
        check=False,
        cleanup_priority=nmci.Cleanup.PRIORITY_PEXPECT_SERVICE,
    ):
        """
        Spawn a service and return the pexpect object. The service is killed at the end of the scenario.
        If the service is still running, it is killed with SIGTERM first, then with SIGKILL.

        :param command: command to execute
        :type command: str
        :param args: arguments to the command, defaults to []
        :type args: list, optional
        :param timeout: timeout in seconds, defaults to 30
        :type timeout: int, optional
        :param maxread: max bytes to read, defaults to 2000
        :type maxread: int, optional
        :param logfile: logfile to use, defaults to None
        :type logfile: file, optional
        :param cwd: current working directory, defaults to None
        :type cwd: str, optional
        :param env: environment variables, defaults to None
        :type env: dict, optional
        :param encoding: encoding to use, defaults to "utf-8"
        :type encoding: str, optional
        :param codec_errors: codec errors to use, defaults to "strict"
        :type codec_errors: str, optional
        :param shell: use shell, defaults to False
        :type shell: bool, optional
        :param label: label for the service, defaults to None
        :type label: str, optional
        :param check: check the return code, defaults to False
        :type check: bool, optional
        :param cleanup_priority: priority for the cleanup, defaults to nmci.Cleanup.PRIORITY_PEXPECT_SERVICE
        :type cleanup_priority: int, optional
        :return: pexpect object
        :rtype: pexpect
        """
        proc, logfile = self._pexpect_start(
            command=command,
            args=args,
            timeout=timeout,
            maxread=maxread,
            logfile=logfile,
            cwd=cwd,
            env=env,
            encoding=encoding,
            codec_errors=codec_errors,
            shell=shell,
        )

        data = PexpectData(
            True, proc, logfile, nmci.embed.get_embed_context("Commands"), label, check
        )

        self._pexpect_service_lst.append(data)

        # These get reaped during the cleanup at the end of the scenario.

        nmci.cleanup.add_callback(
            callback=lambda: self._pexpect_service_cleanup(data),
            name=f"pexpect {proc.name}",
            unique_tag=nmci.Cleanup.UNIQ_TAG_DISTINCT,
            priority=cleanup_priority,
        )

        return proc

    def process_pexpect_spawn(self):
        """
        Kill all pexpect processes spawned by pexpect_spawn().

        :raises Exception: if some process failed
        """
        argv_failed = []

        for data in nmci.util.consume_list(self._pexpect_spawn_lst):
            (
                p_failed,
                argv,
                returncode,
                stdout,
            ) = self._pexpect_complete(data)
            if p_failed:
                argv_failed.append(f"Process '{argv}' could not be stopped.")
            if data.check and returncode != 0:
                argv_failed.append(
                    f"Process '{argv}' returned {returncode}:\nSTDOUT\n{stdout}"
                )

        if argv_failed:
            msg = "\n".join(argv_failed)
            raise Exception(f"Some process failed:\n{msg}")

    def pexpect_service_find_all(self, label=None, running_only=False):
        """
        Find all pexpect services with a given label.

        :param label: label to search for, defaults to None
        :type label: str, optional
        :param running_only: return only instances that are alive
        :type running_only: bool
        :return: list of pexpect services
        :rtype: list
        """
        for proc in self._pexpect_service_lst:
            if label is not None and proc.label != label:
                continue
            if running_only and not proc.proc.isalive():
                continue
            yield proc


_module = _PExpect()
