# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
import os
import pyte
import pexpect
import re
import subprocess
from behave import step
from time import sleep
from subprocess import check_output

from steps import command_output, command_code, additional_sleep

OUTPUT = '/tmp/nmtui.out'
TERM_TYPE = 'vt102'

keys = {}
keys['UPARROW'] = "\033\133\101" # <ESC>[A
keys['DOWNARROW'] = "\033\133\102"
keys['RIGHTARROW'] = "\033\133\103"
keys['LEFTARROW'] = "\033\133\104"
keys['INSERT'] = "\033[2~"
keys['DEL'] = "\033[3~"
keys['PGUP'] = "\033[5~"
keys['PGDOWN'] = "\033[6~"
keys['HOME'] = "\033[7~"
keys['END'] = "\033[8~"
keys['PF1'] = "\033\117\120"
keys['PF2'] = "\033\117\121"
keys['PF3'] = "\033\117\122"
keys['PF4'] = "\033\117\123"
keys['ESCAPE'] = "\033"
keys['ENTER'] = "\r\n"
keys['BACKSPACE'] = "\b"
keys['TAB'] = "\t"

keys['F1'] = "\x1b\x5b\x5b\x41"
keys['F2'] = "\x1b\x5b\x5b\x42"
keys['F3'] = "\x1b\x5b\x5b\x43"
keys['F4'] = "\x1b\x5b\x5b\x44"
keys['F5'] = "\x1b\x5b\x5b\x45"
keys['F6'] = "\x1b\x5b\x31\x37\x7e"
keys['F7'] = "\x1b\x5b\x31\x38\x7e"
keys['F8'] = "\x1b\x5b\x31\x39\x7e"
keys['F9'] = "\x1b\x5b\x32\x30\x7e"
keys['F10'] = "\x1b\x5b\x32\x31\x7e"
keys['F11'] = "\x1b\x5b\x32\x33\x7e"
keys['F12'] = "\x1b\x5b\x32\x34\x7e"

def print_screen_wo_cursor(screen):
    for i in range(len(screen.display)):
        print(screen.display[i])

def get_cursored_screen(screen):
    myscreen_display = screen.display
    lst = [item for item in myscreen_display[screen.cursor.y]]
    lst[screen.cursor.x] = '\u2588'
    myscreen_display[screen.cursor.y] = ''.join(lst)
    return myscreen_display

def get_screen_string(screen):
    screen_string = '\n'.join(screen.display)
    return screen_string

def print_screen(screen):
    cursored_screen = get_cursored_screen(screen)
    for i in range(len(cursored_screen)):
        print(cursored_screen[i])

def feed_print_screen(context):
    if os.path.isfile(OUTPUT):
        feed_screen()
    print_screen(context.screen)

# update the screen
def feed_stream(stream):
    if os.path.isfile(OUTPUT):
        stream.feed(open(OUTPUT, 'r').read().encode('utf-8'))

def init_screen():
    stream = pyte.ByteStream()
    screen = pyte.Screen(80, 24)
    stream.attach(screen)
    return stream, screen

def go_until_pattern_matches_line(context, key, pattern, limit=50):
    sleep(0.2)
    feed_stream(context.stream)
    for i in range(0,limit):
        match = re.match(pattern, context.screen.display[context.screen.cursor.y], re.UNICODE)
        if match is not None:
            return match
        else:
            context.tui.send(key)
            sleep(0.3)
            feed_stream(context.stream)
    return None


def go_until_pattern_matches_aftercursor_text(context, key, pattern, limit=50, include_precursor_char=True):
    pre_c = 0
    sleep(0.2)
    feed_stream(context.stream)
    if include_precursor_char is True:
        pre_c = -1
    for i in range(0,limit):
        match = re.match(pattern, context.screen.display[context.screen.cursor.y][context.screen.cursor.x+pre_c:], re.UNICODE)
        print(context.screen.display[context.screen.cursor.y])
        if match is not None:
            return match
        else:
            context.tui.send(key)
            sleep(0.3)
            feed_stream(context.stream)
    return None

