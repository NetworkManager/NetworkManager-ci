#!/usr/bin/env python
import sys

import dnf

repo_name = sys.argv[1]

base = dnf.Base()
base.fill_sack()
base.read_all_repos()
repo = base.repos.get(repo_name)
print(repo.remote_location(" "))
