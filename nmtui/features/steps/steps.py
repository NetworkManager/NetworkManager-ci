#!/usr/bin/python

import os
import pyte
import pexpect
import re
import subprocess
from behave import step
from time import sleep
from subprocess import check_output

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
        print(screen.display[i].encode('utf-8'))

def get_cursored_screen(screen):
    myscreen_display = screen.display
    lst = [item for item in myscreen_display[screen.cursor.y]]
    lst[screen.cursor.x] = u'\u2588'
    myscreen_display[screen.cursor.y] = u''.join(lst)
    return myscreen_display

def get_screen_string(screen):
    screen_string = u'\n'.join(screen.display)
    return screen_string

def print_screen(screen):
    cursored_screen = get_cursored_screen(screen)
    for i in range(len(cursored_screen)):
        print(cursored_screen[i].encode('utf-8'))

def feed_print_screen(context):
    if os.path.isfile('/tmp/nmtui.out'):
        context.stream.feed(open('/tmp/nmtui.out', 'r').read())
    print_screen(context.screen)

def feed_stream(stream):
    stream.feed(open(OUTPUT, 'r').read())

def init_screen():
    stream = pyte.ByteStream()
    screen = pyte.Screen(80, 24)
    stream.attach(screen)
    return stream, screen

def go_until_pattern_matches_line(context, key, pattern, limit=50):
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    for i in range(0,limit):
        match = re.match(pattern, context.screen.display[context.screen.cursor.y], re.UNICODE)
        if match is not None:
            return match
        else:
            context.tui.send(key)
            sleep(0.3)
            context.stream.feed(open(OUTPUT, 'r').read())
    return None


def go_until_pattern_matches_aftercursor_text(context, key, pattern, limit=50, include_precursor_char=True):
    pre_c = 0
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    if include_precursor_char is True:
        pre_c = -1
    for i in range(0,limit):
        match = re.match(pattern, context.screen.display[context.screen.cursor.y][context.screen.cursor.x+pre_c:], re.UNICODE)
        print(context.screen.display[context.screen.cursor.y].encode('utf-8'))
        if match is not None:
            return match
        else:
            context.tui.send(key)
            sleep(0.3)
            context.stream.feed(open(OUTPUT, 'r').read())
    return None

def dump_command_output(command):
    if not os.path.isfile('/tmp/tui-screen.log'):
        return
    fd = open('/tmp/tui-screen.log', 'a+')
    fd.write("----------\nInfo: next failed step's '%s' output:\n" % command)
    fd.flush()
    subprocess.call(command, shell=True, stdout=fd)
    fd.write("\n")
    fd.flush()
    fd.close()

@step('Prepare virtual terminal environment')
def prepare_environment(context):
    context.stream, context.screen = init_screen()


@step(u'Start nmtui')
def start_nmtui(context):
    context.tui = pexpect.spawn('sh -c "TERM=%s nmtui > %s"' % (TERM_TYPE, OUTPUT))
    sleep(3)


@step(u'Nmtui process is running')
def check_process_running(context):
    assert context.tui.isalive() == True, "NMTUI is down!"


@step(u'Nmtui process is not running')
def check_process_not_running(context):
    assert context.tui.isalive() == False, "NMTUI (pid:%s) is still up!" % context.tui.pid


@step(u'Main screen is visible')
def can_see_welcome_screen(context):
    for line in context.screen.display:
        if 'NetworkManager TUI' in line:
            return
    assert False, "Could not read the main screen in output"


@step(u'Press "{key}" key')
def press_key(context, key):
    context.tui.send(keys[key])

@step(u'Come back to the top of editor')
def come_back_to_top(context):
    context.tui.send(keys['UPARROW']*64)

@step(u'Screen is empty')
def screen_is_empty(context):
    for line in context.screen.display:
        assert re.match('^\s*$', line) is not None, 'Screen not empty on this line:"%s"' % line


@step(u'Prepare new connection of type "{typ}" named "{name}"')
def prep_conn_abstract(context, typ, name):
    context.execute_steps(u'''* Start nmtui
                              * Choose to "Edit a connection" from main screen
                              * Choose to "<Add>" a connection
                              * Choose the connection type "%s"
                              * Set "Profile name" field to "%s"''' % (typ, name))


@step(u'Choose to "{option}" from main screen')
def choose_main_option(context, option):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % option) is not None, "Could not go to option '%s' on screen!" % option
    context.tui.send(keys['ENTER'])


