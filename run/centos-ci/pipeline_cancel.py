#!/usr/bin/python3
import logging
import sys
import os

from node_runner import Runner

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.debug("reading params")
    gl_token = os.environ.get("GL_TOKEN", None)
    if gl_token is None:
        print("Gitlab token missing. Exitting...")
        sys.exit(1)
    trigger_data, build_id, release = None, None, ""
    if len(sys.argv) > 2:
        build_id = sys.argv[1]
        logging.debug(f"Build id: {build_id}")
        trigger_data = sys.argv[2]
        logging.debug(f"Trigger Data Set? {not not trigger_data}")
    if len(sys.argv) > 3:
        release = sys.argv[3].replace("-stream", "")
    else:
        logging.debug(f"Not enough arguments {len(sys.argv)-1}, skipping...")
        exit(0)

    r = Runner()
    r._set_gitlab(trigger_data, gl_token)
    if r.gitlab is not None:
        r._gitlab_message = (
            f"{build_id}\n\n"
            f"Commit: {r.gitlab.commit}\n\n"
            "Aborted by the new run (or unexpected crash of node_runner)"
        )
        r.gitlab.set_pipeline("canceled", release)
        # Don't post the message to reduce email notifications.
        # r._post_results()
        r.gitlab.set_mr_discussion_resolved(False)
        exit(0)

    logging.debug("Gitlab Token or Trigger Data are missing or incorrect, skipping...")
