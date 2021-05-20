#!/usr/bin/python3
import logging
import json
import os
import sys

def post_results (gl_trigger):
    msg = "CentOS Testing Summary\n\n"
    msg+="Aborted by the new run"
    gl_trigger.post_commit_comment(msg)


def set_gitlab (trigger_data, gl_token):
    with open("/etc/python-gitlab.cfg", "w") as cfg:
        cfg.write('[global]\n')
        cfg.write('default = gitlab.freedesktop.org\n')
        cfg.write('ssl_verify = false\n')
        cfg.write('timeout = 30\n')
        cfg.write('[gitlab.freedesktop.org]\n')
        cfg.write('url = https://gitlab.freedesktop.org\n')
        cfg.write('private_token = %s\n' %gl_token)
        cfg.write("\n")
        cfg.close()

    import base64
    content = base64.b64decode(trigger_data).decode('utf-8').strip()
    data = json.loads(content)
    logging.debug(data)
    from cico_gitlab_trigger import GitlabTrigger
    gitlab_trigger = GitlabTrigger(data)
    return gitlab_trigger

if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    logging.debug("reading params")
    if len(sys.argv) > 1:
        build_id = sys.argv[1]
        logging.debug(build_id)
        os.environ['BUILD_URL'] = build_id
    if len(sys.argv) > 2:
        gl_token = sys.argv[2]
        # NEVER PRINT THIS AS IT HAS GL_TOKEN
        # logging.debug(gl_token)
    if len(sys.argv) > 3:
        trigger_data = sys.argv[3]
        logging.debug(trigger_data)
    else:
        trigger_data = None

    if trigger_data:
        gitlab_trigger = set_gitlab(trigger_data, gl_token)
        logging.debug("DO we have gl trigger?")
        logging.debug(gitlab_trigger)
        if gitlab_trigger:
            logging.debug("canceling the pipeline")
            gitlab_trigger.set_pipeline('canceled')
            post_results (gitlab_trigger)
