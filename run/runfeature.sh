#!/bin/bash

if [ -z "$1" ]; then
  cat << EOF
USAGE: $0 {feature_name} [--dry/-d]

  run all the test from given feature as defined in mapper

  if --dry (or -d) is passed as last argument, tests are not executed,
  only list of the tests is printed
EOF
  exit 1
fi

echo "The following tests are going to be executed:"
python3 -m nmci mapper_feature $1 name | \
  nl --number-width=4 --starting-line-number=0 --number-format=rz --number-separator=" "

if [ "$2" == "--dry" -o "$2" == "-d" ]; then
  echo "Dry run, exitting..."
  exit 0
fi

CMDS="$(python3 -m nmci mapper_feature $1 bash)"
R=$?

if [ -z "$CMDS" -o "$R" != 0 ]; then
  echo "No tests matched."
  exit 1
fi

prepare/envsetup.sh setup first_test_setup
set -x
eval "$CMDS"
