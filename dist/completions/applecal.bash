#!/bin/bash

__applecal_cursor_index_in_current_word() {
    local remaining="${COMP_LINE}"

    local word
    for word in "${COMP_WORDS[@]::COMP_CWORD}"; do
        remaining="${remaining##*([[:space:]])"${word}"*([[:space:]])}"
    done

    local -ir index="$((COMP_POINT - ${#COMP_LINE} + ${#remaining}))"
    if [[ "${index}" -le 0 ]]; then
        printf 0
    else
        printf %s "${index}"
    fi
}

# positional arguments:
#
# - 1: the current (sub)command's count of positional arguments
#
# required variables:
#
# - repeating_flags: the repeating flags that the current (sub)command can accept
# - non_repeating_flags: the non-repeating flags that the current (sub)command can accept
# - repeating_options: the repeating options that the current (sub)command can accept
# - non_repeating_options: the non-repeating options that the current (sub)command can accept
# - positional_number: value ignored
# - unparsed_words: unparsed words from the current command line
#
# modified variables:
#
# - non_repeating_flags: remove flags for this (sub)command that are already on the command line
# - non_repeating_options: remove options for this (sub)command that are already on the command line
# - positional_number: set to the current positional number
# - unparsed_words: remove all flags, options, and option values for this (sub)command
__applecal_offer_flags_options() {
    local -ir positional_count="${1}"
    positional_number=0

    local was_flag_option_terminator_seen=false
    local is_parsing_option_value=false

    local -ar unparsed_word_indices=("${!unparsed_words[@]}")
    local -i word_index
    for word_index in "${unparsed_word_indices[@]}"; do
        if "${is_parsing_option_value}"; then
            # This word is an option value:
            # Reset marker for next word iff not currently the last word
            [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]] && is_parsing_option_value=false
            unset "unparsed_words[${word_index}]"
            # Do not process this word as a flag or an option
            continue
        fi

        local word="${unparsed_words["${word_index}"]}"
        if ! "${was_flag_option_terminator_seen}"; then
            case "${word}" in
            --)
                unset "unparsed_words[${word_index}]"
                # by itself -- is a flag/option terminator, but if it is the last word, it is the start of a completion
                if [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]]; then
                    was_flag_option_terminator_seen=true
                fi
                continue
                ;;
            -*)
                # ${word} is a flag or an option
                # If ${word} is an option, mark that the next word to be parsed is an option value
                local option
                for option in "${repeating_options[@]}" "${non_repeating_options[@]}"; do
                    [[ "${word}" = "${option}" ]] && is_parsing_option_value=true && break
                done

                # Remove ${word} from ${non_repeating_flags} or ${non_repeating_options} so it isn't offered again
                local not_found=true
                local -i index
                for index in "${!non_repeating_flags[@]}"; do
                    if [[ "${non_repeating_flags[${index}]}" = "${word}" ]]; then
                        unset "non_repeating_flags[${index}]"
                        non_repeating_flags=("${non_repeating_flags[@]}")
                        not_found=false
                        break
                    fi
                done
                if "${not_found}"; then
                    for index in "${!non_repeating_flags[@]}"; do
                        if [[ "${non_repeating_flags[${index}]}" = "${word}" ]]; then
                            unset "non_repeating_flags[${index}]"
                            non_repeating_flags=("${non_repeating_flags[@]}")
                            break
                        fi
                    done
                fi
                unset "unparsed_words[${word_index}]"
                continue
                ;;
            esac
        fi

        # ${word} is neither a flag, nor an option, nor an option value
        if [[ "${positional_number}" -lt "${positional_count}" || "${positional_count}" -lt 0 ]]; then
            # ${word} is a positional
            ((positional_number++))
            unset "unparsed_words[${word_index}]"
        else
            if [[ -z "${word}" ]]; then
                # Could be completing a flag, option, or subcommand
                positional_number=-1
            else
                # ${word} is a subcommand or invalid, so stop processing this (sub)command
                positional_number=-2
            fi
            break
        fi
    done

    unparsed_words=("${unparsed_words[@]}")

    if\
        ! "${was_flag_option_terminator_seen}"\
        && ! "${is_parsing_option_value}"\
        && [[ ("${cur}" = -* && "${positional_number}" -ge 0) || "${positional_number}" -eq -1 ]]
    then
        COMPREPLY+=($(compgen -W "${repeating_flags[*]} ${non_repeating_flags[*]} ${repeating_options[*]} ${non_repeating_options[*]}" -- "${cur}"))
    fi
}

__applecal_add_completions() {
    local completion
    while IFS='' read -r completion; do
        COMPREPLY+=("${completion}")
    done < <(IFS=$'\n' compgen "${@}" -- "${cur}")
}

__applecal_custom_complete() {
    if [[ -n "${cur}" || -z ${COMP_WORDS[${COMP_CWORD}]} || "${COMP_LINE:${COMP_POINT}:1}" != ' ' ]]; then
        local -ar words=("${COMP_WORDS[@]}")
    else
        local -ar words=("${COMP_WORDS[@]::${COMP_CWORD}}" '' "${COMP_WORDS[@]:${COMP_CWORD}}")
    fi

    "${COMP_WORDS[0]}" "${@}" "${words[@]}"
}

