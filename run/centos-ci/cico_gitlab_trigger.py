#!/usr/bin/env python

import sys
import json
import os
import datetime
import time
import subprocess
import re

from pprint import pprint

default_os = ["9-stream"]
##next_os = 'RHEL8.4'
# next_branch_base = 'rhel-8'

jenkins_url = "https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/"


class GitlabTrigger(object):
    def __init__(self, data, config_files=["/tmp/python-gitlab.cfg"]):
        self.data = data
        # If we don't have python-gitlab we can still use object for parsing
        self.gl_project = None
        try:
            import gitlab

            self.gl_api = gitlab.Gitlab.from_config(
                "gitlab.freedesktop.org", config_files
            )
            group = "NetworkManager"
            self.gl_project = self.gl_api.projects.get(
                "%s/%s" % (group, data["repository"]["name"])
            )
        except:
            pass

    @property
    def request_type(self):
        return self.data["object_kind"]

    @property
    def comment(self):
        ret = None
        if self.request_type == "note":
            ret = self.data["object_attributes"]["note"].strip()
        return ret

    @property
    def description(self):
        ret = None
        if self.request_type == "note":
            ret = self.data["merge_request"]["description"]
        elif self.request_type == "merge_request":
            ret = self.data["object_attributes"]["description"]
        return ret

    @property
    def title(self):
        ret = None
        if self.request_type == "note":
            ret = self.data["merge_request"]["title"]
        elif self.request_type == "merge_request":
            ret = self.data["object_attributes"]["title"]
        return ret

    @property
    def source_branch(self):
        source_branch = None
        if self.request_type == "note":
            source_branch = self.data["merge_request"]["source_branch"]
        elif self.request_type == "merge_request":
            source_branch = self.data["object_attributes"]["source_branch"]
        return source_branch

    @property
    def target_branch(self):
        target_branch = None
        if self.request_type == "note":
            target_branch = self.data["merge_request"]["target_branch"]
        elif self.request_type == "merge_request":
            target_branch = self.data["object_attributes"]["target_branch"]
        return target_branch

    @property
    def source_project_id(self):
        target_branch = None
        if self.request_type == "note":
            target_branch = self.data["merge_request"]["source_project_id"]
        elif self.request_type == "merge_request":
            target_branch = self.data["object_attributes"]["source_project_id"]
        return target_branch

    @property
    def target_project_id(self):
        target_branch = None
        if self.request_type == "note":
            target_branch = self.data["merge_request"]["target_project_id"]
        elif self.request_type == "merge_request":
            target_branch = self.data["object_attributes"]["target_project_id"]
        return target_branch

    @property
    def wip(self):
        wip = False
        if self.request_type == "note":
            wip = self.data["merge_request"]["work_in_progress"]
        elif self.request_type == "merge_request":
            wip = self.data["object_attributes"]["work_in_progress"]
        return wip

    @property
    def latest_main_commit(self):
        if self.gl_project is None:
            return None
        branch = self.gl_project.branches.get("main")
        commit_id = branch.commit["id"]
        return commit_id

    @property
    def commit(self):
        commit = None
        if self.request_type == "note":
            if "merge_request" in self.data:
                commit = self.data["merge_request"]["last_commit"]["id"].strip()
        elif self.request_type == "merge_request":
            commit = self.data["object_attributes"]["last_commit"]["id"].strip()
        if commit == self.latest_main_commit:
            commit = None
        return commit

    @property
    def commit_author(self):
        author = None
        if self.request_type == "note":
            author = (
                self.data["merge_request"]["last_commit"]["author"]["email"]
                .split("@")[0]
                .strip()
            )
        elif self.request_type == "merge_request":
            author = (
                self.data["object_attributes"]["last_commit"]["author"]["email"]
                .split("@")[0]
                .strip()
            )
        return author

    @property
    def commit_message(self):
        message = None
        if self.request_type == "note":
            message = self.data["merge_request"]["last_commit"]["message"]
        elif self.request_type == "merge_request":
            message = self.data["object_attributes"]["last_commit"]["message"]
        return message.strip()

    def post_commit_comment(self, text):
        com = self.gl_project.commits.get(self.commit)
        exc = None
        for _ in range(3):
            try:
                com.comments.create({"note": text})
                return
            except Exception as e:
                exc = e
                time.sleep(1)
        print(f"Unable to post comment to gitlab:\n{text}\n\nException: {exc}")

    def play_commit_job(self):
        pipeline = self.pipeline
        jobs = pipeline.jobs.list()
        for job in jobs:
            if job.name == "TestResults":
                job_trigger = self.gl_project.jobs.get(job.id)
                job_trigger.play()

    def mapper_text(self, refspec):
        print(">> Reading mapper.yaml from gitlab ref: " + refspec)
        f = self.gl_project.files.get(file_path="mapper.yaml", ref=refspec)
        return f.decode()

    @property
    def merge_request_id(self):
        mr_id = None
        if self.request_type == "note":
            mr_id = self.data["merge_request"]["iid"]
        elif self.request_type == "merge_request":
            mr_id = self.data["object_attributes"]["iid"]
        return mr_id

    @property
    def merge_request_url(self):
        mr_id = None
        if self.request_type == "note":
            mr_id = self.data["merge_request"]["url"]
        elif self.request_type == "merge_request":
            mr_id = self.data["object_attributes"]["url"]
        return mr_id

    @property
    def repository(self):
        return self.data["repository"]["name"]

    @property
    def pipeline(self):
        com = self.gl_project.commits.get(self.commit)
        if com.last_pipeline is None:
            return None
        return self.gl_project.pipelines.get(com.last_pipeline["id"])

    @property
    def changed_features(self):
        features = []

        # do it via wget and raw mode - as API is silly complicated in getting MR's diff
        mr_url = self.merge_request_url
        print(">> Reading patch from gitlab merge request: " + mr_url)
        ret = subprocess.run(
            f"curl -s {mr_url}.diff".split(" "),
            check=False,
            stdout=subprocess.PIPE,
            encoding="utf-8",
        )

        if ret.returncode != 0 or not ret.stdout:
            print(f"Failed downloading diff\n{ret.stdout}\n{ret.stderr}")
            return None

        for line in ret.stdout.split("\n"):
            m = re.match(r"^\+\+\+.*/(\S+)\.feature", line)
            if m is not None:
                f = m.group(1)
                print(f"Found feature: {f}")
                if f not in features:
                    features.append(f)

        return features

    def latest_MR_commit(self, repository, mr_id):
        project = self.gl_api.projects.get(f"NetworkManager/{repository}")
        try:
            merge_request = project.mergerequests.get(mr_id)
            if merge_request.state == "opened":
                return merge_request.sha
        except:
            return None
        return None

    def is_NMCI_branch(self, branch_name):
        import requests

        url_base = (
            "https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci/-/raw"
        )
        file = "mapper.yaml"
        url = f"{url_base}/{branch_name}/{file}"

        r = requests.get(url)
        return r.status_code == 200

    def set_pipeline(self, status, release=""):
        try:
            description = ""
            if status == "pending":
                description = "The build has started"
            if status == "running":
                description = "The build is running"
            elif status == "canceled":
                description == "The build has been canceled"
            elif status == "success":
                description == "The build has finshed successfully"
            elif status == "failed":
                description == "The build has finshed unstable or failing"

            com = self.gl_project.commits.get(self.commit)

            build_id = re.match(r"^.*/([^/]+)/$", os.environ["BUILD_URL"])[1]
            pipeline_name = f"c{release}s: NM {build_id}"

            exc = None
            for _ in range(3):
                try:
                    com.statuses.create(
                        {
                            "state": status,
                            "target_url": os.environ["BUILD_URL"],
                            "name": pipeline_name,
                            "description": description,
                        }
                    )
                    return
                except Exception as e:
                    exc = e
                    time.sleep(1)
            print(f"Unable to set commit status in gitlab:\nException: {exc}")

        except Exception as e:
            print(str(e))


