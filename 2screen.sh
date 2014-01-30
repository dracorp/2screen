#!/usr/bin/env bash
#===============================================================================
# NAME
#       2screen - run program in the screen
#
# SYNOPSIS
#       2screen [OPTIONS] PROGRAM
#
# DESCRIPTION
#       Run a PROGRAM in a screen session. If the session of screen is 
#       detached then program reattaches the session.
#
#       -s
#           name of session
#
# EXAMPLE
#       2screen -s 'slrn screen' slrn
#           runs the program slrn in screen mode
#
# REQUIREMENTS
#       screen, bash, getopt
#
# TODO
#       List of active sessions of screen
#
# COPYRIGHT
#       Copyright © 2014- Piotr Roogża. 
#
#       This is free software: you are free to change and redistribute it.
#       There is NO WARRANTY, to the extent permitted by law.
#==============================================================================

usage() { #{{{
    # https://github.com/l0b0/shell-includes
    local IFS=
    while read -r line || [ -n "$line" ]; do
        case "$line" in
            '#!'*) # Shebang line
                ;;
            '#='*) # comment from header
                ;;
            ''|'##'*|[!#]*) # End of comments
                exit "${1:-0}"
                ;;
            *) # Comment line
                printf '%s\n' "${line:2}" # Remove comment prefix
                ;;
        esac
    done < "$0"
} #}}}
params="$(getopt -o s: -- "$@")"
if [[ $? -ne 0 || $# -eq 0 ]]; then
    usage 1
fi
eval set -- "$params"
unset params

while true; do
    case $1 in
        -s)
            session_name="${2}"
            shift 2
            ;;
        --)
            shift
            if [ -z "${program_name=${@:$#}}" ]; then
                usage 1
            fi
            break
            ;;
        *)
            usage
            ;;
    esac
done

if ! which $program_name &>/dev/null; then
    usage
fi

# by default session_name=program_name if empty
: ${session_name=$program_name}
tmpdir='/tmp'
screen_pid_file="${tmpdir}/${program_name}-screen-${USER}.pid"
screen_dump_interval=30
hardcopy="/tmp/hardcopy-${program_name}-${USER}"

# Configuration for program_name
config_override="~/.config/${program_name}-screen"
if [ -r "$config_override" ]; then
    source "$config_override"
fi

# must be exported to be accessible in subshell
export hardcopy program_name
# screen session
if [ -r "$screen_pid_file" ]; then
    screen -x $(<"$screen_pid_file")
else
    screen -U -S "$session_name" -t "$session_name" bash -c "
    while true; do
        sleep 1
        screen -S \$PPID -X hardcopy \$hardcopy
        sleep $screen_dump_interval
    done &
    echo \$PPID > $screen_pid_file
    \$program_name
    rm -f $screen_pid_file
    rm -f \$hardcopy
    "
fi
