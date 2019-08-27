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
HTML_INDEX_FILE="index.html"

# Put in BASE_URL the base url of your NM jenkins projects and in PROJECTS
# the project names (this allows to collect separate logs from multiple projects)
# Here a working example for the public NetworkManager CI on CentosCI, collecting
# results for 3 projects (3 different branches).
BASE_URL="https://ci.centos.org/view/NetworkManager/job/NetworkManager-"
PROJECTS="master nm-1-10 nm-1-8"
PROJECT_LABEL="CentosCI"

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
	ref="$1_index.html"
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

for proj in $PROJECTS
do
	PROJECT_FULL_NAME="${PROJECT_LABEL}-${proj}"

	$JDUMP_BIN $JDUMP_OPTIONS --name "$PROJECT_FULL_NAME" "$BASE_URL""$proj" >> "$LOG_FILE" 2>&1
	index_html_add_entry "$PROJECT_FULL_NAME" "${proj}"
done

index_html_trailing

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"

