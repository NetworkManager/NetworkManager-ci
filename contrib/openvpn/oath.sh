#!/bin/sh
# This could be dummy "exit 0" script, since we use management console to control challenge-response
# But, it might be handy to filter out invalid request beforehand (to add some negative test)

passfile=$1

# Get the user/pass from the tmp file
user=$(head -1 $passfile)
pass=$(tail -1 $passfile)

# accept correct user:pass combination
[ "$user" == "trest@redhat" ] && [ "$pass" == "secret" ] && exit 0

# accept correct challenge-response
[ "$user" == "trest@redhat" ] && [ "$pass" == "CRV1::Om01u7Fh4LrGBS7uh0SWmzwabUiGiW6l::123456" ] && exit 0

# deny the rest
exit 1