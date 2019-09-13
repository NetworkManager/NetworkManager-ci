from __future__ import absolute_import, division, print_function, unicode_literals
import sys
from subprocess import call, check_output

current_nm_version = [ int(x) for x in check_output(["NetworkManager","-V"]).decode("utf-8").split("-")[0].split(".") ]

if "NetworkManager" in sys.argv[2] and "Test" in sys.argv[2]:
    test_name = "".join('_'.join(sys.argv[2].split('_')[2:]))
else:
    test_name = sys.argv[2]

try:
    com = "behave $( grep %s -l %s/features/*.feature) -k -t %s --dry-run | grep %s" %(test_name, sys.argv[1], test_name, test_name)
    raw_tags = check_output (com, shell=True).decode('utf-8').strip("\n")
except:
    sys.exit(1)

tests_tags = raw_tags.split('\n')

# for every line with the same test_name
for tags in tests_tags:
    run = True
    tags = [tag.strip('@') for tag in tags.split()]
    for tag in tags:
        if tag.startswith('ver=') or tag.startswith('ver+') or tag.startswith('ver-'):
            tag_version = [ int(x) for x in tag.replace("=","").replace("ver+","").replace("ver-","").split(".") ]
            if '+=' in tag:
                while len(tag_version) < 3:
                    tag_version.append(0)
                if current_nm_version < tag_version:
                    run = False

            elif '-=' in tag:
                while len(tag_version) < 3:
                    tag_version.append(9999)
                if current_nm_version > tag_version:
                    run = False

            elif '-' in tag:
                while len(tag_version) < 3:
                    tag_version.append(0)
                if current_nm_version >= tag_version:
                    run = False

            elif '+' in tag:
                while len(tag_version) < 3:
                    tag_version.append(0)
                if current_nm_version <= tag_version:
                    run = False
    if run:
        print(" -t ".join(tags))
        sys.exit(0)

sys.exit(1)
