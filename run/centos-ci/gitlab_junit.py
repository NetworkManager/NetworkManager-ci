import gitlab
import os

for var in ["CI_SERVER_URL", "GITLAB_TOKEN", "CI_PROJECT_PATH", "CI_COMMIT_SHA"]:
    if var not in os.environ:
        print(var + " is not set")
        exit(2)

gl = gitlab.Gitlab(
    os.environ["CI_SERVER_URL"], private_token=os.environ["GITLAB_TOKEN"]
)
gl_project = gl.projects.get(os.environ["CI_PROJECT_PATH"])
commit = gl_project.commits.get(os.environ["CI_COMMIT_SHA"])
statuses = commit.statuses.list()
statuses = [
    status.target_url
    for status in statuses
    if status.target_url
    and "jenkins-networkmanager.apps.ocp.cloud.ci.centos.org" in status.target_url
]
if len(statuses) > 0:
    statuses.sort()
    status = statuses[-1]
    print(status + "/artifact/junit.xml")
    exit(0)
exit(1)
