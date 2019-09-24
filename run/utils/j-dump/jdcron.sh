#!/bin/sh

###
# This script runs in batch j-dump sessions to collect result summaries from
# multiple jenkins jobs.
# It will produce as output two html files per job:
# - ${job}_builds.html
# - ${job}_failures.html
###

# Change the JDUMP_BIN to the path of j-dump.py script if required.
JDUMP_BIN="$PWD/j-dump.py"
OUTPUT_DIR="/tmp/j_dump/"
LOG_FILE="logger.txt"
HTML_INDEX_FILE="index.html"

# Put in JENKINS_URL the base url of your jenkins server.
# Put in JOBS the job list you want to process (logs will be collected separately
# for each job).
# If your jobs have a common header, you can drop it from the jobs listed in JOBS
# and put it in JOB_HEADER.
# Here a working example for the public NetworkManager CI on CentosCI, collecting
# results for 3 jobs (matching 3 different branches on gitlab).
JENKINS_URL="https://ci.centos.org"
JOB_HEADER="NetworkManager-"
JOBS="master nm-1-20 nm-1-18"

USER="$1"
PASSWORD="$2"

[ -n "$USER" -a -n "$PASSWORD" ] && JDUMP_OPTIONS="--user $USER --password $PASSWORD"

log() {
	echo "$*" >> "$LOG_FILE"
}

index_html_heading() {
	echo -e '<!DOCTYPE html>\n' \
	        '<html>\n' \
	        '  <head>\n' \
	        '    <style> * { font-family:arial, sans-serif; } </style>\n' \
	        '  </head>\n' \
	        '  <body>\n' \
	        '    <h1>NetworManager CI results</h1>\n' \
	        '    <ul>' \
	> $HTML_INDEX_FILE
}

index_html_add_entry() {
	ref="$1_builds.html"
	name="$2"

	echo "      <li><a href=${ref}>${name}</a></li>" >> $HTML_INDEX_FILE
}

index_html_trailing() {
	echo -e '    </ul>\n' \
	        '  </body>\n' \
	        '</html>' \
	>> $HTML_INDEX_FILE
}

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"
log "-----------------------------------------------------------------"
log `date`
log "-----------------------------------------------------------------"

index_html_heading

for job in $JOBS
do
	JOB_FULL_NAME="${JOB_HEADER}${job}"
	[ -n "$JOB_HEADER" ] && JDUMP_JOB_NAME="--name $job" || unset JDUMP_JOB_NAME

	$JDUMP_BIN $JDUMP_OPTIONS $JDUMP_JOB_NAME "$JENKINS_URL" "$JOB_FULL_NAME" >> "$LOG_FILE" 2>&1
	index_html_add_entry "$JOB_FULL_NAME" "${job}"
done

index_html_trailing

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"

