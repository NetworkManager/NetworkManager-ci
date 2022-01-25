#!/usr/bin/python3
import logging
import sys

from node_runner import Runner

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.debug("reading params")
    gl_token, trigger_data, build_id = None, None, None
    if len(sys.argv) > 3:
        build_id = sys.argv[1]
        logging.debug(f"Build id: {build_id}")
        gl_token = sys.argv[2]
        logging.debug(f"Gitlab Token Set? {not not gl_token}")
        trigger_data = sys.argv[3]
        logging.debug(f"Trigger Data Set? {not not trigger_data}")
    else:
        logging.debug(f"Not enough arguments {len(sys.argv)-1}, skipping...")
        exit(0)

    r = Runner()
    r._set_gitlab(trigger_data, gl_token)
    if r.gitlab is not None:
        r._gitlab_message = (
            f"{build_id}\n\n"
            + "Aborted by the new run (or unexpected crash of node_runner)"
        )
        r.gitlab.set_pipeline("canceled")
        r._post_results()
        exit(0)

    logging.debug("Gitlab Token or Trigger Data are missing or incorrect, skipping...")
