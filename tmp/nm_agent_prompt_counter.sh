#!/bin/bash
# this screpts runs the "nm agent secrets" and counts the number of
# password prompts

# do_start info
# spawns nmcli agent secrets and cancells all prompts 
# (by pressing ENTER 100 times)
# remembers pidfile and output of agent is also redirected

PIDFILE=/tmp/nm_agent.pid
OUTFILE=/tmp/nm_agent.txt

do_usage() {
    echo "USAGE: $0 {start|stop}"
    echo "  start: start nm agent"
    echo "  stop:  stop nm agent and show result in stdout"
}

do_start() {
    for i in {1..100}
        do
            echo
        done | \
        nmcli agent secret &> $OUTFILE & echo $! > $PIDFILE
}

# do_stop
# kills agent process (grep and wc will exit normally)
# then filter result and wrap it
# (it is safe to search for ='1' rather than 1 alone, 
# beause 10, 11... would be valid outputs then)
# remove pidfile, keep output for debuging, if test fails

do_stop() {
    if ! [ -f $PIDFILE ]; then
        echo "$PIDFILE: No such file or directory"
        exit 1
    fi
    kill $(cat $PIDFILE)
    echo "PASSWORD_PROMPT_COUNT='$(grep ^Password $OUTFILE | wc -l)'"
    rm $PIDFILE
    # keep outfile, for debug
    # rm  $OUTFILE
}

if [ "$1" == "start" ]; then
    do_start
elif [ "$1" == "stop" ]; then
    do_stop
else
    do_usage
fi
