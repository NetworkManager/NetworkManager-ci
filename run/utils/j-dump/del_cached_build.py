
#! /usr/bin/python3
import argparse
import sys, os
import traceback
from subprocess import call
import jsonpickle

class Build:
    id = 0

class Failure:
    name = ""

def load_cache(cache_file):
    if not os.path.isfile(cache_file):
        return (None, None)
    with open(cache_file, "r") as fd:
        data_json = fd.read()
    data = jsonpickle.decode(data_json, keys=True)
    return data

def save_cache(cache_file, builds, failures):
    data = (builds, failures)
    data_json = jsonpickle.encode(data, keys=True)
    with open(cache_file, "w") as fd:
        fd.write(data_json)

def remove_build(builds, failures, build_id):
    builds = [ build for build in builds if build.id != build_id]

    for failure in failures.values():
        failure.builds = [ build for build in failure.builds if build.id != build_id]
        if build_id in failure.artifact_urls.keys():
            failure.artifact_urls.pop(build_id)

    for failure_name in list(failures.keys()):
        if len(failures[failure_name].builds) == 0:
            failures.pop(failure_name)

    return (builds, failures)

def main():
    parser = argparse.ArgumentParser(description='Remove specific Build from cache')
    parser.add_argument('file', help="Cache file")
    parser.add_argument('id', help="Jenkins Build ID to remove")
    args = parser.parse_args()

    file = args.file
    id = int(args.id)


    builds, failures = load_cache(file)

    print("deleting Build #%d from %s" % (id, file))

    builds, failures = remove_build(builds, failures, id)

    save_cache(file, builds, failures)

if __name__ == '__main__':
    main()