@step(u'Choose the connection type "{typ}"')
def select_con_type(context, typ):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % typ) is not None, "Could not go to option '%s' on screen!" % typ
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^<Create>.*$') is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])


@step(u'Press "{button}" button in the dialog')
def press_dialog_button(context, button):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^ +%s.*$' % button) is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])


@step(u'Press "{button}" button in the password dialog')
def press_password_dialog_button(context, button):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'^%s.*$' % button) is not None, "Could not go to action '<Create>' on screen!"
    context.tui.send(keys['ENTER'])


@step(u'Select connection "{con_name}" in the list')
def select_con_in_list(context, con_name):
    match = re.match('.*Delete.*', get_screen_string(context.screen), re.UNICODE | re.DOTALL)
    if match is not None:
        context.tui.send(keys['LEFTARROW']*8)
        context.tui.send(keys['UPARROW']*16)
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],r'.*%s.*' % con_name) is not None, "Could not go to connection '%s' on screen!" % con_name


@step(u'Get back to the connection list')
def back_to_con_list(context):
    context.tui.send(keys['LEFTARROW']*8)
    context.tui.send(keys['UPARROW']*32)

@step(u'Come back to main screen')
def back_to_main(context):
    current_nm_version = "".join(check_output("""NetworkManager -V |awk 'BEGIN { FS = "." }; {printf "%03d%03d%03d", $1, $2, $3}'""", shell=True).split('-')[0])
    context.tui.send(keys['ESCAPE'])
    if current_nm_version < "001003000":
        context.execute_steps(u'* Start nmtui')

@step(u'Exit nmtui via "{action}" button')
@step(u'Choose to "{action}" a slave')
@step(u'Exit the dialog via "{action}" button')
@step(u'Choose to "{action}" a connection')
def choose_connection_action(context, action):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],r'%s.*' % action) is not None, "Could not go to action '%s' on screen!" % action
    context.tui.send(keys['ENTER'])
    sleep(0.5)


@step(u'Bring up connection "{connection}"')
def bring_up_connection(context, connection):
    cli = pexpect.spawn('nmcli connection up %s' % connection, timeout = 180)
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while upping connection %s' % connection)
    elif r == 1:
        raise Exception('nmcli connection up %s timed out (180s)' % connection)


@step(u'Bring up connection "{connection}" ignoring everything')
def bring_up_connection_ignore_everything(context, connection):
    subprocess.Popen('nmcli connection up %s' % connection, shell=True)
    sleep(1)


@step(u'Confirm the route settings')
def confirm_route_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> route dialog button!"
    context.tui.send(keys['ENTER'])


@step(u'Confirm the slave settings')
def confirm_slave_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> button! (In form? Segfault?)"
    context.tui.send(keys['ENTER'])


@step(u'Confirm the connection settings')
def confirm_connection_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    match = re.match(r'^<OK>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "Could not get to the <OK> button! (In form? Segfault?)"
    context.tui.send(keys['ENTER'])


@step(u'Cannot confirm the connection settings')
def cannot_confirm_connection_screen(context):
    context.tui.send(keys['DOWNARROW']*64)
    sleep(0.2)
    context.stream.feed(open(OUTPUT, 'r').read())
    match = re.match(r'^<Cancel>.*', context.screen.display[context.screen.cursor.y][context.screen.cursor.x-1:], re.UNICODE)
    assert match is not None, "<OK> button is likely not greyed got: %s at the last line" % match.group(1)


@step(u'"{pattern}" is visible on screen')
def pattern_on_screen(context, pattern):
    match = re.match(pattern, get_screen_string(context.screen), re.UNICODE | re.DOTALL)
    assert match is not None, "Could see pattern '%s' on screen!" % pattern


@step(u'"{pattern}" is not visible on screen')
def pattern_not_on_screen(context, pattern):
    match = re.match(pattern, get_screen_string(context.screen), re.UNICODE | re.DOTALL)
    assert match is None, "The pattern is visible '%s' on screen!" % pattern


@step(u'Set current field to "{value}"')
def set_current_field_to(context, value):
    context.tui.send(keys['BACKSPACE']*100)
    context.tui.send(value)


@step(u'Set "{field}" field to "{value}"')
def set_specific_field_to(context, field, value):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2500-\u2599\s]+%s.*' % field) is not None, "Could not go to option '%s' on screen!" % field
    context.tui.send(keys['BACKSPACE']*100)
    context.tui.send(value)


