import pexpect

import nmci.embed
import nmci.util
import nmci.process
import nmci.cleanup


class PexpectData:
    def __init__(self, is_service, proc, logfile, embed_context, label):
        self.is_service = is_service
        self.proc = proc
        self.logfile = logfile
        self.embed_context = embed_context
        self.label = label


class _PExpect:
    def __init__(self):
        self._pexpect_spawn_lst = []
        self._pexpect_service_lst = []
        self.EOF = pexpect.EOF
        self.TIMEOUT = pexpect.TIMEOUT

    def _pexpect_complete(self, data):
        proc = data.proc
        failed = False
        status = 0
        if proc.status is None:
            proc.kill(15)
            if proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1:
                proc.kill(9)
        # this sets proc status if killed, if exception, something very wrong happened
        if proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1:
            failed = True
            nmci.embed.embed_data("DEBUG: ps aufx", nmci.process.run_stdout("ps aufx"))
        if not status:
            status = proc.status
        # TODO: make the tests capable of this change
        # if not failed:
        #     failed = status != 0
        stdout = nmci.util.file_get_content_simple(data.logfile.name)
        data.logfile.close()

        argv = "pexpect:" + proc.name

        nmci.embed.embed_run(
            argv,
            True,
            status,
            stdout,
            None,
            embed_context=data.embed_context,
        )

        return failed, argv, status, stdout

    def _pexpect_service_cleanup(self, data):

        self._pexpect_service_lst.remove(data)

        (
            p_failed,
            argv,
            returncode,
            stdout,
        ) = self._pexpect_complete(data)

        if p_failed:
            raise Exception(f"process failed: {argv}")

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
    ):
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

        data = PexpectData(False, proc, logfile, nmci.embed.get_embed_context(), label)

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
        cleanup_priority=nmci.cleanup.Cleanup.PRIORITY_PEXPECT_SERVICE,
    ):
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

        data = PexpectData(True, proc, logfile, nmci.embed.get_embed_context(), label)

        self._pexpect_service_lst.append(data)

        # These get reaped during the cleanup at the end of the scenario.

        nmci.cleanup.cleanup_add(
            callback=lambda: self._pexpect_service_cleanup(data),
            name=f"pexpect {proc.name}",
            unique_tag=nmci.cleanup.Cleanup.UNIQ_TAG_DISTINCT,
            priority=cleanup_priority,
        )

        return proc

    def process_pexpect_spawn(self):

        argv_failed = None

        for data in nmci.util.consume_list(self._pexpect_spawn_lst):
            (
                p_failed,
                argv,
                returncode,
                stdout,
            ) = self._pexpect_complete(data)
            if argv_failed is None and p_failed:
                argv_failed = argv

        if argv_failed:
            raise Exception(f"Some process failed: {argv_failed}")

    def pexpect_service_find_all(self, label=None):
        for proc in self._pexpect_service_lst:
            if label is not None and proc.label != label:
                continue
            yield proc
