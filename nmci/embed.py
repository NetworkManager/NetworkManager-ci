import collections
import os
import traceback

import xml.etree.ElementTree as ET

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


TRACE_COMBINE_TAG = object()
NO_EMBED = object()

MODULE_NAME_TRANSLATIONS = {
    "Ip": "IP",
    "Nmutil": "NM Util",
    "Process": "Commands",
    "Cext": "Commands",
}

MODULES_TO_SKIP = ["Tags"]


class Embed:

    EmbedContext = collections.namedtuple("EmbedContext", ["count", "embed_data"])

    def __init__(self, fail_only=False, combine_tag=None):
        """General Embed

        :param fail_only: whether to embed only if scenario failed, defaults to False
        :type fail_only: bool, optional
        :param combine_tag: join multiple embeds under single caption, defaults to None
        :type combine_tag: str, optional
        """
        self.fail_only = fail_only
        self.combine_tag = combine_tag
        self._data = None
        self._mime_type = None
        self._caption = None

    def evalDoEmbedArgs(self):
        return (self._mime_type, self._data or "NO DATA", self._caption)


class EmbedData(Embed):
    def __init__(
        self, caption, data, mime_type="text/plain", fail_only=False, combine_tag=None
    ):
        """Embed General Data

        :param caption: embed caption
        :type caption: str
        :param data: data to be embedded
        :type data: str
        :param mime_type: mime-type of the data, defaults to "text/plain"
        :type mime_type: str, optional
        :param fail_only: whether to embed only if scenario failed, defaults to False
        :type fail_only: bool, optional
        :param combine_tag: join multiple embeds under single caption, defaults to None
        :type combine_tag: str, optional
        """
        Embed.__init__(self, fail_only=fail_only, combine_tag=combine_tag)
        self._caption = caption
        self._data = data
        self._mime_type = mime_type


class EmbedLink(Embed):
    def __init__(self, caption, data, fail_only=False, combine_tag=None):
        """Embed links

        :param caption: embed caption
        :type caption: str
        :param data: data must be a list of 2-tuples, where the first element, is the link target (href) and the second the text.
        :type data: list of pairs of str
        :param fail_only: whether to embed only if scenario failed, defaults to False
        :type fail_only: bool, optional
        :param combine_tag: join multiple embeds under single caption, defaults to None
        :type combine_tag: str, optional
        """
        Embed.__init__(self, fail_only=fail_only, combine_tag=combine_tag)

        new_data = []
        for d in data:
            (target, text) = d
            new_data.append((target, text))

        self._caption = caption
        self._data = new_data
        self._mime_type = "link"