@step(u'Empty the field "{field}"')
def empty_specific_field(context, field):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2500-\u2599\s]+%s.*' % field) is not None, "Could not go to option '%s' on screen!" % field
    context.tui.send(keys['BACKSPACE']*100)


@step(u'In "{prop}" property add "{value}"')
def add_in_property(context, prop, value):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^.*[\u2502\s]+%s <Add.*' % prop) is not None, "Could not find '%s' property!" % prop
    context.tui.send(' ')
    context.tui.send(value)


@step(u'In this property also add "{value}"')
def add_more_property(context, value):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2502\s]+<Add\.\.\.>.*') is not None, "Could not find the next <Add>"
    context.tui.send(' ')
    context.tui.send(value)


@step(u'Add ip route "{values}"')
def add_route(context, values):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    assert go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^<Add.*') is not None, "Could not find the routing add button"
    context.tui.send('\r\n')
    for value in values.split():
        context.tui.send(keys['BACKSPACE']*32)
        context.tui.send(value)
        context.tui.send('\t')
    context.execute_steps(u'* Confirm the route settings')


@step(u'Cannot add ip route "{values}"')
def cannot_add_route(context, values):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    assert go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^<Add.*') is not None, "Could not find the routing add button"
    context.tui.send('\r\n')
    for value in values.split():
        context.tui.send(keys['BACKSPACE']*32)
        context.tui.send(value)
        context.tui.send('\t')
    context.execute_steps(u'* Cannot confirm the connection settings')


@step(u'Remove all routes')
def remove_routes(context):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2502\s]+Routing.+<Edit') is not None, "Could not find the routing edit button"
    context.tui.send('\r\n')
    while go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^<Remove.*', limit=5) is not None:
        context.tui.send('\r\n')
    context.execute_steps(u'* Confirm the connection settings')


@step(u'Remove all "{prop}" property items')
def remove_items(context, prop):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^.*[\u2502\s]+%s.*' % prop) is not None, "Could not find '%s' property!" % prop
    while go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^<Remove.*', limit=2) is not None:
        context.tui.send('\r\n')
    context.tui.send(keys['UPARROW']*2)


@step(u'Come in "{category}" category')
def come_in_category(context, category):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^.*[\u2550|\u2564]\s%s.*' % category) is not None, "Could not go to category '%s' on screen!" % category
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^(<Hide>|<Show>).*')
    assert match is not None, "Could not go to hide/show for the category %s " % category
    if match.group(1) == u'<Show>':
        context.tui.send(' ')


@step(u'Set "{category}" category to "{setting}"')
def set_category(context, category, setting):
    assert go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^.*[\u2550|\u2564]\s%s.*' % category) is not None, "Could not go to category '%s' on screen!" % category
    context.tui.send(' ')
    context.tui.send(keys['UPARROW']*16)
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^\s*%s\s*\u2502.*' % setting)
    assert match is not None, "Could not find setting %s for the category %s " % (setting, category)
    context.tui.send('\r\n')


@step(u'Set "{dropdown}" dropdown to "{setting}"')
def set_dropdown(context, dropdown, setting):
    assert go_until_pattern_matches_line(context,keys['TAB'],u'^.*\s+%s.*' % dropdown) is not None, "Could not go to dropdown '%s' on screen!" % dropdown
    context.tui.send(' ')
    context.tui.send(keys['UPARROW']*16)
    match = go_until_pattern_matches_aftercursor_text(context,keys['DOWNARROW'],u'^\s*%s\s*\u2502.*' % setting)
    assert match is not None, "Could not find setting %s for the dropdown %s " % (setting, dropdown)
    context.tui.send('\r\n')


@step(u'Ensure "{toggle}" is checked')
@step(u'Ensure "{toggle}" is {n} checked')
def ensure_toggle_is_checked(context, toggle, n=None):
    match = go_until_pattern_matches_line(context,keys['DOWNARROW'],u'^[\u2500-\u2599\s]+(\[.\])\s+%s.*' % toggle)
    assert match is not None, "Could not go to toggle '%s' on screen!" % toggle
    if match.group(1) == u'[ ]' and n is None:
        context.tui.send(' ')
    elif match.group(1) == u'[X]' and n is not None:
        context.tui.send(' ')


@step(u'Execute "{command}"')
def execute_command(context, command):
    os.system(command)


@step(u'Note the output of "{command}"')
def note_the_output_of(context, command):
    context.noted_value = subprocess.check_output(command, shell=True).strip() # kill the \n