def search_all_patterns_in_list(context, patterns, limit=50):
    patterns = list(patterns)  # make local copy
    context.tui.send(keys["UPARROW"]*limit)
    sleep(0.2)
    feed_stream(context.stream)
    for i in range(0,limit):
        for pattern in patterns:
            match = re.match(pattern, context.screen.display[context.screen.cursor.y], re.UNICODE)
            if match is not None:
                patterns.remove(pattern)
                break
        if len(patterns) == 0:
            break
        context.tui.send(keys["DOWNARROW"])
        sleep(0.3)
        feed_stream(context.stream)
    return patterns

@step('Prepare virtual terminal environment')
def prepare_environment(context):
    context.stream, context.screen = init_screen()


@step('Start nmtui')
def start_nmtui(context):
    context.tui = pexpect.spawn('sh -c "TERM=%s nmtui > %s"' % (TERM_TYPE, OUTPUT), encoding='utf-8', codec_errors='ignore')
    for line in context.screen.display:
        if 'NetworkManager TUI' in line:
            break
    sleep(0.2)

@step('Nmtui process is running')
def check_process_running(context):
    assert context.tui.isalive() == True, "NMTUI is down!"


@step('Nmtui process is not running')
def check_process_not_running(context):
    assert context.tui.isalive() == False, "NMTUI (pid:%s) is still up!" % context.tui.pid


@step('Press "{key}" key')
def press_key(context, key):
    context.tui.send(keys[key])
    sleep(0.2)

@step('Come back to the top of editor')
def come_back_to_top(context):
    context.tui.send(keys['UPARROW']*64)

@step('Screen is empty')
def screen_is_empty(context):
    for line in context.screen.display:
        assert re.match('^\s*$', line) is not None, 'Screen not empty on this line:"%s"' % line


@step('Prepare new connection of type "{typ}" named "{name}"')
def prep_conn_abstract(context, typ, name):
    context.execute_steps('''* Start nmtui
                              * Choose to "Edit a connection" from main screen
                              * Choose to "<Add>" a connection
                              * Choose the connection type "%s"
                              * Set "Profile name" field to "%s"''' % (typ, name))


@step('Choose to "{option}" from main screen')
def choose_main_option(context, option):
    context.execute_steps('''* Come back to the top of editor''')
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % option) is not None, "Could not go to option '%s' on screen!" % option
    context.tui.send(keys['ENTER'])
    sleep(0.2)

@step('Choose the connection type "{typ}"')
def select_con_type(context, typ):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % typ) is not None, "Could not go to option '%s' on screen!" % typ
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^<Create>.*$') is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])


@step('Press "{button}" button in the dialog')
def press_dialog_button(context, button):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^ +%s.*$' % button) is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])
    if button == 'Delete':
        sleep(0.5)


@step('Press "{button}" button in the password dialog')
def press_password_dialog_button(context, button):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^%s.*$' % button) is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])


@step('Select connection "{con_name}" in the list')
def select_con_in_list(context, con_name):
    match = re.match('.*Delete.*', get_screen_string(context.screen), re.UNICODE | re.DOTALL)
    if match is not None:
        context.tui.send(keys['LEFTARROW']*8)
        context.tui.send(keys['UPARROW']*16)
    if not go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % con_name):
        assert go_until_pattern_matches_line(context,keys['UPARROW'],r'.*%s.*' % con_name) is not None, "Could not go to connection '%s' on screen!" % con_name


@step('Connections "{con_names}" are in the list')
def all_cons_in_list(context, con_names):
    patterns = search_all_patterns_in_list(context, [r".*%s.*" % name for name in con_names.split(",")])
    assert len(patterns) == 0, "The following list items were not found: " + str(patterns)


@step('Get back to the connection list')
def back_to_con_list(context):
    context.tui.send(keys['LEFTARROW']*8)
    context.tui.send(keys['UPARROW']*32)

