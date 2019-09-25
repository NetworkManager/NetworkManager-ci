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

# Put in CI_NICK the header that will be printed on top of your CI jobs.
# Put in JENKINS_URL the base url of your jenkins server.
# Put in JOBS the job list you want to process (logs will be collected separately
# for each job).
# If your jobs have a common header, you can drop it from the jobs listed in JOBS
# and put it in JOB_HEADER.
# Here a working example for the public NetworkManager CI on CentosCI, collecting
# results for 3 jobs (matching 3 different branches on gitlab).
CI_NICK="CentOS CI"
JENKINS_URL="https://ci.centos.org"
JOB_HEADER="NetworkManager-"
JOBS="master nm-1-20"

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
	        '    <style>\n' \
		'      * { font-family:arial, sans-serif; }\n' \
		'      header { padding-left:30px; font-size:20px; }\n' \
		'      nav { float:left; width:20%; padding-left:10px; }\n' \
		'      article { float:left; width:75%; padding-left:20px; }\n' \
		'      @media (max-width:800px) {\n' \
		'        nav,article { width:100%; height:auto; }\n' \
		'      }\n' \
		'    </style>\n' \
	        '  </head>\n' \
	        '  <body>\n' \
	        '    <header><h1>NetworManager CI results</h1></header>\n' \
		'    <section>\n' \
		'      <nav>\n' \
	> $HTML_INDEX_FILE
}

index_html_ci_begin() {
	ci_nick="$1"

	echo -e "        <h2>${ci_nick}</h2>\n" \
	        '        <ul>\n' \
	>> $HTML_INDEX_FILE
}

index_html_ci_end() {
	echo -e '        </ul>\n' >> $HTML_INDEX_FILE
}

index_html_add_entry() {
	ref="$1_builds.html"
	name="$2"

	echo "      <li><a href=${ref} target=\"iframe_res\">${name}</a></li>" >> $HTML_INDEX_FILE
}

index_html_trailing() {
	echo -e '    </nav>\n' \
		"    <article><iframe name=\"iframe_res\" width=100% height=1000px style=\"border:none\"\n" \
		'    </section>\n' \
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

log "***  $CI_NICK ***"
index_html_ci_begin "$CI_NICK"
for job in $JOBS
do
	JOB_FULL_NAME="${JOB_HEADER}${job}"
	[ -n "$JOB_HEADER" ] && JDUMP_JOB_NAME="--name $job" || unset JDUMP_JOB_NAME

	$JDUMP_BIN $JDUMP_OPTIONS $JDUMP_JOB_NAME "$JENKINS_URL" "$JOB_FULL_NAME" >> "$LOG_FILE" 2>&1
	index_html_add_entry "$JOB_FULL_NAME" "${job}"
done
index_html_ci_end

index_html_trailing

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"