@step(u'Restore hostname from the noted value')
def restore_hostname(context):
    os.system('nmcli g hostname %s' % context.noted_value)
    sleep(0.5)


@step(u'"{pattern}" is visible with command "{command}"')
def check_pattern_visible_with_command(context, pattern, command):
    cmd = pexpect.spawn(command, timeout = 180)
    if cmd.expect([pattern, pexpect.EOF]) != 0:
        dump_command_output(command)
        raise Exception('Did not see the pattern %s' % (pattern))


@step(u'"{pattern}" is visible with command "{command}" in "{seconds}" seconds')
def check_pattern_visible_with_command_in_time(context, pattern, command, seconds):
    timer = int(seconds)
    while timer > 0:
        cmd = pexpect.spawn(command, timeout = 180)
        if cmd.expect([pattern, pexpect.EOF]) == 0:
            return True
        timer = timer - 1
        sleep(1)
    dump_command_output(command)
    raise Exception('Did not see the pattern %s in %s seconds' % (pattern, seconds))


@step(u'"{pattern}" is not visible with command "{command}"')
def check_pattern_not_visible_with_command(context, pattern, command):
    cmd = pexpect.spawn(command, timeout = 180)
    if cmd.expect([pattern, pexpect.EOF]) == 0:
        dump_command_output(command)
        raise Exception('pattern %s still visible with %s' % (pattern, command))


@step(u'Check ifcfg-name file created for connection "{con_name}"')
def check_ifcfg_exists_given_device(context, con_name):
    sleep(1)
    cat = pexpect.spawn('cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name)
    cat.expect('NAME=%s' % con_name)


@step(u'ifcfg-"{con_name}" file does not exist')
def ifcfg_doesnt_exist(context, con_name):
    cat = pexpect.spawn('cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name)
    assert cat.expect('No such file') == 0, 'Ifcfg-%s exists!' % con_name


@step(u'Wait for at least "{secs}" seconds')
def wait_for_x_seconds(context,secs):
    sleep(int(secs))
    assert True


#---- bond steps ----

@step(u'Check bond "{bond}" in proc')
def check_bond_in_proc(context, bond):
    child = pexpect.spawn('cat /proc/net/bonding/%s ' % (bond))
    assert child.expect(['Ethernet Channel Bonding Driver', pexpect.EOF]) == 0; "%s is not in proc" % bond


@step(u'Check slave "{slave}" in bond "{bond}" in proc')
def check_slave_in_bond_in_proc(context, slave, bond):
    i = 5
    while i > 0:
        child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond))
        if child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) == 0:
            return 0
        sleep(1)
        i -= 1
    assert child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) == 0, "Slave %s is not in %s" % (slave, bond)


@step(u'Check "{bond}" has "{slave}" in proc')
def check_slave_present_in_bond_in_proc(context, slave, bond):
    # DON'T USE THIS STEP UNLESS YOU HAVE A GOOD REASON!!
    # this is not looking for up state as arp connections are sometimes down.
    # it's always better to check whether slave is up
    child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond))
    assert child.expect(["Slave Interface: %s\s+MII Status:" % slave, pexpect.EOF]) == 0, "Slave %s is not in %s" % (slave, bond)


@step(u'Check slave "{slave}" not in bond "{bond}" in proc')
def check_slave_not_in_bond_in_proc(context, slave, bond):
    i = 5
    while i > 0:
        child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond))
        if child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) != 0:
            return 0
        sleep(1)
        i -= 1
    assert child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) != 0, "Slave %s is in %s" % (slave, bond)


@step(u'Check bond "{bond}" state is "{state}"')
def check_bond_state(context, bond, state):
    child = pexpect.spawn('ip addr show dev %s up' % (bond))
    exp = 0 if state == "up" else 1
    r = child.expect(["\\d+: %s:" %  bond, pexpect.EOF])
    assert r == exp, "%s not in %s state" % (bond, state)


@step(u'Check bond "{bond}" link state is "{state}"')
def check_bond_link_state(context, bond, state):
    if os.system('ls /proc/net/bonding/%s' %bond) != 0 and state == "down":
        return
    child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond))
    assert child.expect(["MII Status: %s" %  state, pexpect.EOF]) == 0, "%s is not in %s link state" % (bond, state)


