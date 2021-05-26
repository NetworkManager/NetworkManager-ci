#!/bin/bash
set -x
###
# This script runs in batch j-dump sessions to collect result summaries from
# multiple jenkins jobs.
# It will produce as output two html files per job:
# - ${job}_builds.html
# - ${job}_failures.html
#
# The jobs are grouped under CI_NICKs labels. You can collect results under
# multiple CI_NICKs and from different Jenkins instances.
# For more info check jdump.cfg
###

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CFG="jdcron.cfg"
if ! source $DIR/$CFG; then
    echo "Cannot read config file in $CFG, exitting."
	exit 1
fi

mkdir -p "$OUTPUT_DIR"

# wrap the code to be run exclusively with parentheses
(
# wait at most 10 seconds for lockfile (fd 200) to be released, if not exit 1
flock -x -w 10 200 || exit 1

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
			"  <link rel=\"icon\" href=\"$NM_ICON_FILE\">\n" \
	        '  <body>\n' \
	        '    <header>\n' \
		"      <h1><img style=\"width:235px; height:75px; padding-right:50px\" src=\"$NM_LOGOTYPE_FILE\" alt=\"NetworkManager\" align=\"bottom\">CI results</h1>\n" \
		'    </header>\n' \
		'    <section>\n' \
		'      <nav>\n' \
	> $HTML_INDEX_FILE
}

js_heading() {
  echo "var projects = [" > $JS_CONFIG_FILE
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

	hl="$5"
  unset health
	if [ $hl -eq 1 ] || [ $hl -eq 0 ] ; then
		health=$NM_HEALTH_FILE1
	elif [ $hl -eq 2 ]; then
		health=$NM_HEALTH_FILE2
	elif [ $hl -eq 3 ]; then
		health=$NM_HEALTH_FILE3
	elif [ $hl -eq 4 ]; then
		health=$NM_HEALTH_FILE4
	elif [ $hl -eq 5 ]; then
		health=$NM_HEALTH_FILE5
  fi

    if [ -n "$health" ]; then
        health="<img style=\"width:20px; height:20px; padding-right:20px; margin-top:5px; margin-bottom:-5px;\" src=\"$health\">"
    fi

	echo -n "      <li>${health}<a style=\"text-decoration:none; border-radius:2px; padding:0 3px; ${style}\" href=${ref} target=\"iframe_res\">${name}" >> $HTML_INDEX_FILE
	for i in `seq $4`; do
		echo -n " <b>*</b>" >> $HTML_INDEX_FILE
	done
	echo '</a></li>' >> $HTML_INDEX_FILE
}

js_add_entry() {
  cat << EOF >> $JS_CONFIG_FILE
  {
    project:"$1",
    name:"$2",
    os:"$3",
  },
EOF
}

index_html_trailing() {
	echo -e '    </nav>\n' \
		"    <article><iframe name=\"iframe_res\" width=100% height=1000px style=\"border:none\">\n" \
		'    </section>\n' \
		'  </body>\n' \
	        '</html>' \
	>> $HTML_INDEX_FILE
}

js_trailing() {
  # end projects array, output health images names (image 0 and 1 are the same)
  cat << EOF >> $JS_CONFIG_FILE
  ];
  var health_img = [
  "$NM_HEALTH_FILE1",
  "$NM_HEALTH_FILE1",
  "$NM_HEALTH_FILE2",
  "$NM_HEALTH_FILE3",
  "$NM_HEALTH_FILE4",
  "$NM_HEALTH_FILE5",
  ];
EOF
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
		health="$(grep -v 'RUNNING' ${JOB_FULL_NAME}_builds.html | grep -m 5 '<tr><td>' |grep SUCCESS |wc -l) "
		index_html_add_entry "$JOB_FULL_NAME" "${job%-upstream}" "$color" "$running" "$health"
    js_add_entry "$JOB_FULL_NAME" "${job%-upstream}" "$CI_NICK_LABEL"
	done
	index_html_ci_end
}

[ -f "$NM_LOGOTYPE_FILE" ] && cp "$NM_LOGOTYPE_FILE" "$OUTPUT_DIR"
[ -f "$NM_ICON_FILE" ] && cp "$NM_ICON_FILE" "$OUTPUT_DIR"
[ -f "$NM_HEALTH_FILE1" ] && cp "$NM_HEALTH_FILE1" "$OUTPUT_DIR"
[ -f "$NM_HEALTH_FILE2" ] && cp "$NM_HEALTH_FILE2" "$OUTPUT_DIR"
[ -f "$NM_HEALTH_FILE3" ] && cp "$NM_HEALTH_FILE3" "$OUTPUT_DIR"
[ -f "$NM_HEALTH_FILE4" ] && cp "$NM_HEALTH_FILE4" "$OUTPUT_DIR"
[ -f "$NM_HEALTH_FILE5" ] && cp "$NM_HEALTH_FILE5" "$OUTPUT_DIR"

cd "$OUTPUT_DIR"
log "-----------------------------------------------------------------"
log `date`
log "-----------------------------------------------------------------"

index_html_heading
js_heading

for nick in $CI_NICK_LIST; do
	process_job "$nick"
done


index_html_trailing
js_trailing

mv -f $OUTPUT_DIR/*.* $FINAL_DIR
cp -r $OUTPUT_DIR/cache $FINAL_DIR

[ "$?" = "0" ] && log "*** Success ***"
log "@@-------------------------------------------------------------@@"

) 200>$OUTPUT_DIR/jdcronlock
