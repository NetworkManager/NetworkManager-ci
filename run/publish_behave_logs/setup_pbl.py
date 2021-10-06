#!/usr/bin/env python3

import dbus
import os
import re
import shutil
from subprocess import run, PIPE, STDOUT
import sys

inst = ['/usr/bin/dnf', '-y', 'install', 'httpd', 'python3-libselinux', 'python3-inotify']
inst_el7 = ['/usr/bin/yum', '-y', 'install', 'httpd', 'libselinux-python', 'python-inotify']
server_root = '/etc/httpd'
document_root = '/var/www/html'
httpd_conf = '/conf/'.join((server_root, 'httpd.conf'))
httpd_welcome_file = '/conf.d/'.join((server_root, 'welcome.conf'))
httpd_welcome_conf = '# disable welcome page'
httpd_listen = 'Listen 8080'
httpd_custom_file = '99-publish_behave_logs.conf'
httpd_custom_file_full = '/conf.d/'.join((server_root, httpd_custom_file))
source_dir = os.path.dirname(__file__)


# install packages
with open('/etc/redhat-release', 'r') as f:
    rh_release = f.read()

if 'Maipo' in rh_release:
    inst = inst_el7

installed = run(inst, encoding='UTF-8')

if installed.returncode != 0:
    raise SystemExit('\n\nPackage installation failed!')

os.makedirs(document_root, exist_ok=True)


# set up apache
try:
    with open(httpd_welcome_file, 'r+') as f:
        welcome_orig = f.read()
        f.truncate(0)
        f.seek(0)
        f.write(httpd_welcome_conf)

    with open(httpd_conf, 'r+', encoding='UTF-8') as f:
        conf_orig = f.read()
        conf_new = re.sub('(?m)^Listen\s+.*$', httpd_listen, conf_orig)
        f.truncate(0)
        f.seek(0)
        f.write(conf_new)

    shutil.copy('/'.join((source_dir, httpd_custom_file)), httpd_custom_file_full)

    # raise exception if configuration test fails
    configtest = run(('apachectl', 'configtest'), check=True, stdout=PIPE, stderr=STDOUT, encoding='UTF-8')
except:
    with open(httpd_welcome_file, 'w') as f:
        f.truncate(0)
        f.write(welcome_orig)

    with open(httpd_conf) as f:
        f.truncate(0)
        f.write(conf_orig)

    os.remove(httpd_custom_file_full)

    raise SystemExit(f'apachectl configtest failed! configtest output was:\n\n{configtest.stdout}')
print('httpd configured')


shutil.copy('/'.join((source_dir, 'publish_behave_logs')), '/usr/local/bin/')
if 'Maipo' in rh_release:
    shutil.copy('/'.join((source_dir, 'publish_behave_logs.service.el7')),
            '/etc/systemd/system/publish_behave_logs.service')
else:
    shutil.copy('/'.join((source_dir, 'publish_behave_logs.service')), '/etc/systemd/system/')
print('service files installed')

# load and restart systemd services
dbus_system_bus = dbus.SystemBus()
dbus_systemd = dbus_system_bus.get_object('org.freedesktop.systemd1', '/org/freedesktop/systemd1')
dbus_systemd_manager = dbus.Interface(dbus_systemd, 'org.freedesktop.systemd1.Manager')

dbus_systemd_manager.EnableUnitFiles(['httpd.service'], False, True)
dbus_systemd_manager.Reload()

dbus_systemd_manager.RestartUnit('publish_behave_logs.service', 'replace')
dbus_systemd_manager.RestartUnit('httpd.service', 'replace')
print('services enabled and started, all should be set now')
