# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

NetworkManager-ci is a comprehensive test suite for NetworkManager using the Behave testing framework. It provides integration tests for NetworkManager functionality across different distributions and environments.

## Common Commands

### Running Tests

- **Single test**: `run/runtest.sh test_name` (supports tab completion)
- **Feature tests**: `run/runfeature.sh feature_name` 
- **List tests in feature**: `run/runfeature.sh feature_name --dry`
- **Unit tests**: `python3 -m pytest nmci/test_nmci.py`

### Development Commands

- **Lint checking**: Use `black` for code formatting (configured in pyproject.toml)
- **Type checking**: Use `mypy` (configured in pyproject.toml)
- **Test debugging**: Set `NMCI_DEBUG=yes` for full HTML reports
- **Version override**: Set `NM_VERSION=x.y.z` to simulate different NetworkManager versions

### Test Environment Setup

- **Environment setup**: `prepare/envsetup.sh` - installs packages and configures test environment
- **Virtual network setup**: `prepare/vethsetup.sh` - creates 11-device test network
- **GSM setup**: `prepare/initialize_modem.sh` - initializes GSM modems for testing

## Architecture Overview

### Core Components

- **`mapper.yaml`**: Central test configuration mapping tests to features, dependencies, and metadata
- **`nmci/`**: Core Python library containing test infrastructure and utilities
- **`features/`**: Behave test scenarios and step definitions organized by functional area
- **`run/`**: Test execution scripts and CI/CD runners
- **`prepare/`**: Environment setup and configuration scripts
- **`contrib/`**: Supporting files and reproducers needed for tests

### Key Python Modules

- **`nmci/tags.py`**: Tag-based test environment preparation and cleanup system
- **`nmci/helpers/version_control.py`**: Version-aware test execution logic
- **`features/environment.py`**: Behave framework hooks and test lifecycle management
- **`features/steps/`**: Step definitions organized by functional area (bond, bridge, team, connection, etc.)

### Test Organization

Tests are written in Gherkin format (`.feature` files) with Python step definitions. The framework supports:

- **Version control tags**: `@ver+=1.30`, `@rhelver+=8.4`, `@fedver+=32` for conditional test execution
- **Environment tags**: Setup/teardown automation via `@device_connect`, `@clean_up`, etc.
- **Behavioral tags**: `@xfail`, `@may_fail` for expected failure handling

### Test Execution Flow

1. **Environment setup**: `envsetup.sh` configures system and installs dependencies
2. **Version control**: Checks if test should run based on version tags
3. **Tag processing**: Executes before-scenario setup (device preparation, etc.)
4. **Test execution**: Runs Behave scenarios with step definitions
5. **Cleanup**: Tag-based cleanup and log collection
6. **Reporting**: HTML reports generated with embedded logs and screenshots

### CI/CD Integration

- **GitLab MR pipelines**: Automatic test execution on merge requests
- **Build overrides**: `@Build:branch_name` for testing specific NetworkManager builds
- **Test selection**: `@RunTests:test1,test2` or `@RunFeatures:feature1,feature2`
- **OS targeting**: `@os:rhel9.3`, `@os:c9s`, `@os:fedora-39`

### Testing Framework Features

- **Tag-based setup/teardown**: Automated environment preparation via decorator tags
- **HTML reporting**: Rich reports with embedded logs, command outputs, and nmtui screenshots
- **Network simulation**: Virtual test bed with bridges, bonds, VLANs, etc.
- **Multi-platform**: RHEL, CentOS Stream, Fedora support with version-aware test execution
- **Hardware testing**: Support for WiFi, GSM, Infiniband, and DCB hardware

## Development Workflow

### Adding New Tests

1. Write `.feature` file in appropriate `features/scenarios/` subdirectory
2. Add test mapping to `mapper.yaml` with dependencies and metadata
3. Create step definitions in relevant `features/steps/` module
4. Add version tags and environment tags as needed
5. Test locally with `run/runtest.sh test_name`

### Test Debugging

- Use `NMCI_DEBUG=yes` for comprehensive logging
- HTML reports are saved to `/tmp/` with embedded commands and logs
- Set breakpoints in step definitions for interactive debugging
- Use `@skip_in_centos` or version tags to control test execution

### Version Management

The framework uses sophisticated version control to run tests only on appropriate NetworkManager versions and distributions. Version tags support ranges (`@ver+=1.30`), distributions (`@rhelver+=8.4`), and stream-specific overrides (`@ver/rhel/9+=1.43.6`).