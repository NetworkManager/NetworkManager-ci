#!/bin/bash

while read line; do
  echo "`date '+%b %d %H:%M:%S <%s.%N>'` $line"
done
