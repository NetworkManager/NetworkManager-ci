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

### Infrastructure Failures (not your code)

| Symptom | Meaning | Action |
|---------|---------|--------|
| UnitTests fails with package install errors | Fedora container registry or DNF mirror issue | Re-trigger |
| `test_fmf` fails in UnitTests | `tests.fmf` is out of sync with `mapper.yaml` | Run `python3 update_tests_fmf.py` and commit |
| Jenkins job shows "Aborted" | A newer push cancelled the older run | Expected -- check the newer run |
| All tests SKIP (exit code 77) | Version control says tests don't apply to this NM/OS | Check `@ver`/`@rhelver` tags |
| `testeth0` connectivity failure | Virtual testbed lost its default route | Testbed setup issue; re-trigger or investigate `vethsetup.sh` |
| Machine provisioning timeout | CentOS CI infrastructure is overloaded | Re-trigger later |

### Code Failures (likely related to your change)

| Symptom | Meaning | Action |
|---------|---------|--------|
| Test FAILs with assertion error | A `Then "pattern" is visible` step didn't match | Check the HTML report for actual command output |
| NM crash detected (coredump) | NetworkManager crashed during the test | HTML report includes crash details and FAF links |
| Test timeout (10m default) | The test hung | Check for missing cleanup, blocking `nmcli` call, or NM bug |
| `@xfail` test PASSes unexpectedly | An expected-failure test started passing | The underlying bug may be fixed; update the test |
| Multiple tests fail in the same feature | A tag-based environment setup may be broken | Check `nmci/tags.py` for the relevant tags |

### Reading HTML Reports

- **PASS reports** contain minimal info (just cleanup output) to save space
- **FAIL reports** contain full details: all command outputs, NM journal logs,
  SELinux AVCs, crash dumps
- Reports are stored in `/tmp` on the test machine and published via HTTP on
  port 8080 when available
- Enable verbose reports locally with `NMCI_DEBUG=yes run/runtest.sh test_name`
- Example reports:
  - [PASS report](https://vbenes.fedorapeople.org/NM/PASS_bond_8023ad_with_vlan_srcmac.html)
  - [FAIL report](https://vbenes.fedorapeople.org/NM/FAIL_ipv6_survive_external_link_restart.html)

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
