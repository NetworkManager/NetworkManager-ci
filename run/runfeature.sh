#!/bin/bash

if [ -z "$1" ]; then
  cat << EOF
USAGE: $0 {feature} [testmapper [--dry/-d]]

  run all the test from given feature and testmaper as defined in mapper, accepts 'all' and '*'


  if --dry (or -d) is passed as last argument, tests are not executed,
  only list of the tests is printed

EXAMPLES:
  $0 {feature}        - run feature, search in all tesmappers
  $0 all deafult      - execute all tests from default testmapper (gsm, wifi, dcg and inf excluded)
  $0 all all --dry    - list all the tests from mapper
  $0 {feature} all -d - testmapper must be specified before "--dry/-d" option
EOF
  exit 1
fi

feature="$1"
shift
testmapper="$1"
[ -z "$testmapper" ] && testmapper=all
shift
dry=0
[ "$1" == "--dry" -o "$1" == "-d" ] && dry=1
shift

echo "The following tests are going to be executed:"
tests="$(python3l -m nmci mapper_feature "$feature" "$testmapper" name)"
echo "$tests" | \
  nl --number-width=4 --starting-line-number=0 --number-format=rz --number-separator=" "

if [ "$dry" == 1 ]; then
  echo "Dry run, exitting..."
  exit 0
fi

prepare/envsetup.sh setup first_test_setup
set -x
run/runtests.sh $tests