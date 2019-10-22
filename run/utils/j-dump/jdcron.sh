#!/bin/sh

###
# This script runs in batch j-dump sessions to collect result summaries from
# multiple jenkins jobs.
# It will produce as output two html files per job:
# - ${job}_builds.html
# - ${job}_failures.html
#
# The jobs are grouped under CI_NICKs labels. You can collect results under
# multiple CI_NICKs and from different Jenkins instances.
###

### GLOBAL CONFIG ###
# Change the JDUMP_BIN to the path of j-dump.py script if required.
JDUMP_BIN="$PWD/j-dump.py"
OUTPUT_DIR="/tmp/j_dump/"
LOG_FILE="logger.txt"
HTML_INDEX_FILE="index.html"
NM_LOGOTYPE_FILE="nm_logotype_235x75.png"
NM_ICON_FILE="nm_icon.png"


### CI_NICKs config ###
# add to the CI_NICK_LIST each nickname you want to be used to group some jobs.
# For each nickname you add, you should fill the CI_NICK_LABEL, JENKINS_URL,
# USER, PASSWORD, JOB_HEADER and JOBS properties.
#
# Put in CI_NICK the header that will be printed on top of your CI jobs.
# Put in JENKINS_URL the base url of your jenkins server.
# Put in JOBS the job list you want to process (logs will be collected separately
# for each job).
# If your jobs have a common header, you can drop it from the jobs listed in JOBS
# and put it in JOB_HEADER.
#
# Here a working example for the public NetworkManager CI on CentosCI, collecting
# results for 3 jobs (matching 3 different branches on gitlab).

CI_NICK_LIST="CentOS"

### CentOS ###
CentOS_CI_NICK_LABEL="CentOS"
CentOS_USER=""
CentOS_PASSWORD=""
CentOS_JENKINS_URL="https://ci.centos.org"
CentOS_JOB_HEADER="NetworkManager-"
CentOS_JOBS=\
"master "\
"nm-1-20 "\
"nm-1-18 "\
"nm-1-16 "


log() {
	echo "$*" >> "$LOG_FILE"
}

index_html_heading() {
	echo -e '<!DOCTYPE html>\n' \
	        '<html>\n' \
	        '  <head>\n' \
	        '    <style>\n' \
		'      * { font-family:arial, sans-serif; }\n' \
		'      img { width:235px; height:75px; padding-right:50px; }\n' \
		'      header { padding-left:30px; font-size:20px; }\n' \
		'      nav { float:left; width:20%; padding-left:10px; }\n' \
		'      article { float:left; width:75%; padding-left:20px; }\n' \
		'      @media (max-width:800px) {\n' \
		'        nav,article { width:100%; height:auto; }\n' \
		'      }\n' \
		'    </style>\n' \
	        '  </head>\n' \
			"  <link rel=\"icon\" href=\"$NM_ICON_FILE\">\n" \
	        '  <body>\n' \
	        '    <header>\n' \
		"      <h1><img src=\"$NM_LOGOTYPE_FILE\" alt=\"NetworkManager\" align=\"bottom\">CI results</h1>\n" \
		'    </header>\n' \
		'    <section>\n' \
		'      <nav>\n' \
	> $HTML_INDEX_FILE
}

index_html_ci_begin() {
	ci_nick="$1"

	echo -e "        <h2>${ci_nick}</h2>\n" \
	        '        <ul style="list-style-type: none;">\n' \
	>> $HTML_INDEX_FILE
}

index_html_ci_end() {
	echo -e '        </ul>\n' >> $HTML_INDEX_FILE
}

index_html_add_entry() {
	ref="$1_builds.html"
	name="$2"
    if [ "$3" == "green" ]; then
        style="color:green; border:1px solid green; background-color:#ddffdd;"
    elif [ "$3" == "black" ]; then
        style="color:black; border:1px solid black; background-color:#dddddd;"
    else
        style="color:red;   border:1px solid red;   background-color:#ffdddd;"
	fi
	echo -n "      <li style=\"padding:2px 0;\"><a style=\"text-decoration:none; border-radius:2px; padding:0 3px; ${style}\" href=${ref} target=\"iframe_res\">${name}" >> $HTML_INDEX_FILE
	for i in `seq $4`; do
		echo -n " <b>*</b>" >> $HTML_INDEX_FILE
	done
	echo '</a></li>' >> $HTML_INDEX_FILE
}

index_html_trailing() {
	echo -e '    </nav>\n' \
		"    <article><iframe name=\"iframe_res\" width=100% height=1000px style=\"border:none\">\n" \
		'    </section>\n' \
		'  </body>\n' \
	        '</html>' \
	>> $HTML_INDEX_FILE
}


process_job() {
	local NICK="$1"
	eval local CI_NICK_LABEL="\"\$${NICK}_CI_NICK_LABEL CI\""
	eval local USER="\"\$${NICK}_USER\""
	eval local PASSWORD="\"\$${NICK}_PASSWORD\""
	eval local JENKINS_URL="\"\$${NICK}_JENKINS_URL\""
	eval local JOB_HEADER="\"\$${NICK}_JOB_HEADER\""
	eval local JOBS="\"\$${NICK}_JOBS\""

	unset JDUMP_OPTIONS
	[ -n "$USER" -a -n "$PASSWORD" ] && JDUMP_OPTIONS="--user $USER --password $PASSWORD"

	log "***  $CI_NICK_LABEL ***"
	index_html_ci_begin "$CI_NICK_LABEL"
	for job in $JOBS
	do
		JOB_FULL_NAME="${JOB_HEADER}${job}"
		[ -n "$JOB_HEADER" ] && JDUMP_JOB_NAME="--name ${job%-upstream}" || unset JDUMP_JOB_NAME

		$JDUMP_BIN $JDUMP_OPTIONS $JDUMP_JOB_NAME "$JENKINS_URL" "$JOB_FULL_NAME" >> "$LOG_FILE" 2>&1
		color="$(grep -v 'RUNNING' ${JOB_FULL_NAME}_builds.html | grep -m 1 '<tr><td>' | grep -o -e green -e black )"
		running="$(grep -o 'RUNNING' ${JOB_FULL_NAME}_builds.html | wc -l)"
		index_html_add_entry "$JOB_FULL_NAME" "${job%-upstream}" "$color" "$running"
	done
	index_html_ci_end
}

mkdir -p "$OUTPUT_DIR"
[ -f "$NM_LOGOTYPE_FILE" ] && cp "$NM_LOGOTYPE_FILE" "$OUTPUT_DIR"
[ -f "$NM_ICON_FILE" ] && cp "$NM_ICON_FILE" "$OUTPUT_DIR"

cd "$OUTPUT_DIR"
log "-----------------------------------------------------------------"
log `date`
log "-----------------------------------------------------------------"

index_html_heading


for nick in $CI_NICK_LIST; do
	process_job "$nick"
done


index_html_trailing

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"