@step('Come back to main screen')
def back_to_main(context):
    current_nm_version = "".join(check_output("""NetworkManager -V |awk 'BEGIN { FS = "." }; {printf "%03d%03d%03d", $1, $2, $3}'""", shell=True).decode('utf-8', 'ignore').split('-')[0])
    context.tui.send(keys['ESCAPE'])
    sleep(0.4)
    if current_nm_version < "001003000":
        context.execute_steps('* Start nmtui')

@step('Exit nmtui via "{action}" button')
@step('Choose to "{action}" a slave')
@step('Exit the dialog via "{action}" button')
@step('Choose to "{action}" a connection')
def choose_connection_action(context, action):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'%s.*' % action) is not None, "Could not go to action '%s' on screen!" % action
    sleep(0.1)
    context.tui.send(keys['ENTER'])
    sleep(0.5)


@step('Confirm the route settings')
def confirm_route_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    feed_stream(context.stream)
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> route dialog button!"
    context.tui.send(keys['ENTER'])


@step('Confirm the slave settings')
def confirm_slave_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    feed_stream(context.stream)
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> button! (In form? Segfault?)"
    context.tui.send(keys['ENTER'])


@step('Confirm the connection settings')
def confirm_connection_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    context.tui.send(keys['RIGHTARROW']*3)
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    feed_stream(context.stream)
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> button! (In form? Segfault?)"
    context.tui.send(keys['ENTER'])
    sleep(0.2)
    feed_stream(context.stream)
    for line in context.screen.display:
        print (line)
        if '<Add>' in line:
            break
        else:
            feed_stream(context.stream)


@step('Cannot confirm the connection settings')
def cannot_confirm_connection_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    feed_stream(context.stream)
    match = re.match(r'^<Cancel>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "<OK> button is likely not greyed got: %s at the last line" % match.group(1)


@step('"{pattern}" is visible on screen in "{seconds}" seconds')
@step('"{pattern}" is visible on screen')
def pattern_on_screen(context, pattern, seconds=1):
    match = None
    seconds = int(seconds)
    while seconds and match is None:
        seconds -= 1
        screen = get_screen_string(context.screen)
        match = re.match(pattern, screen, re.UNICODE | re.DOTALL)
        if match is None:
            feed_stream(context.stream)
            sleep(1)
    assert match is not None, "Could not see pattern '%s' on screen:\n\n%s" % (pattern, screen)


@step('"{pattern}" is not visible on screen')
def pattern_not_on_screen(context, pattern):
    match = re.match(pattern, get_screen_string(context.screen), re.UNICODE | re.DOTALL)
    assert match is None, "The pattern is visible '%s' on screen!" % pattern


@step('Set current field to "{value}"')
def set_current_field_to(context, value):
    context.tui.send(keys['BACKSPACE']*100)
    context.tui.send(value)
    sleep(0.2)


@step('Set "{field}" field to "{value}"')
def set_specific_field_to(context, field, value):
    if value == "<noted>":
        value = context.noted['noted-value']
        print(f"setting '{field}' to '{value}'")
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2500-\u2599\s]+%s.*' % field) is not None, "Could not go to option '%s' on screen!" % field
    context.tui.send(keys['BACKSPACE']*100)
    context.tui.send(value)


@step('Empty the field "{field}"')
def empty_specific_field(context, field):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2500-\u2599\s]+%s.*' % field) is not None, "Could not go to option '%s' on screen!" % field
    context.tui.send(keys['BACKSPACE']*100)


@step('In "{prop}" property add "{value}"')
def add_in_property(context, prop, value):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^.*[\u2502\s]+%s <Add.*' % prop) is not None, "Could not find '%s' property!" % prop
    context.tui.send(' ')
    context.tui.send(value)