@step(u'Reboot')
def reboot(context):
    os.system("sudo ip link set dev eth1 down")
    os.system("sudo ip link set dev eth2 down")
    os.system("sudo ip link set dev eth3 down")
    os.system("sudo ip link set dev eth4 down")
    os.system("sudo ip link set dev eth5 down")
    os.system("sudo ip link set dev eth6 down")
    os.system("sudo ip link set dev eth7 down")
    os.system("sudo ip link set dev eth8 down")
    os.system("sudo ip link set dev eth9 down")
    os.system("sudo ip link set dev eth10 down")
    os.system("nmcli device disconnect bond0")
    os.system("nmcli device disconnect team0")
    sleep(2)
    context.nm_restarted = True
    os.system("sudo service NetworkManager restart")
    sleep(10)


@step(u'Team "{team}" is down')
def team_is_down(context, team):
    sleep(2)
    assert os.system('teamdctl %s state dump' % team) != 0, 'team "%s" exists' % (team)


@step(u'Team "{team}" is up')
def team_is_up(context, team):
    sleep(2)
    assert os.system('teamdctl %s state dump' % team) == 0, 'team "%s" does not exist' % (team)


@step(u'Check slave "{slave}" in team "{team}" is "{state}"')
def check_slave_in_team_is_up(context, slave, team, state):
    i = 20
    while i > 0:
        r = subprocess.call('sudo teamdctl %s port present %s' %(team, slave), shell=True)
        if state == "up":
            if r == 0:
                return 0

        if state == "down":
            if r != 0:
                return 0
        i -= 1
        sleep(1)

    if state == "up":
        raise Exception('Device %s was not found in dump of team %s' % (slave, team))

    if state == "down":
        raise Exception('Device %s was found in dump of team %s' % (slave, team))

@step(u'Set team json config to "{value}"')
def set_team_json(context, value):
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],u'^<Edit.*') is not None
    context.tui.send(keys['TAB'])
    assert go_until_pattern_matches_aftercursor_text(context,keys['TAB'],u'^<Edit.*') is not None, "Could not find the json edit button"
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


def get_device_dbus_path(device):
    import dbus
    bus = dbus.SystemBus()
    proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
    dpath = None
    devices = manager.GetDevices()
    for d in devices:
        dev_proxy = bus.get_object("org.freedesktop.NetworkManager", d)
        prop_iface = dbus.Interface(dev_proxy, "org.freedesktop.DBus.Properties")
        iface = prop_iface.Get("org.freedesktop.NetworkManager.Device", "Interface")
        if iface == device:
            dpath = d
            break
    if not dpath or not len(dpath):
        raise Exception("NetworkManager knows nothing about %s" % device)
    return dpath


@step(u'Flag "{flag}" is {n} set in WirelessCapabilites')
@step(u'Flag "{flag}" is set in WirelessCapabilites')
def flag_cap_set(context, flag, n=None, device='wlan0', giveexception=True):
    wcaps = {}
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_WEP40'] = 0x1
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_WEP104'] = 0x2
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_TKIP'] = 0x4
    wcaps['NM_802_11_DEVICE_CAP_CIPHER_CCMP'] = 0x8
    wcaps['NM_802_11_DEVICE_CAP_WPA'] = 0x10
    wcaps['NM_802_11_DEVICE_CAP_RSN'] = 0x20
    wcaps['NM_802_11_DEVICE_CAP_AP'] = 0x40
    wcaps['NM_802_11_DEVICE_CAP_ADHOC'] = 0x80
    wcaps['NM_802_11_DEVICE_CAP_FREQ_VALID'] = 0x100
    wcaps['NM_802_11_DEVICE_CAP_FREQ_2GHZ'] = 0x200
    wcaps['NM_802_11_DEVICE_CAP_FREQ_5GHZ'] = 0x400

    path = get_device_dbus_path(device)
    cmd = '''dbus-send --system --print-reply \
            --dest=org.freedesktop.NetworkManager \
            %s \
            org.freedesktop.DBus.Properties.Get \
            string:"org.freedesktop.NetworkManager.Device.Wireless" \
            string:"WirelessCapabilities" | grep variant | awk '{print $3}' ''' % path
    ret = int(subprocess.check_output(cmd, shell=True).strip())

    if n is None:
        if wcaps[flag] & ret == wcaps[flag]:
            return True
        elif giveexception:
            raise AssertionError("The flag is unset! WirelessCapabilities: %d" % ret)
        else:
            return False
    else:
        if wcaps[flag] & ret == wcaps[flag]:
            raise AssertionError("The flag is set! WirelessCapabilities: %d" % ret)
