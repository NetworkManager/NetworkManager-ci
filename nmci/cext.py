import subprocess

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _CExt:
    """Context Extenstion object
    Remembers the current behave context and implements
    basic operations over it.
    """

    def __init__(self):
        self.context = None
        self.scenario_skipped = False

    def setup(self, context):
        """Setup context formatter, commands, and save context.

        :param context: behave context object
        :type context: behave.Context
        """
        assert not hasattr(context, "embed")
        assert not hasattr(context, "cext")

        self.context = context

        if hasattr(context, "_runner"):
            nmci.embed.setup(context._runner)

        context.process = nmci.process
        context.util = nmci.util
        context.cext = self
        context.ifindex = 600

        def _run(command, *a, **kw):
            def _shell(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                encoding="utf-8",
                errors="ignore",
                *a,
                **kw,
            ):
                return shell

            shell = _shell(command, *a, **kw)

            out, err, code = nmci.run.run(command, *a, **kw)
            nmci.embed.embed_run(
                command,
                shell,
                code,
                out,
                err,
            )
            return out, err, code

        def _command_output(command, *a, **kw):
            out, err, code = _run(command, *a, **kw)
            assert code == 0, "command '%s' exited with code %d" % (command, code)
            return out

        def _command_output_err(command, *a, **kw):
            out, err, code = _run(command, *a, **kw)
            assert code == 0, "command '%s' exited with code %d" % (command, code)
            return out, err

        def _command_code(command, *a, **kw):
            out, err, code = _run(command, *a, **kw)
            return code

        context.command_code = _command_code
        context.run = _run
        context.command_output = _command_output
        context.command_output_err = _command_output_err
        context.pexpect_spawn = lambda *a, **kw: nmci.pexpect.pexpect_spawn(*a, **kw)
        context.pexpect_service = lambda *a, **kw: nmci.pexpect.pexpect_service(
            *a, **kw
        )

    def skip(self, msg=""):
        """Skip scenario and stop executing (raise SkipTestException).

        :param msg: Reason of skip, defaults to ""
        :type msg: str, optional
        :raises nmci.misc.SkipTestException: Interupts further code execution
        """
        if msg:
            nmci.embed.embed_data("Skip message", msg)
        self.context.scenario.skip(msg)
        self.scenario_skipped = True
        raise nmci.misc.SkipTestException(msg)


_module = _CExt()
