#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import yaml

def index(x, i, default=""):
    if len(x) > i: return x[i]

# eks/project1/prod/gitops-prow/.trash/aws/kube-system/app-shared-default/iam-policy.json
# eks/project1/prod/gitops-prow/aws/kube-system/app-shared-default/iam-policy.json
# eks/project1/prod/gitops-prow/iam-sa/kube-system/app-shared-default/iam-policy.json
# images/prow-ci/Dockerfile

def is_wafv2(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 4)
    return ctrl == "wafv2"

def is_ecs(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 4)
    return ctrl == "ecs"

def is_asg(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 4)
    return ctrl == "asg"

def is_elbv2(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 4)
    return ctrl == "alb"

def is_iam(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 4)
    return ctrl == "iam"

def is_ghe(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    ctrl = index(segments, 1)
    return ctrl == "ghe"

def identity(one):
    return one

def wafv2_post_process(parsed):
    filename = parsed["filename"]
    parsed["name"] = ".".join(filename.split(".")[:-1])
    return parsed

def get_ctrl(content):
    return content.get("apiVersion", "").split("/")[0].replace(".aws.sa", "")

def set_ctrl_kind(parsed):
    if parsed.get("ctrl") in ["wafv2", "ecs", "elbv2", "iam"]:
        try:
            with open(parsed["fullname"]) as f:
                content = yaml.safe_load(f)
                parsed["kind"] = content.get("kind")
                ctrl = get_ctrl(content)
                if ctrl:
                    parsed["ctrl"] = ctrl
        except IOError:
            pass
    return parsed

def set_kind_filename(parsed):
    if parsed.get("ctrl") in ["ghe"]:
        parsed["kind"] = parsed["filename"].split(".")[0].capitalize()
    return parsed

formats = {
    "eks": [(lambda _: True, ("vendor", "project", "env", "cluster", "ctrl", "namespace", "name", "filename", "fullname"), identity)],
    "aws": [
        (is_wafv2, ("vendor", "project", "env", "region", "ctrl", "wafv2_type", "name", "filename", "fullname"), wafv2_post_process),
        (is_ecs, ("vendor", "project", "env", "region", "ctrl", "ecs_cluster", "name", "filename", "fullname"), set_ctrl_kind),
        (is_asg, ("vendor", "project", "env", "region", "ctrl", "name", "filename", "fullname"), set_ctrl_kind),
        (is_elbv2, ("vendor", "project", "env", "region", "ctrl", "name", "filename", "fullname"), set_ctrl_kind),
        (is_iam, ("vendor", "project", "env", "region", "ctrl", "name", "filename", "fullname"), set_ctrl_kind),
        (lambda _: True, ("vendor", "project", "env", "region", "ctrl", "name", "filename", "fullname"), identity),
        ],
    "images": [(lambda _: True, ("vendor", "project", "filename", "fullname"), identity)],
    "helm": [(lambda _: True, ("vendor", "chart", "ctrl", "namespace", "app", "policy_file", "policy"), identity)],
    "shared": [(lambda _: True, ("vendor", "env", "region", "ctrl", "wafv2_type", "name", "filename", "fullname"), identity)],
    "app": [
        (is_ghe, ("vendor", "ctrl", "organization", "name", "filename", "fullname"), set_kind_filename),
        ],
}

projects = {
    "singapore": "sg",
    "hongkong": "hk",
}
def add_profile(formated):
    profile = None
    project = formated.get("project")
    env = formated.get("env")
    ctrl = formated.get("ctrl")
    if project in projects:
        project = projects[project]
    if project and env and ctrl:
        profile = "{}-{}-{}".format(project, env, ctrl)
    if profile:
        formated["profile"] = profile
    return formated

def match_format(vendor, fullname):
    if vendor not in formats:
        return None, None
    for match, keys, post_process in formats.get(vendor):
        if match(fullname):
            return keys, post_process

def parse(fullname):
    segments = fullname.strip().replace("/.trash/","/").split(os.sep)
    filename = segments[-1]
    segments=segments[:-1]
    vendor = index(segments, 0)
    keys, post_process = match_format(vendor, fullname)
    if not keys:
        keys = ["filename", "fullname"]
        post_process = identity
        # return None
    length = len(keys)-2
    ordered = tuple(index(segments, i) for i in range(length)) + (filename, fullname.strip(),)
    parsed = post_process(dict(zip(keys, ordered)))
    return add_profile(parsed)

def deduplicate(list_of_dict):
    s = set([tuple(sorted(d.items())) for d in list_of_dict])
    return [dict(pair) for pair in s]

def main():
    changed = set()
    files = list(filter(identity, [parse(line) for line in sys.stdin]))
    res = json.dumps(files)
    print(res)

if __name__ == "__main__":
    main()