@step('In this property also add "{value}"')
def add_more_property(context, value):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2502\s]+<Add\.\.\.>.*') is not None, "Could not find the next <Add>"
    context.tui.send(' ')
    context.tui.send(value)


@step('Add ip route "{values}"')
def add_route(context, values):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    assert go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^<Add.*') is not None, "Could not find the routing add button"
    context.tui.send('\r\n')
    for value in values.split():
        context.tui.send(keys['BACKSPACE']*32)
        context.tui.send(value)
        context.tui.send('\t')
    context.execute_steps('* Confirm the route settings')


@step('Cannot add ip route "{values}"')
def cannot_add_route(context, values):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    assert go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^<Add.*') is not None, "Could not find the routing add button"
    context.tui.send('\r\n')
    for value in values.split():
        context.tui.send(keys['BACKSPACE']*32)
        context.tui.send(value)
        context.tui.send('\t')
    context.execute_steps('* Cannot confirm the connection settings')


@step('Remove all routes')
def remove_routes(context):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    while go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^<Remove.*', limit=5) is not None:
        context.tui.send('\r\n')
    context.execute_steps('* Confirm the connection settings')


@step('Remove all "{prop}" property items')
def remove_items(context, prop):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^.*[\u2502\s]+%s.*' % prop) is not None, "Could not find '%s' property!" % prop
    while go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^<Remove.*', limit=2) is not None:
        context.tui.send('\r\n')
    context.tui.send(keys['UPARROW']*2)


@step('Come in "{category}" category')
def come_in_category(context, category):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^.*[\u2550|\u2564]\s%s.*' % category) is not None, "Could not go to category '%s' on screen!" % category
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^(<Hide>|<Show>).*')
    assert match is not None, "Could not go to hide/show for the category %s " % category
    if match.group(1) == '<Show>':
        context.tui.send(' ')


@step('Set "{category}" category to "{setting}"')
def set_category(context, category, setting):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],'^.*[\u2550|\u2564]\s%s.*' % category) is not None, "Could not go to category '%s' on screen!" % category
    context.tui.send(' ')
    context.tui.send(keys['UPARROW']*16)
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^\s*%s\s*\u2502.*' % setting)
    assert match is not None, "Could not find setting %s for the category %s " % (setting, category)
    context.tui.send('\r\n')


@step('Set "{dropdown}" dropdown to "{setting}"')
def set_dropdown(context, dropdown, setting):
    assert go_until_pattern_matches_line(context,keys['TAB'],'^.*\s+%s.*' % dropdown) is not None, "Could not go to dropdown '%s' on screen!" % dropdown
    context.tui.send(' ')
    context.tui.send(keys['UPARROW']*16)
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],'^\s*%s\s*\u2502.*' % setting)
    assert match is not None, "Could not find setting %s for the dropdown %s " % (setting, dropdown)
    context.tui.send('\r\n')


@step('Ensure "{toggle}" is checked')
@step('Ensure "{toggle}" is {n} checked')
def ensure_toggle_is_checked(context, toggle, n=None):
    match = go_until_pattern_matches_line(context,keys['DOWNARROW'],'^[\u2500-\u2599\s]+(\[.\])\s+%s.*' % toggle)
    assert match is not None, "Could not go to toggle '%s' on screen!" % toggle
    if match.group(1) == '[ ]' and n is None:
        context.tui.send(' ')
    elif match.group(1) == '[X]' and n is not None:
        context.tui.send(' ')


@step('Set team json config to "{value}"')
def set_team_json(context, value):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],'^<Edit.*') is not None
    context.tui.send(keys['TAB'])
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],'^<Edit.*') is not None, "Could not find the json edit button"
    sleep(2)
    context.tui.send('\r\n')
    sleep(5)
    context.tui.send('i')
    sleep(5)
    context.tui.send(value)
    sleep(5)
    context.tui.send(keys['ESCAPE'])
    sleep(5)
    context.tui.send(":wq")
    sleep(5)
    context.tui.send('\r\n')
    sleep(5)