class _Embed:
    def __init__(self):
        self.coredump_reported = False
        self._embed_count = 0
        self._to_embed = []
        self._html_formatter = None
        self._set_title = None
        self._combine_tags = {}

        self.Embed = Embed
        self.EmbedData = EmbedData
        self.EmbedLink = EmbedLink
        self.TRACE_COMBINE_TAG = TRACE_COMBINE_TAG
        self.NO_EMBED = NO_EMBED

    def setup(self, runner):
        """Save formatter from behave.Runnr object

        :param runner: behave Runner object
        :type runner: behave.Runner
        """
        # setup formatter embed and set_title
        for formatter in runner.formatters:
            if "html" not in formatter.name:
                continue
            if hasattr(formatter, "set_title"):
                self._set_title = formatter.set_title
            if hasattr(formatter, "embed"):
                self._html_formatter = formatter

    def get_embed_context(self, combine_tag):
        """Returns the EmbedContext object for given combine tag, creates new if needed.

        :param combine_tag: caption of joined embeds
        :type combine_tag: str
        :return: EmbedContext object for given combine_tag.
        :rtype: EmbedContext
        """
        if combine_tag == NO_EMBED:
            return Embed.EmbedContext(-1, None)

        self._embed_count += 1
        count = self._embed_count

        embed_data = None
        if combine_tag in self._combine_tags:
            embed_data = self._combine_tags[combine_tag]
        elif self._html_formatter:
            embed_data = self._html_formatter.embed("text/plain", "", combine_tag or "")
            if combine_tag:
                self._combine_tags[combine_tag] = embed_data
        return Embed.EmbedContext(count, embed_data)

    def after_step(self):
        """Sould be called after each step to refresh the combined tags."""
        self._combine_tags = {}

    def set_title(self, *a, **kw):
        """Calls set_title() of the formatter, if supported by formatter."""
        if self._set_title:
            self._set_title(*a, *kw)

    def has_html_formatter(self):
        """Check if HTML formatter is set. This makes sense only after setup() call.

        :return: True if HTML formatter is present.
        :rtype: bool
        """
        return self._html_formatter is not None

    def get_current_scenario(self):
        """Returns the current scenario object of the HTML formatter

        :return: current scenario object in HTML formatter
        :rtype: formatter.Scenario
        """
        if self._html_formatter is None:
            return None
        return self._html_formatter.current_scenario

    def formatter_add_scenario(self, scenario):
        """Register the scenario in formatter.

        This is called if skipped before scenario, because behave then does not
        register the scenario to formatter.

        :param scenario: scenario to be registered in formatter
        :type scenario: behave.Scenario
        """
        if self._html_formatter is None:
            return
        self._html_formatter.scenario(scenario)

    def before_scenario_finish(self, status):
        """
        This is needed as last call of :code:`before_scenario()`
        The purpose of this is to separate embeds between
        scenarios correctly, provide status to the formatter
        and formatter also computes time spend. It is harmless
        when formatter is not using pseudo steps.

        :param status: status of the before scenario
        :type status: str
        """
        if self._html_formatter is None:
            return
        self._html_formatter.before_scenario_finish(status)

    def after_scenario_finish(self, status):
        """
        This is needed as last call of :code:`after_scenario()`
        The purpose of this is to separate embeds between
        scenarios correctly, provide status to the formatter
        and formatter also computes time spend. It is harmless
        when formatter is not using pseudo steps.

        :param status: status of the after scenario
        :type status: str
        """
        if self._html_formatter is None:
            return
        self._html_formatter.after_scenario_finish(status)

    def _get_module_from_trace(self):
        module = "Commands"
        stack = traceback.extract_stack()
        for item in stack:
            if "/nmci/" in item.filename:
                module = item.filename.split("/")[-1].replace(".py", "").capitalize()
                if module in MODULES_TO_SKIP:
                    continue
                break
        if module in MODULE_NAME_TRANSLATIONS:
            module = MODULE_NAME_TRANSLATIONS[module]
        return module

    def _embed_queue(self, entry, embed_context=None):

        if embed_context is None and self._html_formatter:
            embed_context = self.get_embed_context(entry.combine_tag)

        entry._embed_context = embed_context

        self._to_embed.append(entry)

    def _embed_args(self, embed_data, mime_type, data, caption):
        if embed_data:
            embed_data.set_data(mime_type, data, caption)

        if os.environ.get("NMCI_SHOW_EMBED") == "1":
            print(f">>>> EMBED[{mime_type}]: {caption}")
            for line in str(data).splitlines():
                print(f">>>>>> {line}")

    def _embed_mangle_message_for_fail(self, fail_only, mime_type, data):

        if not nmci.util.is_verbose() and fail_only:
            if mime_type != "text/plain":
                return ("text/plain", f"truncated mime_type={mime_type} on success")
            if isinstance(data, str):
                if not nmci.util.is_verbose() and len(data) > 2048:
                    data_split = data.split("\n", 1)
                    if len(data_split) == 2:
                        # embed first line, header of command, truncate header if longer than 2048
                        data_header, data = data_split
                        if len(data_header) > 2048:
                            data_header = f"...{data_header[-2048:]}"
                        data_header = f"{data_header}\n"
                    else:
                        data_header = ""
                    return (
                        mime_type,
                        f"truncated on success\n\n{data_header}...\n{data[-2048:]}",
                    )
            elif isinstance(data, bytes):
                if not nmci.util.is_verbose() and len(data) > 2048:
                    return (
                        mime_type,
                        b"truncated binary on success\n\n...\n" + data[-2048:],
                    )
            else:
                if not nmci.util.is_verbose():
                    return (mime_type, f"truncated non-text {type(data)} on success")
        return (mime_type, data)

    def _embed_one(self, entry):
        (mime_type, data, caption) = entry.evalDoEmbedArgs()
        (mime_type, data) = self._embed_mangle_message_for_fail(
            entry.fail_only, mime_type, data
        )
        self._embed_args(
            entry._embed_context.embed_data,
            mime_type,
            data,
            f"({entry._embed_context.count}) {caption}",
        )

    def _embed_combines(self, combine_tag, embed_data, lst):

        counts = nmci.misc.list_to_intervals(
            [entry._embed_context.count for entry in lst]
        )
        main_caption = f"({counts}) {combine_tag}"
        message = ""
        for entry in lst:
            (mime_type, data, caption) = entry.evalDoEmbedArgs()
            assert mime_type == "text/plain"
            (mime_type, data) = self._embed_mangle_message_for_fail(
                entry.fail_only, mime_type, data
            )
            message += f"{'-'*50}\n({entry._embed_context.count}) {caption}\n{data}\n"
        message += f"{'-'*50}\n"
        self._embed_args(embed_data, "text/plain", message, main_caption)

    def process_embeds(self):
        """This is called in after scenario to process the embeds
        and send data to the HTML formatter (if present).
        """

        combines_dict = {}
        self._to_embed.sort(key=lambda e: e._embed_context.count)
        for entry in nmci.util.consume_list(self._to_embed):
            combine_tag = entry.combine_tag
            if combine_tag is NO_EMBED:
                continue
            if combine_tag is None:
                self._embed_one(entry)
                continue
            key = (combine_tag, entry._embed_context.embed_data)
            lst = combines_dict.get(key, None)
            if lst is None:
                lst = []
                combines_dict[key] = lst
            lst.append(entry)
        for key, lst in combines_dict.items():
            self._embed_combines(key[0], key[1], lst)

    def embed_data(self, *a, embed_context=None, **kw):
        self._embed_queue(EmbedData(*a, **kw), embed_context=embed_context)

    def embed_link(self, *a, embed_context=None, **kw):
        self._embed_queue(EmbedLink(*a, **kw), embed_context=embed_context)

    def embed_dump(self, caption, dump_id, *, data=None, links=None):
        """embed new crash dump

        :param caption: embed caption
        :type caption: str
        :param dump_id: unique ID of the crash
        :type dump_id: str
        :param data: backtrace of the coredump, defaults to None
        :type data: str, optional
        :param links: FAF links to embed, defaults to None
        :type links: list of pairs of str, optional
        """
        print("Attaching %s, %s" % (caption, dump_id))

        assert (data is None) + (links is None) == 1
        if data is not None:
            self.embed_data(caption, data)
        else:
            self.embed_link(caption, links)
        self.coredump_reported = True
        nmci.crash.coredump_report(dump_id)

    def embed_run(
        self,
        argv,
        shell,
        returncode,
        stdout,
        stderr,
        fail_only=True,
        embed_context=None,
        combine_tag=TRACE_COMBINE_TAG,
        elapsed_time=None,
    ):
        """Embed results of a process

        :param argv: arguments of the process
        :type argv: list of str or str
        :param shell: whether executed in shell
        :type shell: bool
        :param returncode: returncode of the process
        :type returncode: int
        :param stdout: STDOUT of the process
        :type stdout: str or binary
        :param stderr: STDERR of the process
        :type stderr: str or binary
        :param fail_only: wheter to embed only if scenario fails, defaults to True
        :type fail_only: bool, optional
        :param embed_context: embed context, defaults to None
        :type embed_context: Embed.EmedContext, optional
        :param combine_tag: caption of joined embeds, defaults to TRACE_COMBINE_TAG, computes caption from stactrace
        :type combine_tag: str, optional
        :param elapsed_time: measured time of process run in seconds, defaults to None
        :type elapsed_time: float, optional
        """

        if stdout is not None:
            try:
                stdout = nmci.util.bytes_to_str(stdout)
            except UnicodeDecodeError:
                pass
        if stderr is not None:
            try:
                stderr = nmci.util.bytes_to_str(stderr)
            except UnicodeDecodeError:
                pass
        shell_str = "(shell) " if shell else ""
        time_str = (
            f" in {nmci.misc.format_duration(elapsed_time)}"
            if elapsed_time is not None
            else ""
        )
        message = f"{repr(argv)} {shell_str}returned {returncode}{time_str}\n"
        if stdout:
            message += (
                f"STDOUT{'[binary]' if isinstance(stderr, bytes) else ''}:\n{stdout}\n"
            )
        if stderr:
            message += (
                f"STDERR{'[binary]' if isinstance(stderr, bytes) else ''}:\n{stderr}\n"
            )

        if isinstance(argv, bytes):
            title = argv.decode("utf-8", errors="replace")
        elif isinstance(argv, str):
            title = argv
        else:
            import shlex

            title = " ".join(
                shlex.quote(nmci.util.bytes_to_str(a, errors="replace")) for a in argv
            )
        if len(argv) < 30:
            title = f"Command `{title}`"
        else:
            title = f"Command `{title[:30]}...`"

        if combine_tag == TRACE_COMBINE_TAG:
            combine_tag = self._get_module_from_trace()

        self.embed_data(
            title,
            message,
            fail_only=fail_only,
            combine_tag=combine_tag,
            embed_context=embed_context,
        )

    def embed_service_log(
        self,
        descr,
        service=None,
        syslog_identifier=None,
        journal_args=None,
        cursor=None,
        fail_only=False,
    ):
        """Embed log of service using journalctl

        :param descr: embed caption
        :type descr: str
        :param service: name of the service to filter out, defaults to None
        :type service: str, optional
        :param syslog_identifier: equivalent to '-u' parameter of journalctl, defaults to None
        :type syslog_identifier: str, optional
        :param journal_args: additional journalctl arguments, defaults to None
        :type journal_args: list of str, optional
        :param cursor: journalctl cursor, defaults to None
        :type cursor: str, optional
        :param fail_only: wheter to embed only if scenario fails, defaults to True
        :type fail_only: bool, optional
        """
        print("embedding " + descr + " logs")

        if cursor is None:
            cursor = nmci.cext.context.log_cursor
        self.embed_data(
            descr,
            nmci.misc.journal_show(
                service=service,
                syslog_identifier=syslog_identifier,
                journal_args=journal_args,
                cursor=cursor,
            ),
            fail_only=fail_only,
        )

    def embed_file_if_exists(
        self,
        caption,
        fname,
        as_base64=False,
        fail_only=False,
    ):
        """Embed file to HTML report

        :param caption: embed caption
        :type caption: str
        :param fname: name of the file to embed
        :type fname: str
        :param as_base64: whether to convert file to base64, defaults to False
        :type as_base64: bool, optional
        :param fail_only: wheter to embed only if scenario fails, defaults to True
        :type fail_only: bool, optional
        :return: True if file exists and embedded, False otherwise
        :rtype: bool
        """

        if not os.path.isfile(fname):
            print("Warning: File " + repr(fname) + " not found")
            return False

        if caption is None:
            caption = fname

        print("embeding " + caption + " log (" + fname + ")")

        if not as_base64:
            data = nmci.util.file_get_content_simple(fname)
            self.embed_data(caption, data, fail_only=fail_only)
            return True

        import base64

        data = nmci.util.file_get_content_simple(fname, as_bytes=True)
        data_base64 = base64.b64encode(data)
        data_encoded = data_base64.decode("utf-8").replace("\n", "")
        data = "data:application/octet-stream;base64," + data_encoded

        self.embed_link(caption, [(data, fname)], fail_only=fail_only)
        return True


_module = _Embed()
