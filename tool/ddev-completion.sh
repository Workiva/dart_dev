_ddev()
{
    local cur prev cmds

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmds="--help --quiet --version --color --no-color analyze copy-license coverage docs examples format link init test unlink"

    #
    # Complete subcommand options instead of top-level commands and options.
    #

    if [[ " ${COMP_WORDS[*]} " == *" analyze "* ]]; then
        cmds="--help --fatal-warnings --no-fatal-warnings --hints --no-hints"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" coverage "* ]]; then
        cmds="--help --unit --no-unit --integration --no-integration --html --no-html --open --no-open"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" docs "* ]]; then
        cmds="--help --open --no-open"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" examples "* ]]; then
        cmds="--help --hostname --port"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" format "* ]]; then
        cmds="--help --check --line-length"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" link "* ]]; then
        cmds="--help"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" test "* ]]; then
        cmds="--help --unit --no-unit --integration --no-integration --concurrency --platform"
    fi

    if [[ " ${COMP_WORDS[*]} " == *" unlink "* ]]; then
        cmds="--help"
    fi

    COMPREPLY=($(compgen -W "${cmds}" -- ${cur}))  
    return 0
}
complete -F _ddev ddev

