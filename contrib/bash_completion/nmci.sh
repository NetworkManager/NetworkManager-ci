_test_list()
{
    local cur path file tests
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    path="${PWD}/features/"

    tests=""
    for f_file in "$path"*.feature "$path"scenarios/*.feature
    do
    if [ -f "$f_file" ]; then
        tests="$tests $(awk '/^\s*@[^@]+/ { last_tag=$0 } ; /^[^#]*Scenario:/ {print last_tag}' $f_file | sed 's/@//g')"
    fi
    done

    COMPREPLY=( $(compgen -W "${tests}" -- ${cur}) )
}

complete -F _test_list run/runtest.sh
complete -F _test_list run/./runtest.sh
complete -F _test_list ./runtest.sh
complete -F _test_list ./test_run.sh

_run_in_container_feature_names()
{
    { grep -ohP '(?<=feature: )\S+' mapper.yaml 2>/dev/null; echo gate; echo all; } | sort -u
}

_run_in_container_test_names()
{
    local path="${PWD}/features/"
    local tests=""
    for f_file in "$path"*.feature "$path"scenarios/*.feature
    do
    if [ -f "$f_file" ]; then
        tests="$tests $(awk '/^\s*@[^@]+/ { last_tag=$0 } ; /^[^#]*Scenario:/ {print last_tag}' $f_file | sed 's/@//g')"
    fi
    done
    echo "$tests"
}

_run_in_container_complete()
{
    local cur i w mode
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # -t/--tags and -F/--feature both take one or more values, so the
    # relevant flag isn't necessarily the immediately preceding word --
    # scan back until we hit it or another flag.
    mode=""
    for ((i = COMP_CWORD - 1; i > 0; i--)); do
        w="${COMP_WORDS[i]}"
        case "$w" in
            -F|--feature) mode="feature"; break ;;
            -t|--tags) mode="tags"; break ;;
            -d|--distro) mode="distro"; break ;;
            -n|--nm-version) mode="nmversion"; break ;;
            -*) break ;;
        esac
    done

    case "$mode" in
        feature)
            COMPREPLY=( $(compgen -W "$(_run_in_container_feature_names)" -- "$cur") )
            ;;
        tags)
            COMPREPLY=( $(compgen -W "$(_run_in_container_test_names)" -- "$cur") )
            ;;
        distro)
            COMPREPLY=( $(compgen -W "c10s c9s" -- "$cur") )
            ;;
        nmversion)
            COMPREPLY=( $(compgen -W "main skip" -- "$cur") )
            ;;
        *)
            COMPREPLY=( $(compgen -W "-d --distro -n --nm-version -b --nmci-branch -t --tags -F --feature -f --force -s --save-image -P --push --shell -r --refresh -c --clean -h --help" -- "$cur") )
            ;;
    esac
}

complete -F _run_in_container_complete container/run_in_container.sh
complete -F _run_in_container_complete run_in_container.sh
complete -F _run_in_container_complete ./run_in_container.sh