_applecal() {
    trap "$(shopt -p);$(shopt -po)" RETURN
    shopt -s extglob
    set +o history +o posix

    local -xr SAP_SHELL=bash
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(IFS='.';printf %s "${BASH_VERSINFO[*]}")"
    local -r SAP_SHELL_VERSION

    local -r cur="${2}"
    local -r prev="${3}"

    local -i positional_number
    local -a unparsed_words=("${COMP_WORDS[@]:1:${COMP_CWORD}}")

    local -a repeating_flags=()
    local -a non_repeating_flags=(-h --help)
    local -a repeating_options=()
    local -a non_repeating_options=()
    __applecal_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    doctor|auth|calendars|events|completion|schema|help)
        # Offer subcommand argument completions
        "_applecal_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'doctor auth calendars events completion schema help' -- "${cur}"))
        ;;
    esac
}

_applecal_doctor() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_auth() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    status|grant|reset)
        # Offer subcommand argument completions
        "_applecal_auth_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'status grant reset' -- "${cur}"))
        ;;
    esac
}

_applecal_auth_status() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_auth_grant() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_auth_reset() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_calendars() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    list|get)
        # Offer subcommand argument completions
        "_applecal_calendars_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'list get' -- "${cur}"))
        ;;
    esac
}

_applecal_calendars_list() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_calendars_get() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--id --name --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--id')
        return
        ;;
    '--name')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    list|get|search|create|update|delete)
        # Offer subcommand argument completions
        "_applecal_events_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'list get search create update delete' -- "${cur}"))
        ;;
    esac
}

_applecal_events_list() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=(--calendar)
    non_repeating_options=(--from --to --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--from')
        return
        ;;
    '--to')
        return
        ;;
    '--calendar')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events_get() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--id --external-id --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--id')
        return
        ;;
    '--external-id')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events_search() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=(--calendar)
    non_repeating_options=(--query --from --to --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--query')
        return
        ;;
    '--from')
        return
        ;;
    '--to')
        return
        ;;
    '--calendar')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events_create() {
    repeating_flags=()
    non_repeating_flags=(--all-day -h --help)
    repeating_options=(--alarm-minutes)
    non_repeating_options=(--calendar --title --start --end --timezone --location --notes --url --repeat --interval --byday --until --count --rrule --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--calendar')
        return
        ;;
    '--title')
        return
        ;;
    '--start')
        return
        ;;
    '--end')
        return
        ;;
    '--timezone')
        return
        ;;
    '--location')
        return
        ;;
    '--notes')
        return
        ;;
    '--url')
        return
        ;;
    '--repeat')
        return
        ;;
    '--interval')
        return
        ;;
    '--byday')
        return
        ;;
    '--until')
        return
        ;;
    '--count')
        return
        ;;
    '--rrule')
        return
        ;;
    '--alarm-minutes')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events_update() {
    repeating_flags=()
    non_repeating_flags=(--clear-recurrence -h --help)
    repeating_options=(--alarm-minutes)
    non_repeating_options=(--id --title --start --end --timezone --location --notes --url --all-day --occurrence-start --scope --expected-revision --repeat --interval --byday --until --count --rrule --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--id')
        return
        ;;
    '--title')
        return
        ;;
    '--start')
        return
        ;;
    '--end')
        return
        ;;
    '--timezone')
        return
        ;;
    '--location')
        return
        ;;
    '--notes')
        return
        ;;
    '--url')
        return
        ;;
    '--all-day')
        return
        ;;
    '--occurrence-start')
        return
        ;;
    '--scope')
        return
        ;;
    '--expected-revision')
        return
        ;;
    '--repeat')
        return
        ;;
    '--interval')
        return
        ;;
    '--byday')
        return
        ;;
    '--until')
        return
        ;;
    '--count')
        return
        ;;
    '--rrule')
        return
        ;;
    '--alarm-minutes')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_events_delete() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=(--id --occurrence-start --scope --expected-revision --format --pretty)
    __applecal_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--id')
        return
        ;;
    '--occurrence-start')
        return
        ;;
    '--scope')
        return
        ;;
    '--expected-revision')
        return
        ;;
    '--format')
        __applecal_add_completions -W 'json'$'\n''table'
        return
        ;;
    '--pretty')
        return
        ;;
    esac
}

_applecal_completion() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    bash|zsh|fish)
        # Offer subcommand argument completions
        "_applecal_completion_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'bash zsh fish' -- "${cur}"))
        ;;
    esac
}

_applecal_completion_bash() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0
}

_applecal_completion_zsh() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0
}

_applecal_completion_fish() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0
}

_applecal_schema() {
    repeating_flags=()
    non_repeating_flags=(-h --help)
    repeating_options=()
    non_repeating_options=()
    __applecal_offer_flags_options 0
}

_applecal_help() {
    :
}

complete -o filenames -F _applecal applecal