def get_rebuild_detail(gt, message, overrides={}):
    # lets see if there is a @OS:cXs in the desc or commit msg
    msg = []
    os_version = overrides.get("os_version", set())

    pattern = None
    match = None
    if gt.repository == "NetworkManager":
        pattern = re.compile("(NetworkManager-ci)(!|/-/merge_requests/)([0-9]+)")
    elif gt.repository == "NetworkManager-ci":
        pattern = re.compile("(NetworkManager)(!|/-/merge_requests/)([0-9]+)")
    if pattern is not None:
        match = re.search(pattern, message)
    if match is not None:
        commit = gt.latest_MR_commit(match.group(1), match.group(3))
        if commit is not None:
            overrides["build"] = commit
            if gt.repository == "NetworkManager":
                overrides["mr_id"] = match.group(3)

    for line in message.split("\n"):
        if line.strip().lower().startswith("@os:"):
            os_alias = line.strip().split(":")[-1]
            if os_alias in ["c8s", "centos8-stream"]:
                os_version.add("8-stream")
            elif os_alias in ["c9s", "centos9-stream"]:
                os_version.add("9-stream")
            else:
                os_version.add("unknown")
        elif line.strip().lower().startswith("@runfeatures:"):
            overrides["features"] = line.strip().split(":", 1)[-1]
        elif line.strip().lower().startswith("@runtests:"):
            overrides["features"] = "tests:" + line.strip().split(":", 1)[-1]
        elif line.strip().lower().startswith("@build:"):
            overrides["build"] = line.strip().split(":")[-1]
        elif line:
            msg.append(line)
    if os_version:
        overrides["os_version"] = os_version
    return overrides, "\n".join(msg)


