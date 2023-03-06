from behave import step

import nmci


@step("Commentary")
def commentary_step(context):
    # Get the correct step to override.
    scenario = nmci.embed.get_current_scenario()
    if scenario is None:
        return
    step = scenario.current_step
    # Override the step, this will prevent the decorator to be generated and only the text will show.
    step.set_commentary(True)
