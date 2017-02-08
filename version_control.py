import sys
from subprocess import call, check_output

current_nm_version = "".join(check_output("""NetworkManager -V |awk 'BEGIN { FS = "." }; {printf "%03d%03d%03d", $1, $2, $3}'""", shell=True).split('-')[0])

test_name = "".join('_'.join(sys.argv[2].split('_')[2:]))

raw_tags = check_output ("behave %s/features/  -k -t %s --dry-run |grep %s" %(sys.argv[1], test_name, test_name), shell=True)
tests_tags = raw_tags.split('\n')

tag_to_return = ""

# for every line with the same test_name
for tags in tests_tags:
    tags = [tag.strip('@') for tag in tags.split()]

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
                if int(current_nm_version) >= int(need_nm_version):

                    # set only higher version if we already have one
                    if tag > tag_to_return:
                        tag_to_return = tag
                    break

            if '-=' in tag:
                if int(current_nm_version) <= int(need_nm_version):
                    tag_to_return = tag
                    break

# skip the test
if tag_to_return == "skip":
    sys.exit(1)

# write out the test tag to be used
if tag_to_return != "":
    sys.stdout.write(tag_to_return)
    sys.stdout.flush()

sys.exit(0)