# 'os_version' param for 'rebuild RHEL8.9' etc., good for nm less for desktop as it is mainly determined by branching
# build is TEST_BRANCH for NM, REFSPEC for NM-ci
def execute_build(
    gt, content, os_version=default_os, features="best", build="main", mr_id=None
):
    params = []
    if gt.repository == "NetworkManager":
        # NM CODE will use main unless we know branch mr/abcd exists
        if mr_id is not None:
            params.append({"name": "MERGE_REQUEST_ID", "value": mr_id})
        params.append({"name": "TEST_BRANCH", "value": build})
        params.append({"name": "REFSPEC", "value": gt.commit})
        project_dir = "NetworkManager-code-mr"

    if gt.repository == "NetworkManager-ci":  # NMCI always use main for code
        params.append({"name": "MERGE_REQUEST_ID", "value": gt.merge_request_id})
        params.append({"name": "TEST_BRANCH", "value": gt.commit})
        params.append({"name": "REFSPEC", "value": build})
        project_dir = "NetworkManager-test-mr"

    params.append({"name": "FEATURES", "value": features})
    params.append({"name": "RESERVE", "value": "0s"})
    params.append({"name": "TRIGGER_DATA", "value": content})
    # params.append({'name': 'GL_TOKEN', 'value': os.environ['GL_TOKEN']})

    token = os.environ["JK_TOKEN"]
    job_url = f"{jenkins_url}/job/{project_dir}"

    if not os_version:
        os_version = default_os

    for v in os_version:
        if v == "unknown":
            print("skipping non-centos version")
            continue
        os_version_params = []
        os_version_params.append({"name": "RELEASE", "value": v})
        os_version_params.append(
            {
                "name": "VERSION",
                "value": f"MR#{gt.merge_request_id} {gt.commit_author}: {gt.source_branch} ({v})",
            }
        )

        json_part = json.dumps({"parameter": params + os_version_params})
        url_part = "--data-urlencode json='%s'" % str(json_part.replace("'", ""))

        cmd = f"curl -k -s -X POST {job_url}/build --data 'token={token}' {url_part}"
        os.system(cmd)
        print(f"Executing {job_url}...")
    os.system(f"echo {gt.commit} >> /tmp/gl_commits")


def process_request(data, content):
    gt = GitlabTrigger(data)
    if gt.commit is None:
        print("Skipping empty MR")
        return
    if gt.request_type == "note":
        params, _ = get_rebuild_detail(gt, gt.description + "\n" + gt.commit_message)
        comment = gt.comment
        params, comment = get_rebuild_detail(gt, comment, params)
        if comment.lower().startswith("rebuild"):
            comment = comment.lower().replace("rebuild", "", 1).strip()
            if comment == "":
                execute_build(gt, content, **params)
            elif comment in ["centos9-stream", "c9s"]:
                params["os_version"] = ["9-stream"]
                execute_build(gt, content, **params)
            elif comment in ["centos8-stream", "c8s"]:
                params["os_version"] = ["8-stream"]
                execute_build(gt, content, **params)
        else:
            print("Irrelevant Note...")
    elif data["object_kind"] == "merge_request":
        if data["object_attributes"]["action"] == "merge":
            print("MERGE packet, ignoring")
        elif data["object_attributes"]["action"] == "close":
            print("CLOSE packet, ignoring")
        elif data["object_attributes"]["action"] == "unapproved":
            print("UNAPPROVED packet, ignoring")
        elif data["object_attributes"]["action"] in ["update", "approved"]:
            if gt.repository != "NetworkManager" and (
                gt.wip or gt.title.startswith("WIP")
            ):
                print("This is WIP Merge Request - not proceeding")
            elif (
                gt.request_type == "merge_request"
                and gt.pipeline is not None
                and gt.pipeline.status == "skipped"
            ):
                print("Skipped pipeline detected")
            else:
                if not os.path.exists("/tmp/gl_commits"):
                    os.system("echo '' > /tmp/gl_commits")
                with open("/tmp/gl_commits") as f:
                    commits = f.read().splitlines()
                    if gt.commit not in commits:
                        params, _ = get_rebuild_detail(
                            gt, gt.description + "\n" + gt.commit_message
                        )
                        execute_build(gt, content, **params)
                    else:
                        print(
                            "Commit %s have already executed, use rebuild if needed"
                            % gt.commit
                        )

        else:
            if gt.wip or gt.title.startswith("WIP"):
                print("This is WIP Merge Request - not proceeding")
            else:
                params, _ = get_rebuild_detail(
                    gt, gt.description + "\n" + gt.commit_message
                )
                execute_build(gt, content, **params)
    else:
        print("Invalid object kind: %s" % data["object_kind"])


def run():
    if len(sys.argv) < 2:
        print("Invalid input")
        sys.exit(1)
    json_file = sys.argv[1]
    with open(json_file) as f:
        content = f.read()
    content = """%s""" % content
    print("\n\n\n\n\n-------------")
    print(
        datetime.datetime.fromtimestamp(int(time.time())).strftime("%Y-%m-%d %H:%M:%S")
    )

    data = json.loads(content)
    # pprint(data)
    process_request(data, content)
    print("----end-------")

    # pprint(content)


if __name__ == "__main__":
    run()
