KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
DEBUGFAIL="loglevel=1"
#DEBUGFAIL="rd.shell rd.break rd.debug loglevel=7 "
#DEBUGFAIL="rd.debug loglevel=7 "
#SERVER_DEBUG="rd.debug loglevel=7"
#SERIAL="tcp:127.0.0.1:9999"


[[ -e /tmp/dracut_testdir ]] && . /tmp/dracut_testdir
if [[ -z "$TESTDIR" ]] || [[ ! -d "$TESTDIR" ]]; then
    TESTDIR=$(mktemp -d -p "/var/tmp" -t dracut-test.XXXXXX)
fi
echo "TESTDIR=\"$TESTDIR\"" > /tmp/dracut_testdir
export TESTDIR

basedir=/usr/lib/dracut/
