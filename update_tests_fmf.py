#!/usr/bin/python3

import nmci

from nmci.test_nmci import generate_fmf, generate_tests

generate_fmf(
    generate_tests(nmci.misc.get_mapper_obj()), "./fmf_template.j2", "./tests.fmf"
)
