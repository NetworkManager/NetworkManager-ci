#!/bin/sh

###
# This script runs in batch j-dump sessions to collect result summaries from
# multiple jenkins projects.
# It will produce as output two html files per project:
# - ${PROJECT_NAME}_index.html
# - ${PROJECT_NAME}_failures.html
###

# Change the JDUMP_BIN to the path of j-dump.py script if required.
JDUMP_BIN="$PWD"/j-dump.py
OUTPUT_DIR="/tmp/j_dump/"
LOG_FILE="logger.txt"

log() {
	echo "$*" >> "$LOG_FILE"
}

USER="$1"
PASSWORD="$2"

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"
log "-----------------------------------------------------------------"
log `date`
log "-----------------------------------------------------------------"

# Put in BASE_URL the base url of your NM jenkins projects and in PROJECTS
# the project names (this allows to collect separate logs from multiple projects)
# Here a working example for the public NetworkManager CI on CentosCI, collecting
# results for 3 projects (3 different branches).
BASE_URL="https://ci.centos.org/view/NetworkManager/job/NetworkManager-"
PROJECTS="master nm-1-10 nm-1-8"

for proj in $PROJECTS
do
	$JDUMP_BIN --name CentosCI-"$proj" "$BASE_URL""$proj" >> "$LOG_FILE" 2>&1
done

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"

