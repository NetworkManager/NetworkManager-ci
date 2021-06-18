_test_list()
{
    local cur cmd path file tests
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    cmd="${COMP_WORDS[0]}"

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
