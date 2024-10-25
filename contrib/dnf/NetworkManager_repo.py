#!/usr/bin/env dnf
import dnf

base = dnf.Base()
base.fill_sack()

q = base.sack.query()
i = q.installed()
i = i.filter(name="NetworkManager")

repo_name = ""
for pkg in list(i):
    repo_name = pkg.from_repo
    break

print(repo_name)
