#
# Installation:
#
# Via shell config file  ~/.bashrc  (or ~/.zshrc)
#
#   Append the contents to config file
#   'source' the file in the config file
#
# You may also have a directory on your system that is configured
#    for completion files, such as:
#
#    /usr/local/etc/bash_completion.d/
#

###-begin-ddev-completion-###

if type complete &>/dev/null; then
  __ddev_completion() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           ddev completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F __ddev_completion ddev
elif type compdef &>/dev/null; then
  __ddev_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 ddev completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef __ddev_completion ddev
elif type compctl &>/dev/null; then
  __ddev_completion() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       ddev completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K __ddev_completion ddev
fi

###-end-ddev-completion-###

###-begin-dart_dev-completion-###

if type complete &>/dev/null; then
  __dart_dev_completion() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           dart_dev completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F __dart_dev_completion dart_dev
elif type compdef &>/dev/null; then
  __dart_dev_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 dart_dev completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef __dart_dev_completion dart_dev
elif type compctl &>/dev/null; then
  __dart_dev_completion() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       dart_dev completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K __dart_dev_completion dart_dev
fi

###-end-dart_dev-completion-###

## Generated 2016-05-04 21:49:06.300497Z
## By /Volumes/Workspace/dart_dev/.pub/bin/completion/shell_completion_generator.dart.snapshot

