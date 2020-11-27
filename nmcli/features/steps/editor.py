import os
import pexpect
import re
import subprocess
import time
from behave import step

from steps import command_output, command_code, additional_sleep


@step(u'Autoconnect warning is shown')
def autoconnect_warning(context):
    r = context.prompt.expect(["Saving the connection with \'autoconnect=yes\'. That might result in an immediate activation of the connection.\s+Do you still want to save?", "successfully"])
    if r != 0:
        raise Exception('Autoconnect warning was not shown')


@step(u'Backspace in editor')
def backspace_in_editor(context):
    context.prompt.send('\b')


@step(u'Send "{commands}" via editor to "{connection}"')
def send_com_via_editor(context, commands, connection):
    coms = commands.split(';')
    final = "echo -e '"
    for c in coms:
        final = final+"%s\n" % c.strip()
    final = final+"print\nsave\nquit\n' | nmcli c edit %s" %connection
    command_output(context, final)

@step(u'Send "{what}" in editor')
def send_sth_in_editor(context, what):
    context.prompt.send(what)


@step(u'Clear the text typed in editor')
def clear_text_typed(context):
    context.prompt.send("\b"*128)


@step(u'Check "{options}" are shown for object "{obj}"')
def check_describe_output_in_editor(context, options, obj):
    options = options.split('|')
    for opt in options:
        context.prompt.sendcontrol('c')
        context.prompt.send('\n')
        context.prompt.send('set %s \t\t' % obj)
        time.sleep(0.25)
        a =  context.prompt.expect(["%s" % opt, pexpect.TIMEOUT], timeout=5)
        assert a == 0 , "Option %s was not shown!" % opt


@step(u'Check "{options}" are present in describe output for object "{obj}"')
def check_describe_output_in_editor(context, options, obj):
    options = options.split('|')
    context.prompt.sendline('describe %s' % obj)
    for opt in options:
        assert context.prompt.expect(["%s" % opt, pexpect.TIMEOUT], timeout=5) == 0 , "Option %s was not described!" % opt


@step(u'Check value saved message showed in editor')
def check_saved_in_editor(context):
    context.prompt.expect('successfully')


@step(u'Delete connection "{name}" and hit enter')
def delete_connection_with_enter(context, name):
    command_code(context, 'nmcli connection delete id %s' %name)
    time.sleep(5)
    context.prompt.send('\n')
    time.sleep(2)
    assert context.prompt.isalive() is True, 'Something went wrong'


@step(u'Enter in editor')
def enter_in_editor(context):
    context.prompt.send('\n')


@step(u'Expect "{what}"')
def expect(context, what):
    context.prompt.expect(what)


@step(u'Error appeared in editor')
@step(u'Error appeared in editor in "{seconds}" seconds')
def error_appeared_in_editor(context, seconds=0):
    timeout = int(seconds)
    if timeout > 0:
        r = context.prompt.expect(['Error', pexpect.TIMEOUT, pexpect.EOF], timeout=timeout)
    else:
        r = context.prompt.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
        timeout = context.prompt.timeout
    if r == 2 or r == 1:
        if r == 1:
            reason = "timeout %ds" % timeout
        elif r == 2:
            reason = "EOF"
        raise Exception('Did not see an Error in editor - reason: %s' % reason)


@step(u'Error type "{type}" shown in editor')
def check_error_in_editor(context, type):
    context.prompt.expect("%s" % type)


@step(u'Error type "{type}" while saving in editor')
def check_error_while_saving_in_editor(context, type):
    context.prompt.expect("%s" % type)


@step(u'Mode missing message shown in editor')
def mode_missing_in_editor(context):
    context.prompt.expect("Error: connection verification failed: bond.options: mandatory option 'mode' is missing")


@step(u'No error appeared in editor')
def no_error_appeared_in_editor(context):
    r = context.prompt.expect([pexpect.TIMEOUT, pexpect.EOF, 'Error', 'CRITICAL'], timeout=1)
    if r == 2:
        raise Exception('Got an Error in editor')
    if r == 3:
        raise Exception('Got a CRITICAL warning in editor')


@step(u'Note the "{prop}" property from editor print output')
def note_print_property(context, prop):
    category, item = prop.split('.')
    context.prompt.sendline('print %s' % category)
    context.prompt.expect('%s.%s:\s+(\S+)' % (category, item))

    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = context.prompt.match.group(1)

@step(u'Open editor for connection "{con_name}"')
def open_editor_for_connection(context, con_name):
    time.sleep(0.2)
    prompt = pexpect.spawn('/bin/nmcli connection ed %s' % con_name, logfile=context.log, encoding='utf-8')
    context.prompt = prompt
    r = prompt.expect([con_name, 'Error'])
    if r == 1:
        raise Exception('Got an Error while opening profile %s\n%s%s' % (con_name, prompt.after, prompt.buffer))


@step(u'Open editor for "{con_name}" with timeout')
def open_editor_for_connection_with_timeout(context, con_name):
    prompt = pexpect.spawn('nmcli connection ed %s' % (con_name), logfile=context.log, maxread=6000, timeout=5, encoding='utf-8')
    time.sleep(2)
    context.prompt = prompt
    r = prompt.expect(['Error', con_name])
    if r == 0:
        raise Exception('Got an Error while opening profile %s\n%s%s' % (con_name, prompt.after, prompt.buffer))


@step(u'Open editor for new connection "{con_name}" type "{type}"')
def open_editor_for_connection_type(context, con_name, type):
    prompt = pexpect.spawn('nmcli connection ed type %s con-name %s' % (type, con_name), logfile=context.log, maxread=6000, encoding='utf-8')
    context.prompt = prompt
    time.sleep(1)
    r = prompt.expect(['nmcli interactive connection editor','Error'])
    if r != 0:
        raise Exception('Got an Error while opening  %s profile %s\n%s%s' % (type, con_name, prompt.after, prompt.buffer))

