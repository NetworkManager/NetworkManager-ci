"""Readable checkpoint operations backed by the GI helper and command steps."""

import re

from behave import step


CHECKPOINT_PATH = r"/org/freedesktop/NetworkManager/Checkpoint/[1-9][0-9]*"
HELPER = "contrib/gi/checkpoint.py"


@step('Create checkpoint "{name}" on "{device}" with rollback timeout "{timeout}"')
def create_checkpoint(context, name, device, timeout, overlap=False):
    flag = " --allow-overlapping" if overlap else ""
    context.execute_steps(
        f'* Note the output of "{HELPER} create {timeout}{flag} {device}" as value "{name}"\n'
        f'Then Noted value "{name}" contains "^{CHECKPOINT_PATH}$"'
    )


@step(
    'Create checkpoint "{name}" on "{device}" with rollback timeout "{timeout}" allowing overlap'
)
def create_overlapping_checkpoint(context, name, device, timeout):
    create_checkpoint(context, name, device, timeout, overlap=True)


@step('Creating a checkpoint on "{device}" fails because it overlaps "{name}"')
def overlapping_checkpoint_rejected(context, device, name):
    context.execute_steps(
        f"Then \"Failed:.*device '{re.escape(device)}' is already included in checkpoint <noted:{name}>\" "
        f'is visible with command "{HELPER} create 0 {device}" in "0" seconds'
    )


@step('There are "{count}" checkpoints')
def checkpoint_count(context, count):
    context.execute_steps(
        f'Then "exactly" "{count}" lines with pattern "^{CHECKPOINT_PATH}:" '
        f'are visible with command "{HELPER} show" in "0" seconds'
    )


@step('Checkpoint "{name}" is present')
def checkpoint_present(context, name):
    context.execute_steps(
        f'Then "^<noted:{name}>:" is visible with command "{HELPER} show" in "0" seconds'
    )


@step('Checkpoint "{name}" is gone within "{seconds}" seconds')
def checkpoint_gone(context, name, seconds):
    context.execute_steps(
        f'Then "^<noted:{name}>:" is not visible with command "{HELPER} show" in "{seconds}" seconds'
    )


@step('Rollback checkpoint "{name}" on "{device}"')
def rollback_checkpoint(context, name, device):
    # The helper can exit successfully after printing an asynchronous error.
    # Require the positive result, rather than relying on its exit status.
    context.execute_steps(
        f'Then "^{re.escape(device)} => OK$" is visible with command '
        f'"{HELPER} rollback <noted:{name}>" in "0" seconds'
    )


@step('Adjust checkpoint "{name}" rollback timeout to "{timeout}" seconds')
def adjust_checkpoint_timeout(context, name, timeout):
    context.execute_steps(
        f'Then "^Success$" is visible with command '
        f'"{HELPER} adjust-rollback-timeout <noted:{name}> {timeout}" in "0" seconds'
    )


@step(
    'Checkpoint "{name}" and IPv4 address "{address}" on "{device}" remain present for "{seconds}" seconds'
)
def checkpoint_and_address_remain(context, name, address, device, seconds):
    # Check both in every poll over one interval. Two consecutive waits would
    # change the timing and could miss an early rollback.
    context.execute_steps(
        f'Then "^<noted:{name}>:.*inet {re.escape(address)} " is visible with command '
        f'"{HELPER} show; ip -4 address show dev {device}" for full "{seconds}" seconds'
    )
