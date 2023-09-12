# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import pexpect
import time
from behave import step


@step("Autoconnect warning is shown")
def autoconnect_warning(context):
    r = context.prompt.expect(
        [
            "Saving the connection with 'autoconnect=yes'. That might result in an immediate activation of the connection.\\s+Do you still want to save?",
            "successfully",
        ]
    )
    assert r == 0, "Autoconnect warning was not shown"


@step("Backspace in editor")
def backspace_in_editor(context):
    context.prompt.send("\b")


@step('Send "{commands}" via editor to "{connection}"')
def send_com_via_editor(context, commands, connection):
    coms = commands.split(";")
    final = "echo -e '"
    for c in coms:
        final = final + "%s\n" % c.strip()
    final = final + "print\nsave\nquit\n' | nmcli c edit %s" % connection
    context.command_output(final)


@step('Send "{what}" in editor')
def send_sth_in_editor(context, what):
    context.prompt.send(what)


@step("Clear the text typed in editor")
def clear_text_typed(context):
    context.prompt.send("\b" * 128)


def check_obj_output_in_editor(context, obj, regexes):
    for opt in regexes:
        context.prompt.sendcontrol("c")
        context.prompt.send("\n")
        context.prompt.send("set %s \t\t" % obj)
        time.sleep(0.25)
        a = context.prompt.expect(["%s" % opt, pexpect.TIMEOUT], timeout=5)
        assert a == 0, "Option %s was not shown!" % opt


@step('Check "{options}" are shown for object "{obj}"')
def check_obj_output_in_editor_options(context, options, obj):
    check_obj_output_in_editor(context, obj, options.split("|"))


@step('Check regex "{regex}" is shown for object "{obj}"')
def check_obj_output_in_editor_regex(context, regex, obj):
    check_obj_output_in_editor(context, obj, [regex])


def check_describe_output_in_editor(context, obj, regexes):
    context.prompt.sendline("describe %s" % obj)
    for opt in regexes:
        assert (
            context.prompt.expect(["%s" % opt, pexpect.TIMEOUT], timeout=5) == 0
        ), f'Option "{opt}" was not described!\nPexpect: {context.prompt}'


@step('Check "{options}" are present in describe output for object "{obj}"')
def check_describe_output_in_editor_options(context, options, obj):
    check_describe_output_in_editor(context, obj, options.split("|"))


@step('Check regex "{regex}" in describe output for object "{obj}"')
def check_describe_output_in_editor_regex(context, regex, obj):
    check_describe_output_in_editor(context, obj, [regex])


@step("Check value saved message showed in editor")
def check_saved_in_editor(context):
    context.prompt.expect("successfully")


@step('Delete connection "{name}" and hit enter')
def delete_connection_with_enter(context, name):
    assert context.command_code("nmcli connection delete id %s" % name) == 0
    time.sleep(5)
    context.prompt.send("\n")
    time.sleep(2)
    assert context.prompt.isalive() is True, "Something went wrong"


@step("Enter in editor")
def enter_in_editor(context):
    context.prompt.send("\n")


@step('Expect "{what}"')
def expect(context, what):
    context.prompt.expect(what)


@step("Error appeared in editor")
@step('Error appeared in editor in "{seconds}" seconds')
def error_appeared_in_editor(context, seconds=0):
    timeout = int(seconds)
    if timeout > 0:
        r = context.prompt.expect(
            ["Error", pexpect.TIMEOUT, pexpect.EOF], timeout=timeout
        )
    else:
        r = context.prompt.expect(["Error", pexpect.TIMEOUT, pexpect.EOF])
        timeout = context.prompt.timeout
    assert r == 0, (
        "Did not see an Error in editor - reason: %s" % ["Error", "TIMEOUT", "EOF"][r]
    )


@step('Error type "{type}" shown in editor')
def check_error_in_editor(context, type):
    context.prompt.expect("%s" % type)


@step('Error type "{type}" while saving in editor')
def check_error_while_saving_in_editor(context, type):
    context.prompt.expect("%s" % type)


@step("Mode missing message shown in editor")
def mode_missing_in_editor(context):
    context.prompt.expect(
        "Error: connection verification failed: bond.options: mandatory option 'mode' is missing"
    )


@step("No error appeared in editor")
def no_error_appeared_in_editor(context):
    r = context.prompt.expect(
        [pexpect.TIMEOUT, pexpect.EOF, "Error", "CRITICAL"], timeout=1
    )
    assert r != 2, "Got an Error in editor"
    assert r != 3, "Got a CRITICAL warning in editor"


@step('Note the "{prop}" property from editor print output')
def note_print_property(context, prop):
    category, item = prop.split(".")
    context.prompt.sendline("print %s" % category)
    context.prompt.expect("%s.%s:\\s+(\\S+)" % (category, item))

    if not hasattr(context, "noted"):
        context.noted = {}
    context.noted["noted-value"] = context.prompt.match.group(1)


@step('Open editor for connection "{con_name}"')
def open_editor_for_connection(context, con_name):
    time.sleep(0.2)
    prompt = context.pexpect_service("/bin/nmcli connection ed %s" % con_name)
    context.prompt = prompt
    r = prompt.expect([con_name, "Error"])
    assert r == 0, "Got an Error while opening profile %s\n%s%s" % (
        con_name,
        prompt.after,
        prompt.buffer,
    )


@step('Open editor for "{con_name}" with timeout')
def open_editor_for_connection_with_timeout(context, con_name):
    prompt = context.pexpect_service(
        "nmcli connection ed %s" % (con_name), maxread=6000, timeout=5
    )
    time.sleep(2)
    context.prompt = prompt
    r = prompt.expect(["Error", con_name])
    assert r == 1, "Got an Error while opening profile %s\n%s%s" % (
        con_name,
        prompt.after,
        prompt.buffer,
    )