@step(u'Open editor for a new connection')
def open_editor_for_new_connection(context):
    prompt = pexpect.spawn('nmcli connection edit', logfile=context.log, encoding='utf-8')
    context.prompt = prompt

@step(u'Open editor for a type "{typ}"')
def open_editor_for_a_type(context, typ):
    prompt = pexpect.spawn('nmcli connection edit type %s con-name %s0' % (typ, typ), logfile=context.log, encoding='utf-8')
    context.prompt = prompt


@step(u'Open interactive connection addition mode for a type "{typ}"')
def open_interactive_for_a_type(context, typ):
    prompt = pexpect.spawn('nmcli -a connection add type %s' % typ, timeout = 5, logfile=context.log, encoding='utf-8')
    context.prompt = prompt


@step(u'Open interactive connection addition mode')
def open_interactive(context):
    prompt = pexpect.spawn('nmcli -a connection add', timeout = 5, logfile=context.log, encoding='utf-8')
    context.prompt = prompt


@step(u'Open wizard for adding new connection')
def add_novice_connection(context):
    prompt = pexpect.spawn("nmcli -a connection add", logfile=context.log, encoding='utf-8')
    context.prompt = prompt


@step(u'Print in editor')
def print_in_editor(context):
    context.prompt.sendline('print')


@step(u'Prompt is not running')
def prompt_is_not_running(context):
    time.sleep(0.2)
    if context.prompt.pid:
        prompt = False
        for x in range(1,4):
            prompt = context.prompt.isalive()
            if not prompt:
                break
            time.sleep(0.5)
        assert prompt is False
    else:
        return True


@step(u'Quit editor')
def quit_editor(context):
    context.prompt.sendline('quit')
    # VVV We shouldn't go lower here
    time.sleep(0.3)


@step(u'Save in editor')
def save_in_editor(context):
    context.prompt.sendline('save')
    time.sleep(0.2)


@step(u'See Error while saving in editor')
def check_error_while_saving_in_editor_2(context):
    context.prompt.expect("Error")


@step(u'Set a property named "{name}" to "{value}" in editor')
def set_property_in_editor(context, name, value):
    if value == 'noted-value':
        context.prompt.sendline('set %s %s' % (name,context.noted[value]))
    else:
        context.prompt.sendline('set %s %s' % (name,value))
    time.sleep(0.25)


@step(u'Submit "{what}"')
def submit(context, what):
    if what == 'noted-value':
        context.prompt.sendline(context.noted['noted-value'])
    elif what == '<enter>':
        context.prompt.send("\n")
    elif what == '<tab>':
        context.prompt.send("\t")
    elif what == '<double_tab>':
        context.prompt.send("\t\t")
    else:
        context.prompt.sendline(what)


@step(u'Submit "{command}" in editor')
def submit_in_editor(context, command):
    command = command.replace('\\','')
    context.prompt.sendline("%s" % command)


@step(u'Dismiss IP configuration in editor')
def dismiss_in_editor(context):
    cpl = context.prompt.compile_pattern_list(['There are \d+ optional settings for IPv4 protocol.',
                                               'Do you want to add IP addresses?'])
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps(u'* Submit "no" in editor')
    context.execute_steps(u'* Submit "no" in editor')


@step(u'Dismiss Proxy configuration in editor')
def dismiss_in_editor(context):
    cpl = context.prompt.compile_pattern_list(['There are \d+ optional settings for Proxy.', pexpect.EOF])
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps(u'* Submit "no" in editor')


@step(u'Agree to add IPv4 configuration in editor')
def dismiss_in_editor(context):
    cpl = context.prompt.compile_pattern_list(['There are \d+ optional settings for IPv4 protocol.',
                                               'Do you want to add IP addresses?'])
    context.execute_steps(u"""
        * Submit "yes" in editor
        * Expect "IPv4 address"
    """)


@step(u'Agree to add IPv6 configuration in editor')
def dismiss_in_editor(context):
    cpl = context.prompt.compile_pattern_list(['There are \d+ optional settings for IPv6 protocol.',
                                               'IPv6 address'])
    if context.prompt.expect_list(cpl) == 0:
        context.execute_steps(u"""
            * Submit "yes" in editor
            * Expect "IPv6 address"
        """)


@step(u'Submit team \'{command}\' in editor')
def submit_team_command_in_editor(context, command):
    context.prompt.sendline('%s' % command)


@step(u'Spawn "{command}" command')
def spawn_command(context, command):
    context.prompt = pexpect.spawn(command, logfile=context.log, encoding='utf-8')
    if not hasattr(context, 'spawned_processes'):
        context.spawned_processes = {}
    context.spawned_processes[command] = context.prompt


@step(u'Value saved message showed in editor')
def check_saved_in_editor(context):
    context.prompt.expect('successfully')


@step(u'"{value}" appeared in editor')
def value_appeared_in_editor(context, value):
    r = context.prompt.expect([value, pexpect.TIMEOUT, pexpect.EOF])
    if r == 2 or r == 1:
        raise Exception('Did not see "%s" in editor' % value)


@step(u'Wrong bond options message shown in editor')
def wrong_bond_options_in_editor(context):
    context.prompt.expect("Error: failed to set 'options' property:")


@step(u'Check if object item "{item}" has value "{value}" via print')
def value_printed(context, item, value):
    context.prompt.sendline('print')
    #time.sleep(2)
    if value == "current_time":
        t_int = int(time.time())
        t_str = str(t_int)
        value = t_str[:-3]
        print (value)

    context.prompt.expect('%s\s+%s' %(item, value))
    print (context.prompt)
