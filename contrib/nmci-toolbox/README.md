# Developer toolbx with NM CI stuff

```
$ contrib/toolbox/rebuild-nmci-toolbox
(...)
$ toolbox enter nmci-fedora
$ pytest nmci/test-nmci.py
```

The `rebuild-nmci-toolbox` script prepares toolbx container with all stuff
needed for hacking on NM CI. It removes the previous image and generates a new
one.

The idea is to have all the needed software for any workflows in the container
definition to shave any need for container upkeep. Just generate a fresh one
semi-regularly and if you encounter a need to install or configure something,
send a MR.

## OS

The containers generated are currently based off of fedora 41.

## Software

The packages installed on top of base images are:
  * the same packages as in `gitlab-ci.yml`'s `script` section
  * some extra checkers
  * [`gh`](https://cli.github.com/), [`glab`](https://gitlab.com/gitlab-org/cli)

## Editors/IDE support

### `vim`

Vim comes with [ALE](https://github.com/dense-analysis/ale) enabled:
  * `black` is set as the fixer for python files
  * `ctrl-j` jumps to next problem
  * `ctrl-k` jumps to the previous problem
  * `:ALEFix` or `:Black`:w runs black on the current file

### VSCode

nothing on this front yet. [A possible inspiration](https://www.cogitri.dev/posts/12-fedora-toolbox/#hooking-it-up-with-vscode)

## Issues

* update the main README.md
* make base package lists exists just once in the repo and pull them to the `Containerfile` and `.gitlab-ci.yml`
* add other base OSs
* use the same OS as the host by default
