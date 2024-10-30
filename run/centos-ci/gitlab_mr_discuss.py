import base64
import json
import os
import sys

from node_runner import Runner

data = {}
data["object_kind"] = "note"
data["merge_request"] = {"iid": int(os.environ.get("CI_MERGE_REQUEST_IID"))}
data["repository"] = {"name": os.environ.get("CI_PROJECT_TITLE")}
data_str = base64.b64encode(json.dumps(data).encode("utf-8"))

r = Runner()
r._set_gitlab(data_str, os.environ.get("GITLAB_TOKEN"))

msg = "\n\n".join(sys.argv[1:])
print(f"Sending following comment to gitlab:\n{msg}")
r.gitlab.post_mr_discussion(msg)
r.gitlab.set_mr_discussion_resolved(False)
