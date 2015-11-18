_ddev()
{
    local cur prev cmds

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    cmds="-h --help -q --quiet --version --color --no-color analyze copy-license coverage docs examples format init test"

    COMPREPLY=($(compgen -W "${cmds}" -- ${cur}))  
    return 0
}
complete -F _ddev ddev

