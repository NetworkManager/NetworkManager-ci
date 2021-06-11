if __name__ == "__main__":
    import sys

    def usage():
        print(
            """
USAGE: python -m nmci {command} [command arguments]

COMMANDS:
help
    - print this message
    - aliases: -h, --help

get_test_tags [feature [test_name]]
    - print all test tags for given test
    - feature: nmcli (default), nmtui, or feature file name (e.g. adsl, alias, bond...)

mapper_feature [feature_name [format]]
    - print all tests in feature as defined in mapper.yaml (all or * for all features)
    - possible formats: name (default, output just test name), json, bash (executable format)
"""
        )

    if len(sys.argv) == 1 or sys.argv[1] in ["help", "-h", "--help"]:
        usage()

    elif sys.argv[1] == "get_test_tags":
        import nmci.misc

        if len(sys.argv) > 2:
            feature = f"/features/scenarios/{sys.argv[2]}.feature"
        else:
            print("expected feature name")
            sys.exit(1)

        test_name = None
        if len(sys.argv) > 3:
            test_name = sys.argv[3]
        print("\n".join(nmci.misc.test_load_tags_from_features(feature, test_name)))

    elif sys.argv[1] == "mapper_feature":
        feature = "*"
        if len(sys.argv) > 2:
            feature = sys.argv[2]
        format = "name"
        if len(sys.argv) > 3:
            format = sys.argv[3]
        if format not in ["name", "json", "bash"]:
            print(f"Unknown format: {format}")
            exit(1)
        import nmci.misc

        mapper = nmci.misc.get_mapper_obj()
        mapper_tests = nmci.misc.get_mapper_tests(mapper, feature)
        d_test_run = mapper["component"]["test-run"]
        d_timeout = "10m"
        if format == "json":
            import json

            print(json.dumps(mapper_tests))
        else:
            i = 0
            for test in mapper_tests:
                if format == "name":
                    print(test["testname"])
                elif format == "bash":
                    test_run = d_test_run
                    if "run" in test:
                        test_run = test["run"]
                    timeout = d_timeout
                    if "timeout" in test:
                        timeout = test["timeout"]
                    print(
                        f"testname='{test['testname']}'; "
                        f"export TEST='{test['testname']}'; "
                        f"timeout {timeout} {test_run}; "
                    )
                i += 1
    else:
        print(f"Unrecognized command: {sys.argv[1]}")
        usage()
        exit(1)
