# NM-CI Test Framework and CI Pipeline Reference

This document is a human-readable reference covering the NM-CI test framework
and CI pipeline. It is intended for new team members, product owners, and anyone
who needs to understand how NetworkManager integration testing works without
reading the source code.

> **Scope:** This covers the NM-CI repository
> (`NetworkManager/NetworkManager-ci`). It does not cover NetworkManager
> internals or other sibling projects.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Test File Conventions](#2-test-file-conventions)
3. [How to Add a New Test Case](#3-how-to-add-a-new-test-case)
4. [CI Pipeline](#4-ci-pipeline)
5. [Common CI Failure Patterns](#5-common-ci-failure-patterns)
   - [5.1 How to Tell Infra from Code at a Glance](#51-how-to-tell-infra-from-code-at-a-glance)
   - [5.2 Infrastructure Failures](#52-infrastructure-failures)
   - [5.3 Code Failures](#53-code-failures)
   - [5.4 Reading HTML Reports](#54-reading-html-reports)
   - [5.5 Key Diagnostic Strings Quick Reference](#55-key-diagnostic-strings-quick-reference)
6. [Downstream Testing (Testing Farm / Polarion)](#6-downstream-testing-testing-farm--polarion)
7. [Assessing Test Coverage for an MR](#7-assessing-test-coverage-for-an-mr)

---

## 1. Architecture Overview

NM-CI is a [Behave](https://behave.readthedocs.io/en/stable/)-based (BDD)
integration test suite for NetworkManager. It runs on CentOS Stream, RHEL, and
Fedora systems using virtual network devices to simulate real networking
scenarios.

A single `main` branch supports all NM versions across RHEL, Fedora, and CentOS
Stream. Version-specific behavior is handled at runtime through `@ver`,
`@rhelver`, and `@fedver` tags in the test scenarios.

### Directory Structure

```
NM-ci/
├── mapper.yaml              # Central test registry (source of truth)
├── tests.fmf                # Generated FMF metadata (never edit manually)
├── behave.ini               # Behave framework configuration
├── pyproject.toml            # Python tooling (black, mypy, pytest)
├── .gitlab-ci.yml            # GitLab CI pipeline
│
├── features/
│   ├── scenarios/            # 53 .feature files (Gherkin test specifications)
│   ├── steps/                # 16 Python step implementation files
│   └── environment.py        # Test lifecycle hooks (setup/teardown)
│
├── nmci/                     # Core Python test infrastructure library
│   ├── tags.py               # Tag-based environment setup/cleanup registry
│   ├── process.py            # Command execution utilities
│   ├── nmutil.py             # NetworkManager-specific utilities
│   ├── misc.py               # Version detection, string utilities
│   ├── cleanup.py            # Priority-based cleanup system
│   ├── helpers/
│   │   └── version_control.py  # Version-based test filtering
│   └── test_nmci.py          # Unit tests for the nmci package
│
├── run/
│   ├── runtest.sh            # Single test executor (main entry point)
│   ├── runfeature.sh         # Feature-level executor
│   ├── runtests.sh           # Batch test runner
│   ├── centos-ci/            # Jenkins / CentOS CI integration
│   └── gitlab-pipelines/     # GitLab CI utilities
│
├── prepare/
│   ├── vethsetup.sh          # Creates 10 virtual network devices
│   ├── envsetup.sh           # Environment setup orchestrator
│   └── envsetup/             # Distro-specific setup scripts
│
├── plan/                     # TMT plan files (auto-generated from mapper.yaml)
│   ├── main.fmf              # Primary TMT plan
│   └── features/             # Per-feature plan files
│
└── contrib/                  # Test support files (certs, VPN configs, reproducers)
```

### How It All Fits Together

```
mapper.yaml                    run/runtest.sh
(test registry)  ────────>    (entry point)
                                    │
                                    v
                          version_control.py
                          (should this test run on this NM/OS?)
                                    │
                                    v
                             python3 -m behave
                                    │
                     ┌──────────────┼────────────────┐
                     │              │                 │
                     v              v                 v
              environment.py   scenarios/        steps/*.py
              (lifecycle)      *.feature         (step implementations)
                     │         (Gherkin specs)        │
                     v                                │
              nmci/tags.py  <─────────────────────────┘
              (env setup per tag)     uses nmci.* API
                     │
                     v
              nmci/ library
              (process, embed, cleanup, ip, dbus, ...)
                     │
                     v
              prepare/ scripts
              (virtual testbed, VPN servers, ...)
```

### Key Design Principles

- **Single source of truth:** `mapper.yaml` is the canonical test registry. All
  FMF metadata (`tests.fmf`) and plan files (`plan/`) are generated from it.
- **One branch, all versions:** The `main` branch works on all supported
  NM/RHEL/Fedora/CentOS versions. Runtime version filtering selects the right
  test variant.
- **Tag-driven environment:** Tags on scenarios (`@restart_if_needed`,
  `@eth8_disconnect`, etc.) trigger automatic setup and teardown of the test
  environment via the tag registry in `nmci/tags.py`.
- **Cleanup at creation time:** Resources (connections, interfaces, files) are
  registered for cleanup immediately when created, not at teardown. This ensures
  cleanup happens even if the test fails mid-scenario.

### The Virtual Testbed

Tests run on a virtual network topology created by `prepare/vethsetup.sh`:

- `eth0` is the machine's real network interface (renamed to `eth0`), serving
  as the default gateway. It is **not** a virtual device.
- **10 virtual ethernet devices** (`eth1`-`eth10`) using Linux veth pairs
- An internal bridge (`inbr`) connecting `eth1`-`eth9` inside a `vethsetup`
  network namespace, with a dnsmasq DHCP server at `192.168.100.1/24`
- A simulated external network on `eth10` with dual-stack DHCP
  (`10.16.1.0/24` + `2620:52:0:1086::/64`)
- `testeth0` is the default connectivity path (route metric 99)

> **Warning:** The testbed setup (`vethsetup.sh` and `envsetup.sh`) is
> destructive -- it deletes all existing NM connections, disables all network
> devices except the default gateway interface (`eth0`), and reconfigures the
> system's networking. **Always run tests inside a VM or container**, never on
> a workstation or production system.

---

## 2. Test File Conventions

### Feature Files (`features/scenarios/*.feature`)

Each `.feature` file covers one NetworkManager functional area. The 53 files
span:

| Category | Examples |
|----------|---------|
| L2 bonding/bridging | `bond.feature`, `bridge.feature`, `team.feature` |
| VLANs & virtual devices | `vlan.feature`, `veth.feature`, `vrf.feature` |
| IP networking | `ipv4.feature`, `ipv6.feature`, `dns.feature` |
| VPN | `openvpn.feature`, `libreswan.feature`, `strongswan.feature` |
| Wireless/cellular | `wifi.feature`, `gsm.feature` |
| TUI | `nmtui_bond.feature`, `nmtui_ethernet.feature`, ... |
| Special | `dracut.feature`, `cloud.feature`, `ovs.feature`, `sriov.feature` |

### Tag Ordering Convention

Tags on a scenario follow a strict ordering. **The last tag before `Scenario:`
is always the test name identifier.**

```gherkin
@RHEL-12345                               # 1. Jira issue reference
@ver+=1.30 @rhelver+=8.4 @fedver+=32      # 2. Version and distro gates
@skip_in_centos                           # 3. Skip/control tags
@restart_if_needed                        # 4. Environment setup tags
@bond_8023ad_with_vlan_srcmac             # 5. TEST NAME (must be last)
Scenario: nmcli - bond - 802.3ad with vlan+srcmac
```

### Naming Conventions

- **Test names:** `feature_descriptive_name` (e.g., `bond_add_default_bond`,
  `ipv4_method_static`). This name is used in `mapper.yaml` and as the argument
  to `run/runtest.sh`.
- **Feature files:** named after the NM feature area (e.g., `bond.feature`,
  `ipv6.feature`)
- **Step files:** grouped by functional domain (`connection.py`, `device.py`,
  `commands.py`, `vpn.py`, etc.)

### Step Keyword Usage

- **`*`** (asterisk) -- used for all action/setup steps (preferred over
  Given/When)
- **`Then`** -- used for assertions
- **`And`** -- chains additional assertions after `Then`
- **`Given`/`When`** -- rarely used; `*` is the strong convention

### Common Step Patterns

These are the most frequently used steps across the test suite. New tests should
reuse existing steps wherever possible.

**Connection management:**

```gherkin
* Add "bond" connection named "bond0" for device "nm-bond" with options
      """
      autoconnect no mode active-backup
      """
* Modify connection "bond0" changing options "ipv4.method manual ipv4.addresses 192.168.1.1/24"
* Bring "up" connection "bond0"
* Bring "down" connection "bond0"
* Delete connection "bond0"
```

**Command execution and output checking:**

```gherkin
* Execute "ip link show nm-bond"
Then "Bonding Mode: IEEE 802.3ad" is visible with command "cat /proc/net/bonding/nm-bond"
Then "192.168.1.1/24" is visible with command "nmcli connection show bond0" in "10" seconds
Then "some_pattern" is not visible with command "nmcli device" in "5" seconds
```

The `in "N" seconds` variant polls every second until the condition is met or
times out. Without it, the check runs twice by default.

**Noting values for later use:**

```gherkin
* Note the output of "nmcli -g connection.uuid connection show bond0" as value "uuid1"
Then Noted value "uuid1" is visible with command "nmcli -t connection show --active"
```

**File and config operations:**

```gherkin
* Create NM config file "99-test.conf" with content and "restart" NM
      """
      [main]
      plugins=
      """
* Check keyfile "/etc/NetworkManager/system-connections/bond0.nmconnection" has options
      """
      connection.id=bond0
      """
```

**Service lifecycle:**

```gherkin
* Restart NM
* Stop NM
* Start NM
```

> **Important:** Always use these steps (or the corresponding `nmci.nmutil`
> API functions like `nmci.nmutil.restart_NM_service()`) instead of raw
> commands like `systemctl restart NetworkManager`. The test framework tracks
> the NetworkManager PID for crash detection. A raw restart changes the PID
> without updating the tracker, which triggers false crash alarms and fails
> the test.

### Version Gating Tags

The `@ver` tag controls which NetworkManager versions a test runs on. Key rules:

| Tag | Meaning |
|-----|---------|
| `@ver+=1.42.2` | Run on NM >= 1.42.2 (preferred form) |
| `@ver-1.42.2` | Run on NM < 1.42.2 |
| `@ver/rhel/9+=1.43.6` | NM >= 1.43.6 on RHEL 9 stream only |
| `@rhelver+=9.3` | Run on RHEL >= 9.3 (distro version, not NM version) |
| `@fedver+=32` | Run on Fedora >= 32 |
| `@skip_in_centos` | Skip on CentOS Stream |

Best practices:
- Prefer `@ver+=NUMBER` over `@ver+NUMBER`
- Use development version numbers from `git describe` for the patch commit
- For upstream (odd minor, e.g., 1.43.x): use `@ver+=1.43.6` instead of
  `@ver+=1.43.5`, because the runner adds 1 to upstream micro versions
- When adding `@ver/rhel/...` stream-specific tags, replicate all relevant plain
  `@ver` constraints under the same stream prefix
- `@ver/rhel/...` filters by NM version within a build stream; `@rhelver`
  filters by distro version -- they are independent and can be combined

See the [README.md `@ver` Version Tags section](../README.md#ver-version-tags)
for detailed examples including multi-range and stream-specific patterns.

---

## 3. How to Add a New Test Case

Adding a test requires changes to **four files**, then verification.

### Step 1: Write the scenario

Add to the appropriate file in `features/scenarios/`. Follow the tag ordering
convention:

```gherkin
@RHEL-23456
@ver+=1.48.0
@my_new_test_name
Scenario: nmcli - bond - verify my new behavior
* Add "bond" connection named "bond0" for device "nm-bond" with options
      """
      autoconnect no mode active-backup
      """
* Bring "up" connection "bond0"
Then "nm-bond" is visible with command "nmcli -t -f DEVICE connection show --active"
```

If you need a step that doesn't exist yet, implement it in the appropriate file
under `features/steps/`. Steps use the `@step('...')` decorator from Behave and
call `nmci.*` API functions.

### Step 2: Register in `mapper.yaml`

Add an entry under `testmapper: default:` (or the appropriate subcomponent
section for hardware-specific tests like WiFi, InfiniBand, GSM, DCB):

```yaml
- my_new_test_name:
    feature: bond
    tags: gate              # optional: gate, customer-scenario, package names
    timeout: 15m            # optional: overrides default 10m
```

Available fields per test entry:

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `feature` | Yes | -- | Feature file name (without `.feature` extension) |
| `tags` | No | (none) | Space-separated: `gate`, `customer-scenario`, package names |
| `timeout` | No | `10m` | Test timeout (e.g., `15m`, `60m`) |

### Step 3: Regenerate metadata

```bash
python3 update_tests_fmf.py
```

This regenerates `tests.fmf` (FMF metadata with deterministic UUIDs and
ordering) and all `plan/*.fmf` files. **Never edit `tests.fmf` manually.**

### Step 4: Verify

```bash
# Unit tests (includes freshness check for tests.fmf)
python3 -m pytest nmci/test_nmci.py

# Run the test locally
run/runtest.sh my_new_test_name

# Full HTML report
NMCI_DEBUG=yes run/runtest.sh my_new_test_name
```

Bash completion is available: `run/runtest.sh my_new<tab>` will complete the
test name. The script also accepts a leading `@` for convenient tag pasting.

---

## 4. CI Pipeline

### Overview

NM-CI uses a multi-tier CI system:

| Tier | System | Purpose | Trigger |
|------|--------|---------|---------|
| Unit tests | GitLab CI | Python unit tests (`pytest nmci`) | Automatic on every MR push |
| Integration tests | Jenkins (CentOS CI) | Full Behave test execution on VMs | After maintainer review/approval |
| TMT / Testing Farm | TMT | FMF-driven test execution | On-demand / nightly |

### GitLab CI (`.gitlab-ci.yml`)

Two stages:

**UnitTests** (runs automatically on every MR event):
- Runs in a Fedora container
- Executes `python3 -m pytest nmci` -- this includes:
  - `test_fmf()`: validates that `tests.fmf` is in sync with `mapper.yaml`
  - Version control logic tests
  - Mapper parsing tests
- On failure, posts an unresolved comment to the MR discussion linking to the
  test report
- Produces JUnit XML artifact visible in GitLab's test report UI

**TestResults** (manual trigger):
- Fetches JUnit results from the external Jenkins pipeline
- Downloads `junit.xml` and NM RPM artifacts from Jenkins
- Reports pass/fail in GitLab based on `<failure>` tags in the XML

### Jenkins / CentOS CI

This is the main integration testing engine for MR validation:

1. `cico_gitlab_trigger.py` receives GitLab webhooks, parses CI directives from
   the MR description/comments
2. `runner.groovy` (Jenkins pipeline) clones the repo and invokes
   `node_runner.py`
3. `node_runner.py` provisions bare-metal CentOS CI machines, optionally builds
   NM from source, distributes tests across machines, and collects results
4. Tests execute via `run/runtest.sh` on the provisioned machines
5. Results are uploaded as Jenkins artifacts (JUnit XML + HTML reports)

### What Triggers CI Runs

| Event | What Happens |
|-------|-------------|
| Push to MR | UnitTests run automatically. Integration tests trigger after maintainer approval. Only tests in changed `.feature` files run by default. |
| `rebuild` comment on MR | Re-triggers the full pipeline with current overrides |
| Comment with `@` directives | Triggers a new run with the specified overrides |

### CI Directives

Place these in the MR description, the last commit message, or a `rebuild`
comment. Priority order: `rebuild` comment > commit message > MR description.

| Directive | Effect |
|-----------|--------|
| `@RunTests:test1,test2` | Run only the specified tests |
| `@RunTests:*` | Run all tests |
| `@RunFeatures:bond,ipv4` | Run all tests in the specified features |
| `@Build:main` | Build NM from the main branch |
| `@Build:<commit-hash>` | Build NM from a specific commit |
| `@OS:rhel9.3` | Test on RHEL 9.3 |
| `@OS:c9s` | Test on CentOS 9 Stream |
| `@OS:Fedora-39` | Test on Fedora 39 |

**Defaults:** Tests run on CentOS 10 Stream with the latest NM COPR build
(CentOS) or stock NM RPM (internal).

### How to Re-trigger

- Comment `rebuild` on the MR to re-run with existing overrides
- Comment with `@` directives for one-time overrides (e.g.,
  `@RunTests:my_test rebuild`)
- Push a new commit (triggers automatically)
- Skip CI: `git push -o ci.skip` or use "Rebase without pipeline" in GitLab UI

### Cross-linking MRs

You can interlink NetworkManager and NetworkManager-ci merge requests:

- In an **NM MR** description, mention `NetworkManager-ci!123` to use test code
  from NM-CI MR #123
- In an **NM-CI MR** description, mention `NetworkManager!456` to build NM from
  NM MR #456

### Older Builds

In CentOS CI, older builds running on the same OS from the same MR are
automatically cancelled when a new push arrives, to save resources. This results
in an "Aborted" message in the MR discussion -- this is expected behavior.

---

## 5. Common CI Failure Patterns

### 5.1 How to Tell Infra from Code at a Glance

When a test fails, check these signals first to decide where to look:

| Signal | Infra failure | Code failure |
|--------|--------------|--------------|
| GitLab MR comment says `NO RESULTS`, `BAD RESULTS`, `TIMEOUT`, or `Job unexpectedly aborted!` | Yes | No |
| Jenkins artifacts contain `config.log` | Yes (NM build failed) | No |
| HTML report is a raw `<pre>` journal dump ("No report generated, dumping NM journal log") | Yes (behave never ran) | No |
| No HTML report file at all (`"No HTML reprted!"` in JUnit XML) | Yes | No |
| Failure is in the **Before** pseudo-step of the HTML report | Usually (env/package/service) | Rarely |
| Failure is in a regular `Given`/`When`/`Then` step | No | Yes |
| Embed `"Exception in before scenario tags"` with "No such file or directory" for a binary | Often (package silently not installed) | Sometimes (wrong path in test) |
| Embed `"CRASHED_STEP_NAME"` present | Rarely (NM crashed during setup) | Yes (code change caused crash) |
| Embed `"Found important AVCs"` present | No | Yes |
| Embed `` "`backoff` message found in NM journal" `` present | No | Yes |
| Many unrelated tests fail across multiple features at once | Yes (testbed or machine issue) | No |

The single most reliable indicator: **look at the HTML report structure**.
If the report has properly formatted Behave output with coloured steps, the
infrastructure worked and the failure is in test logic. If the report is a plain
`<pre>` block of raw journal lines, or is absent entirely, the infrastructure
failed before Behave could run.

---

### 5.2 Infrastructure Failures

#### Machine provisioning

Test machines are reserved from the CentOS CI Duffy pool. Provisioning is
retried every 60 seconds for up to 180 minutes before aborting.

| Symptom | Cause | Action |
|---------|-------|--------|
| `"Unable to reserve a machine in 180 minutes"` in GitLab comment | Duffy pool exhausted | Re-trigger later; infra congestion |
| `"Job unexpectedly aborted!"` in GitLab comment, no `junit.xml` and no `config.log` in artifacts | Pipeline orchestrator (`node_runner.py`) itself crashed | Re-trigger; check Jenkins console for Python traceback |
| Jenkins job shows "Aborted" | A newer push cancelled an older run | Expected; check the newer run |
| Machine SSH timeout after setup | Machine came up but networking is broken | Machine creation is retried up to 3 times automatically; if all fail, re-trigger |

#### NM build failures

When `@Build:<ref>` is specified, `run/centos-ci/scripts/build.sh` downloads a
build script from the NM repository and compiles NM from source.

| Symptom | Cause | Action |
|---------|-------|--------|
| `config.log` artifact present in Jenkins | NM failed to compile | Check the build log; verify the `@Build:` ref is valid |
| `"BUILDING ... FAILED"` in Jenkins console, no `config.log` | `wget` failed to download the build script (no retries, no timeout) | Verify the NM ref exists and has the `automation/` branch; re-trigger |
| All tests report `FAIL` immediately without running, sentinel `/tmp/nm_compilation_failed` exists | NM build failed on the machine | See above |

> **Note:** The wget that fetches the build script (`run/centos-ci/scripts/build.sh`)
> has **no retry and no timeout**. A single transient network error permanently
> aborts the entire build run.

#### Package installation failures and silent drops

The test environment installs many packages during setup. Several patterns can
cause packages to be silently missing at test time.

**The core problem:** `dnf` is invoked with `--skip-broken` (dnf4) or
`--skip-unavailable` (dnf5) throughout `prepare/envsetup/pkg_install_common.sh`.
A package that fails to download or resolve is silently omitted -- no error
propagates to the caller, `check_packages` only verifies a small fixed subset,
and the missing package surfaces later as a `"command not found"` or
`"No such file or directory"` error inside a step.

Common root causes for silent drops:

- **Pinned Koji/Brew RPM URLs at pruned builds:** Many packages are specified
  as absolute HTTP URLs to Koji (`kojipkgs.fedoraproject.org`) or internal Brew
  (`download.devel.redhat.com`) at a pinned version (e.g.,
  `tcpreplay-4.3.3-3.fc34.x86_64.rpm`). If that build is pruned from the server
  or the internal mirror is unreachable, dnf gets a 404 or a connection error,
  skips the package with `--skip-broken`, and continues silently.

- **EPEL bootstrap failure:** Each distro-specific install script starts with:
  ```bash
  [ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-N.noarch.rpm
  ```
  This `rpm -i` has no retry and no timeout. If it fails (404, network error,
  EPEL not yet published for a new RHEL major), the EPEL repo is never
  configured. All subsequent packages that live only in EPEL are then silently
  skipped by `--skip-broken`. The only retry is a single `sleep 20` + retry of
  `install_"$release"_packages` in `prepare/envsetup/02_install_packages.sh`.

- **SRPM build failures (tayga, radvd on EL10):** `build_srpm` in
  `prepare/envsetup/utils.sh` downloads a `.src.rpm` from Koji, installs it,
  runs `dnf build-dep`, and calls `rpmbuild -bb`. The output RPM path is then
  added to `$PKGS_INSTALL` unconditionally. If any step in this chain fails
  (wget 404, build-dep unavailable, compile error), the output RPM is never
  produced, and `dnf install` of the literal path fails:
  ```
  Error: No such file or directory: '/root/rpmbuild/RPMS/x86_64/tayga-0.9.6-...rpm'
  ```
  With `--skip-broken`, this is silently dropped. Tests that call `tayga` or
  `radvd` will fail at runtime.

- **`get_centos_pkg_release` returns empty:** This helper (`utils.sh`) runs
  `curl -s <url>/` with no timeout to parse a CBS/Koji directory listing and
  extract the package version. If `curl` times out or the server returns
  unexpected output, the version variable is empty. The assembled package URL
  then contains a double slash and empty version component:
  ```
  openvswitch2.17-2.17.0-.x86_64.rpm   # note empty version
  ```
  dnf fails with HTTP 404 and skips with `--skip-broken`.

#### wget/curl without timeouts

Several `wget` calls in the setup scripts use `--tries=5 --waitretry=2` for
retry logic but **do not set `--timeout` or `--read-timeout`**. If the target
server is reachable but very slow, each of the 5 attempts can hang for minutes,
causing the overall setup to stall.

Affected calls and their consequences:

| Script | URL / Purpose | Missing guard | Consequence if it fails |
|--------|--------------|---------------|------------------------|
| `prepare/envsetup/03_configure_networking.sh:203-204` | WiFi EAP certs (`/tmp/certs/client.pem`, `eaptest_ca_cert.pem`) from internal lab server | No file-existence check after wget; `touch /tmp/nm_wifi_configured` is written unconditionally | EAP/WiFi tests fail at runtime: `"Failed to open /tmp/certs/client.pem: No such file or directory"` |
| `prepare/envsetup/utils.sh:327` | `.src.rpm` download in `build_srpm` | No check that rpm was installed or rpmbuild succeeded before adding output path to `$PKGS_INSTALL` | `dnf install` of non-existent RPM path; package silently dropped |
| `prepare/netdevsim.sh:55` | Kernel `.src.rpm` from Brew/Koji | Partial check on extracted source tree | `rpmbuild` fails; netdevsim kernel module cannot be built; netdevsim tests fail at setup |
| `run/centos-ci/scripts/build.sh:21` | NM build script from GitLab/GitHub raw URL | No retry at all | wget failure sets `/tmp/nm_compilation_failed`; all tests aborted |

#### Virtual testbed failures

The test environment uses 10 virtual ethernet devices (`eth1`–`eth10`) created
by `prepare/vethsetup.sh` inside a network namespace.

| Symptom | Cause | Action |
|---------|-------|--------|
| `"SETUP ERROR: We do not have network available via nmcli command."` printed, no HTML report | `vethsetup.sh` or `envsetup.sh` failed before Behave started | Re-trigger; check if machine has external connectivity |
| Test fails in the **Before** pseudo-step with `"testeth0 check"` embed | `testeth0` was not connected at scenario start; 10 reconnect attempts (1 s each) all failed | Re-trigger; usually transient; investigate `vethsetup.sh` if recurring |
| Many tests fail in Before step with "Regenerate vethsetup" in logs | Virtual testbed state was corrupted between tests | Re-trigger; if recurring, a tag cleanup may have broken the testbed |

#### TMT orchestration failures

| GitLab comment | Meaning | Action |
|----------------|---------|--------|
| `"NO RESULTS"` | Machine died mid-run; no `summary.txt` was retrieved | Re-trigger |
| `"BAD RESULTS"` | `summary.txt` exists but has unexpected format (truncated write) | Re-trigger |
| `"TIMEOUT"`, `Missing: N` | Tests ran but N results were never written (test was killed by timeout without producing output) | Check which tests are listed as missing; consider raising `timeout:` in `mapper.yaml` |

The default per-test timeout is **10 minutes**, read from `mapper.yaml`
`timeout:` field (fallback in `run/centos-ci/scripts/runtest.sh`). If a test
reliably times out, increase `timeout:` in `mapper.yaml` rather than adding
infrastructure retries.

#### GitLab CI unit test failures

| Symptom | Cause | Action |
|---------|-------|--------|
| `UnitTests` stage fails with package install errors | Fedora container registry or DNF mirror transient failure | Re-trigger |
| `test_fmf` fails in `UnitTests` | `tests.fmf` is out of sync with `mapper.yaml` | Run `python3 update_tests_fmf.py` and commit the updated `tests.fmf` |
| All tests SKIP (exit code 77) | Version gates say the tests don't apply to this NM/OS | Check `@ver+=`, `@rhelver+=`, `@fedver+=` tags on the scenarios |

---

### 5.3 Code Failures

Code failures are failures in test logic or NM behaviour detected by the test
framework. They produce structured Behave HTML output with coloured steps and
embedded diagnostic data.

#### Step assertion failures (most common)

A `Then "pattern" is visible` step failed to match actual output, or a step
raised a Python exception.

- **Report shows:** `"Error Message"` embed (the assertion text or exception
  message) and `"Error Traceback"` embed (full Python traceback), both under
  the failed step.
- **To investigate:** Check the `"Commands"` embed in the step immediately
  before the failing one -- it contains the actual command output that was
  checked. Check the `"NM"` embed in the After pseudo-step for the NM journal
  during the scenario.
- **Typical root causes:** typo in a command name or argument, wrong option
  name, wrong file path, output format changed in a newer NM version,
  incorrect regex in the assertion pattern.

#### NM crash (PID change)

NM's PID is captured at `before_scenario` and compared after every step.
A PID change means NM restarted (crashed and was restarted by systemd).

- **Report shows:** `"CRASHED_STEP_NAME"` embed (the step name where the
  crash was first detected), then one of:
  - `"COREDUMP"` embed with GDB backtrace from `coredumpctl debug`
  - `"FAF"` embed with ABRT/FAF URLs or raw backtrace
  - `"NO_COREDUMP/NO_FAF"` embed: `"!!! no crash report detected, but NM PID changed !!!"`
- **Banner printed to stdout:**
  ```
  !! NM CRASHED. NEEDS INSPECTION. FAILING THE TEST !!
  !!  CRASHING STEP: <step name>                     !!
  ```
- **Note:** crash detection has ~1-step latency. The actual crash may have
  happened in the step *before* the one named in `CRASHED_STEP_NAME`.
- **To investigate:** look at the `"COREDUMP"` or `"FAF"` backtrace; also
  check the `"NM"` journal embed for the last log lines before the crash.

#### SELinux AVC failures

`ausearch` is run after every scenario using a checkpoint file so only new
AVCs since the last scenario are reported. AVCs that match NM-related packages
(`NetworkManager`, `ModemManager`, `nmcli`, `nmtui`, `dnsmasq`) and are not
in the per-scenario ignore list cause hard assertion failure.

- **Report shows:** `"Important SELinux AVCs during this scenario"` embed with
  raw `ausearch` output in the After pseudo-step.
- **Error:** `"Found important AVCs"`
- **To suppress temporarily:** set `NMCI_IGNORE_AVC=1` (embeds AVCs but does
  not fail). To permanently ignore a known-benign AVC, add it to
  `context.ignore_avcs` in the relevant step or tag handler.
- **Root cause:** typically a missing or outdated SELinux policy for a new NM
  operation; file a `selinux-policy` bug and add a temporary ignore until the
  policy is shipped.

#### Backoff message detection

After every scenario, the NM journal is scanned for
`"backoff for N seconds before the resync."`. If found, the scenario fails.

- **Error:** `` "`backoff` message found in NM journal" ``
- **Suppress per-scenario:** add tag `@ignore_backoff_message`.
- **Root cause:** the change causes NM to repeatedly detect a configuration
  change and schedule a resync, triggering a backoff storm. Investigate whether
  the code change introduces a loop in NM's configuration reload path.

#### Exceptions in tag setup or teardown

Tag handlers (`@openvpn`, `@hostapd`, `@netdevsim`, etc.) run in
`before_scenario` and `after_scenario`. Exceptions are accumulated and raised
together at the end of each phase.

- **Report shows:** `"Exception in before scenario tags"` or `"Exception in
  after scenario tags"` embed in the Before/After pseudo-step, containing the
  full Python traceback for each failed tag handler.
- **Infra vs. code distinction:** if the traceback shows
  `"No such file or directory"` for a binary (e.g., `openvpn`, `hostapd`),
  the package was silently not installed (see silent dnf drops above). If it
  shows an assertion error or wrong output from a running binary, it is a
  test logic problem.

#### Timeout / SIGTERM kill

The per-test timeout (default 10 minutes, tunable via `mapper.yaml`
`timeout:`) sends SIGTERM to the Behave process when exceeded.

- `environment.py` installs a SIGTERM handler that raises
  `AssertionError("killed externally (timeout)")`, giving Behave a chance to
  produce a partial HTML report before dying.
- **Report shows:** `"Error Message"` embed with `"killed externally (timeout)"`.
- **Typical causes:** test logic hangs (blocking `nmcli` call, NM stuck in a
  state the test doesn't handle, missing cleanup that waits forever). If
  a test reliably times out, raise `timeout:` in `mapper.yaml` and also
  investigate what is blocking.

#### `@xfail` unexpected pass

If a scenario tagged `@xfail` starts passing, `run/runtest.sh` converts the
PASS to FAIL. The underlying bug was likely fixed; remove `@xfail` and the
associated version gate.

#### Failed systemd services

Before and after each scenario, `systemctl list-units --state=failed` is
checked. Failed services are embedded (`"service failed during scenario run: X"`)
but do not directly fail the test -- the failure usually manifests as a step
assertion error triggered by the broken service.

---

### 5.4 Reading HTML Reports

#### Report naming

- **On Jenkins/CentOS CI:**
  `FAIL-report_NetworkManager-ci-M{machine_id}_Test{XXXX}_{test_name}.html`
- **Locally:**
  `/tmp/report_NetworkManager-ci_Test{XXXX}_{test_name}.html`

A `FAIL-` prefix means Behave reported failure. Absence of the file, or a file
containing only a raw `<pre>` block, means Behave never ran (infra failure).

Enable full local reports with `NMCI_DEBUG=yes run/runtest.sh test_name`.

Example reports:
- [PASS report](https://vbenes.fedorapeople.org/NM/PASS_bond_8023ad_with_vlan_srcmac.html)
- [FAIL report](https://vbenes.fedorapeople.org/NM/FAIL_ipv6_survive_external_link_restart.html)

#### Report structure

```
Global summary (feature counts, scenario counts, suite duration)
└── Per-feature block
    ├── Feature stats (passed/failed/skipped, Expand All Failed button)
    └── Per-scenario block
        ├── Tags as links, scenario name, duration
        ├── Before  ← tag-based setup (failure here = env/infra problem)
        ├── * Step 1 (Given/When/Then/And/*)
        ├── * Step 2
        │     └── [embedded data sections, numbered]
        ├── ...
        └── After   ← tag-based teardown + journal/log collection
```

The **Before** and **After** entries are pseudo-steps representing tag-based
environment setup and teardown. A failure in **Before** almost always means an
environment or infrastructure problem, not a test logic error.

#### Key embedded data sections

Each embed appears collapsed under its step (click to expand). The most
important ones:

| Embed caption | Location | What it means |
|---------------|----------|----------------|
| `"Error Message"` | Failed step | Python assertion text or exception message |
| `"Error Traceback"` | Failed step | Full Python traceback |
| `"Commands"` / module name | Any step | All nmcli/process calls and their output in that step |
| `"NM"` | After pseudo-step | NM journal from before_scenario to end of scenario |
| `"STDOUT"` | After pseudo-step | runtest stdout piped through journald |
| `"CRASHED_STEP_NAME"` | Failed step or After | Step where NM PID change was first detected |
| `"NO_COREDUMP/NO_FAF"` | Alongside CRASHED_STEP_NAME | NM crashed but no crash report was captured |
| `"COREDUMP"` | Failed step | GDB backtrace from `coredumpctl debug` |
| `"FAF"` | Failed step | ABRT/FAF URLs or raw backtrace |
| `"Package list"` | Alongside COREDUMP | `rpm -qa` output at crash time |
| `"Important SELinux AVCs during this scenario"` | After pseudo-step | Filtered NM-relevant AVC records (these cause failure) |
| `"SELinux AVCs during this scenario"` | After pseudo-step | All AVCs (informational; only important ones cause failure) |
| `"Exception in before scenario tags"` | Before pseudo-step | Stack traces from tag setup failures |
| `"Exception in after scenario tags"` | After pseudo-step | Stack traces from tag teardown failures |
| `"service failed during scenario run: X"` | After pseudo-step | Systemd service journal for a service that failed during the test |
| `"failed services' statuses"` | Before pseudo-step | `systemctl status` of services already failed before the scenario |

#### `fail_only` truncation

Many embeds are created with `fail_only=True`: on PASS, only the first line
and last 2 KB are shown; on FAIL, the full content is shown. This is expected
behaviour and not a report defect.

**PASS reports** contain minimal content (only cleanup output) to save space.
Full diagnostic detail is only present in FAIL reports.

---

### 5.5 Key Diagnostic Strings Quick Reference

Use these to search (`Ctrl+F`) in the HTML report or grep in logs.

| String to search for | Source | Cause | Action |
|----------------------|--------|-------|--------|
| `"SETUP ERROR: We do not have network available"` | `prepare/envsetup.sh` | Vethsetup or machine networking failed before Behave | Re-trigger; check vethsetup |
| `"killed externally (timeout)"` | HTML report embed | Per-test timeout (SIGTERM) hit | Raise `timeout:` in `mapper.yaml`; investigate what hung |
| `"NM Crashed as new PID"` | NM journal embed | NM process restarted (PID changed) | Check `COREDUMP` / `FAF` embeds |
| `"NM CRASHED. NEEDS INSPECTION."` | stdout / HTML | NM crash confirmed | See `CRASHED_STEP_NAME` embed |
| `"!!! no crash report detected, but NM PID changed !!!"` | `NO_COREDUMP/NO_FAF` embed | NM restarted without leaving a dump | May be a clean NM restart; check NM journal for reason |
| `"No such file or directory"` on a known binary | Step embed | Package silently not installed (dnf `--skip-broken`) | Re-trigger; verify the Koji/Brew URL for that package still resolves |
| `"No such file or directory"` on `/tmp/certs/client.pem` | Step embed | WiFi EAP cert wget failed silently | Check lab cert server reachability; re-trigger |
| `"command not found"` on a test tool | Step embed | Package silently not installed | Re-trigger; check EPEL bootstrap and pinned RPM URLs |
| `"Found important AVCs"` | HTML report embed | SELinux AVC involving NM package | Check AVC details; file selinux-policy bug or add ignore |
| `` "`backoff` message found in NM journal" `` | HTML report embed | NM resync storm triggered by the change | Investigate config reload loop in the MR diff |
| `"Exception in before scenario tags"` | Before pseudo-step embed | Tag setup raised an exception | Check traceback: missing binary (infra) vs. assertion error (code) |
| `"No HTML reprted!"` (sic) | JUnit XML `<failure>` text | Behave never produced a report | Infra failure; check `tmt.m{N}.log` in Jenkins artifacts |
| `"no summary.txt retrieved"` | GitLab MR comment | Machine died during test run | Re-trigger |
| `"Job unexpectedly aborted!"` | GitLab MR comment | Pipeline orchestrator crashed | Re-trigger; check Jenkins console for Python traceback |
| `"Unable to reserve a machine"` | GitLab MR comment | Duffy pool exhausted | Re-trigger later |
| `"BUILDING ... FAILED"` | Jenkins console | NM build failure | Check `config.log` artifact; verify `@Build:` ref |
| `"backoff for N seconds before the resync."` | NM journal embed | NM resync backoff (bug indicator) | Check if MR introduces a config-change loop in NM |
| `"Regenerate vethsetup!!"` | Logs / Before embed | Virtual testbed was corrupted | Re-trigger; investigate tag cleanup if recurring |

---

## 6. Downstream Testing (Testing Farm / Polarion)

### TMT Plan Structure

TMT (Test Management Tool) executes tests through a 5-step pipeline defined in
`plan/main.fmf`:

1. **discover** -- reads `tests.fmf` to find tests (each test has a
   deterministic UUID)
2. **provision** -- runs locally on the provisioned machine
3. **prepare** -- installs packages, runs `vethsetup.sh` and `envsetup.sh`
4. **execute** -- runs each test via `run/runtest.sh <testname>`
5. **report** -- generates HTML report + optional Polarion upload

### Polarion Integration

- Each test has a deterministic UUID5 identifier (computed from the test name),
  mapped to a Polarion work item
- `tests.fmf` contains `link: implements: <polarion-url>` entries linking tests
  to Polarion work items
- The `update_tests_fmf.py` script can optionally query Polarion (via `pylero`)
  to discover and sync links
- Test results are uploaded to Polarion when `polarion=yes` is set in the TMT
  plan

### Auto-generated Plan Files

Plan files in `plan/` are regenerated by `update_tests_fmf.py` from
`mapper.yaml`. They should not be manually edited.

| Plan Type | Example | Filter |
|-----------|---------|--------|
| Per-feature | `plan/features/bond.fmf` | Lists all bond tests by name |
| Per-tag | `plan/gate.fmf` | `filter: tag:gate` |
| Per-subcomponent | `plan/NetworkManager-wifi.fmf` | `filter: name:/tests/NetworkManager-wifi/.*` |
| All default tests | `plan/all.fmf` | `filter: name:/tests/[^/]*` |

---

## 7. Assessing Test Coverage for an MR

When reviewing an MR to determine if test coverage is adequate:

### Checklist

1. **Identify affected features:** What NM functionality does the change touch?
   (bonding, IPv4, DNS, VPN, etc.)

2. **Check existing tests:** Look in `features/scenarios/<feature>.feature` for
   tests covering the affected behavior.

3. **Check version gating:** If the change is version-specific, ensure tests
   have appropriate `@ver+=` tags so they only run where the feature exists.

4. **Verify registration:** Confirm new tests are registered in `mapper.yaml`
   with the correct feature and tags.

5. **Gating coverage:** Tests tagged `gate` in `mapper.yaml` run in the gating
   pipeline. High-impact changes should have at least one gating test.

6. **Cross-feature impact:** Changes to core NM behavior (connection
   activation, DNS handling, etc.) may need tests across multiple feature files.

7. **Hardware-specific tests:** WiFi, InfiniBand, GSM, and DCB tests run on
   dedicated hardware via subcomponents in `mapper.yaml`. Verify if the change
   affects these areas.

### Quick Coverage Checks

```bash
# List all tests for a feature (dry run)
run/runfeature.sh bond --dry

# Count gating tests for a feature
grep -A2 "feature: bond" mapper.yaml | grep "tags:.*gate" | wc -l

# See recent test changes for a feature
git log --oneline -20 -- features/scenarios/bond.feature

# Run unit tests to validate consistency
python3 -m pytest nmci/test_nmci.py
```

### What "Adequate" Looks Like

- **Bug fix:** At least one test that reproduces the bug, tagged with the
  relevant Jira issue tag (e.g., `@RHEL-12345`) and version gates
- **New feature:** Tests covering the main functionality plus edge cases, with
  `@ver+=` tags matching the NM version where the feature lands
- **Behavioral change:** Existing tests updated if their assumptions changed;
  new tests for the new behavior; version-gated variants if the old behavior
  must still be tested on older versions
- **Config/connection type changes:** Tests that create, modify, activate, and
  verify the connection type, plus cleanup verification

---

## Quick Reference

### Running Tests Locally

> **Warning:** Test execution modifies the system's network configuration.
> `vethsetup.sh` deletes all connections and disables all devices except the
> default gateway. Run tests only inside a dedicated VM or container.

```bash
# Single test
run/runtest.sh test_name

# With full HTML report
NMCI_DEBUG=yes run/runtest.sh test_name

# Entire feature
run/runfeature.sh bond

# List tests in a feature (dry run)
run/runfeature.sh bond --dry

# Unit tests
python3 -m pytest nmci/test_nmci.py

# Override NM version detection
NM_VERSION=1.48.0 run/runtest.sh test_name
```

### Key Files to Know

| File | Purpose |
|------|---------|
| `mapper.yaml` | Central test registry -- add tests here |
| `features/scenarios/*.feature` | Test specifications in Gherkin |
| `features/steps/*.py` | Step implementations in Python |
| `nmci/tags.py` | Tag-based environment setup/teardown |
| `features/environment.py` | Test lifecycle hooks |
| `tests.fmf` | Generated metadata -- run `update_tests_fmf.py` to refresh |
| `run/runtest.sh` | Main test execution entry point |
| `.gitlab-ci.yml` | GitLab CI pipeline definition |