@step('Open editor for new connection "{con_name}" type "{type}"')
def open_editor_for_connection_type(context, con_name, type):
    prompt = context.pexpect_service(
        "nmcli connection ed type %s con-name %s" % (type, con_name), maxread=6000
    )
    context.prompt = prompt
    time.sleep(1)
    r = prompt.expect(["nmcli interactive connection editor", "Error"])
    assert r == 0, "Got an Error while opening %s profile %s\n%s%s" % (
        type,
        con_name,
        prompt.after,
        prompt.buffer,
    )


@step("Open editor for a new connection")
def open_editor_for_new_connection(context):
    prompt = context.pexpect_service("nmcli connection edit")
    context.prompt = prompt


@step('Open editor for a type "{typ}"')
def open_editor_for_a_type(context, typ):
    prompt = context.pexpect_service(
        "nmcli connection edit type %s con-name %s0" % (typ, typ)
    )
    context.prompt = prompt


@step('Open interactive connection addition mode for a type "{typ}"')
def open_interactive_for_a_type(context, typ):
    prompt = context.pexpect_service("nmcli -a connection add type %s" % typ, timeout=5)
    context.prompt = prompt


@step("Open interactive connection addition mode")
def open_interactive(context):
    prompt = context.pexpect_service("nmcli -a connection add", timeout=5)
    context.prompt = prompt


@step("Open wizard for adding new connection")
def add_novice_connection(context):
    prompt = context.pexpect_service("nmcli -a connection add")
    context.prompt = prompt


@step("Print in editor")
def print_in_editor(context):
    context.prompt.sendline("print")


@step("Prompt is not running")
def prompt_is_not_running(context):
    time.sleep(0.2)
    if context.prompt.pid:
        prompt = False
        for x in range(1, 4):
            prompt = context.prompt.isalive()
            if not prompt:
                break
            time.sleep(0.5)
        assert prompt is False
    else:
        return True


@step("Quit editor")
def quit_editor(context):
    context.prompt.sendline("quit")
    # VVV We shouldn't go lower here
    time.sleep(0.3)


@step("Save in editor")
def save_in_editor(context):
    context.prompt.sendline("save")
    time.sleep(0.2)


@step("See Error while saving in editor")
def check_error_while_saving_in_editor_2(context):
    context.prompt.expect("Error")


@step('Set a property named "{name}" to "{value}" in editor')
def set_property_in_editor(context, name, value):
    if value == "noted-value":
        context.prompt.sendline("set %s %s" % (name, context.noted[value]))
    else:
        context.prompt.sendline("set %s %s" % (name, value))
    time.sleep(0.25)


@step('Submit "{what}"')
def submit(context, what):
    if what == "noted-value":
        context.prompt.sendline(context.noted["noted-value"])
    elif what == "<enter>":
        context.prompt.send("\n")
    elif what == "<tab>":
        context.prompt.send("\t")
    elif what == "<double_tab>":
        context.prompt.send("\t\t")
    else:
        context.prompt.sendline(what)


@step('Submit "{command}" in editor')
def submit_in_editor(context, command):
    command = command.replace("\\", "")
    context.prompt.sendline("%s" % command)


@step("Dismiss IP configuration in editor")
def dismiss_in_editor(context):
    cpl = context.prompt.compile_pattern_list(
        [
            "There are \\d+ optional settings for IPv4 protocol.",
            "Do you want to add IP addresses?",
        ]
    )
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps('* Submit "no" in editor')
    context.execute_steps('* Submit "no" in editor')


@step("Dismiss Proxy configuration in editor")
def dismiss_proxy_in_editor(context):
    cpl = context.prompt.compile_pattern_list(
        ["There are \\d+ optional settings for Proxy.", pexpect.EOF]
    )
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps('* Submit "no" in editor')


@step("Agree to add IPv4 configuration in editor")
def agree4_in_editor(context):
    context.prompt.compile_pattern_list(
        [
            "There are \\d+ optional settings for IPv4 protocol.",
            "Do you want to add IP addresses?",
        ]
    )
    context.execute_steps(
        """
        * Submit "yes" in editor
        * Expect "IPv4 address"
    """
    )


@step("Agree to add IPv6 configuration in editor")
def agree6_in_editor(context):
    cpl = context.prompt.compile_pattern_list(
        ["There are \\d+ optional settings for IPv6 protocol.", "IPv6 address"]
    )
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps(
            """
            * Submit "yes" in editor
            * Expect "IPv6 address"
        """
        )


@step("Submit team '{command}' in editor")
def submit_team_command_in_editor(context, command):
    context.prompt.sendline("%s" % command)


@step('Spawn "{command}" command')
def spawn_command(context, command):
    context.prompt = context.pexpect_service(command)


@step("Value saved message showed in editor")
def check_showed_in_editor(context):
    context.prompt.expect("successfully")


@step('"{value}" appeared in editor')
def value_appeared_in_editor(context, value):
    r = context.prompt.expect([value, pexpect.TIMEOUT, pexpect.EOF])
    assert r == 0, 'Did not see "%s" in editor' % value


@step("Wrong bond options message shown in editor")
def wrong_bond_options_in_editor(context):
    context.prompt.expect("Error: failed to set 'options' property:")


@step('Check if object item "{item}" has value "{value}" via print')
def value_printed(context, item, value):
    context.prompt.sendline("print")
    # time.sleep(2)
    if value == "current_time":
        t_int = int(time.time())
        t_str = str(t_int)
        value = t_str[:-3]
        print(value)

    context.prompt.expect("%s:\\s+%s" % (item, value))
    print(context.prompt)
