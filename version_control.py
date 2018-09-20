from __future__ import absolute_import, division, print_function, unicode_literals
import sys
from subprocess import call, check_output

def skip_non_default_packages(tags):
    if 'not_with_rhel7_pkg' in tags:
        # Do not run on stock RHEL7 package
        if call('rpm -qi NetworkManager |grep -q build.*bos.redhat.co', shell=True) == 0 and \
        check_output("rpm --queryformat %{RELEASE} -q NetworkManager |awk -F .  '{ print ($1 < 200) }'", shell=True).decode('utf-8').strip() == '1' and \
        call("grep -q 'release 7' /etc/redhat-release", shell=True) == 0:
            return True
        else:
            return False
    else:
        return False
        
current_nm_version = "".join(check_output("""NetworkManager -V |awk 'BEGIN { FS = "." }; {printf "%03d%03d%03d", $1, $2, $3}'""", shell=True).decode('utf-8').split('-')[0])

if "NetworkManager" in sys.argv[2] and "Test" in sys.argv[2]:
    test_name = "".join('_'.join(sys.argv[2].split('_')[2:]))
else:
    test_name = sys.argv[2]

raw_tags = check_output ("behave %s/features/  -k -t %s --dry-run |grep %s" %(sys.argv[1], test_name, test_name), shell=True).decode('utf-8')
tests_tags = raw_tags.split('\n')

tag_to_return = ""

# for every line with the same test_name
for tags in tests_tags:
    tags = [tag.strip('@') for tag in tags.split()]

    # search for tags starting ver
    maximal_nm_version = 99999999
    minimal_nm_version = 00000000
    #print tags
    for tag in tags:
        if tag.startswith('ver') and '=' in tag:

            # set skip flag if we don't still have tag
            if tag_to_return == "":
                tag_to_return = "skip"

            # we need version in 001002003 format
            tokens = tag.split('=')[-1].split('.')
            if len(tokens) == 3:
                need_nm_version = "%03d%03d%03d" % (int(tokens[0]), int(tokens[1]), int(tokens[2]))
            # append 0 to the end if needed
            elif len(tokens) == 2:
                need_nm_version = "%03d%03d000" % (int(tokens[0]), int(tokens[1]))
            # skip tag otherwise
            else:
                tag_to_return = "skip"
                break

            if '+=' in tag:
                minimal_nm_version = need_nm_version
                # print (minimal_nm_version)

            if '-=' in tag:
                maximal_nm_version = need_nm_version
                # print (maximal_nm_version)

    # search for tags starting ver
    for tag in tags:
        if tag.startswith('ver') and '=' in tag:

            # set skip flag if we don't still have tag
            if tag_to_return == "":
                tag_to_return = "skip"

            # we need version in 001002003 format
            tokens = tag.split('=')[-1].split('.')
            if len(tokens) == 3:
                need_nm_version = "%03d%03d%03d" % (int(tokens[0]), int(tokens[1]), int(tokens[2]))
            # append 0 to the end if needed
            elif len(tokens) == 2:
                need_nm_version = "%03d%03d000" % (int(tokens[0]), int(tokens[1]))
            # skip tag otherwise
            else:
                tag_to_return = "skip"
                break

            if '+=' in tag:
                # print need_nm_version
                # print maximal_nm_version
                # print current_nm_version
                if int(current_nm_version) >= int(need_nm_version):
                    if int(current_nm_version) <= int(maximal_nm_version):
                        # set only higher version if we already have one
                        if tag > tag_to_return:
                            if skip_non_default_packages(tags):
                                break
                            tag_to_return = tag
                            break

            if '-=' in tag:
                # print need_nm_version
                # print minimal_nm_version
                # print current_nm_version
                if int(current_nm_version) <= int(need_nm_version):
                    if int(current_nm_version) >= int(minimal_nm_version):
                        if skip_non_default_packages(tags):
                            break
                        tag_to_return = tag
                        break

# skip the test
if tag_to_return == "skip":
    sys.exit(1)

#print "TTR"
#print tag_to_return
# write out the test tag to be used
if tag_to_return != "":
    sys.stdout.write(tag_to_return)
    sys.stdout.flush()

sys.exit(0)
