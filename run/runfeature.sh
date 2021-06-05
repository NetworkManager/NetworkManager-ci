#!/bin/bash

prepare/envsetup.sh first_test_setup

echo "The following tests are going to be executed:"
python -m nmci mapper_feature $1 name | nl --number-width=4 --starting-line-number=0 --number-format=rz --number-separator=" "

set -x
eval "$(python -m nmci mapper_feature $1 bash)"
