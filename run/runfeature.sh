#!/bin/bash

prepare/envsetup.sh first_test_setup

echo "The following tests are going to be executed:"
python -m nmci mapper_feature $1 name

set -x
eval "$(python -m nmci mapper_feature $1 bash)"
