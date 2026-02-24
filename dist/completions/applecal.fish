function __applecal_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]

    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __applecal_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __applecal_should_offer_completions_for_positional -a expected_commands expected_positional_index positional_index_comparison
    if test -z $positional_index_comparison
        set positional_index_comparison -eq
    end

    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __applecal_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __applecal_parse_tokens -S
    set -l unparsed_tokens (__applecal_tokens -pc)
    set -l present_flags_and_options

    switch $unparsed_tokens[1]
    case 'applecal'
        __applecal_parse_subcommand 0 'h/help'
        switch $unparsed_tokens[1]
        case 'doctor'
            __applecal_parse_subcommand 0 'format=' 'pretty=' 'h/help'
        case 'auth'
            __applecal_parse_subcommand 0 'h/help'
            switch $unparsed_tokens[1]
            case 'status'
                __applecal_parse_subcommand 0 'format=' 'pretty=' 'h/help'
            case 'grant'
                __applecal_parse_subcommand 0 'format=' 'pretty=' 'h/help'
            case 'reset'
                __applecal_parse_subcommand 0 'format=' 'pretty=' 'h/help'
            end
        case 'calendars'
            __applecal_parse_subcommand 0 'h/help'
            switch $unparsed_tokens[1]
            case 'list'
                __applecal_parse_subcommand 0 'format=' 'pretty=' 'h/help'
            case 'get'
                __applecal_parse_subcommand 0 'id=' 'name=' 'format=' 'pretty=' 'h/help'
            end
        case 'events'
            __applecal_parse_subcommand 0 'h/help'
            switch $unparsed_tokens[1]
            case 'list'
                __applecal_parse_subcommand 0 'from=' 'to=' 'calendar=+' 'format=' 'pretty=' 'h/help'
            case 'get'
                __applecal_parse_subcommand 0 'id=' 'external-id=' 'format=' 'pretty=' 'h/help'
            case 'search'
                __applecal_parse_subcommand 0 'query=' 'from=' 'to=' 'calendar=+' 'format=' 'pretty=' 'h/help'
            case 'create'
                __applecal_parse_subcommand 0 'calendar=' 'title=' 'start=' 'end=' 'timezone=' 'all-day' 'location=' 'notes=' 'url=' 'repeat=' 'interval=' 'byday=' 'until=' 'count=' 'rrule=' 'alarm-minutes=+' 'format=' 'pretty=' 'h/help'
            case 'update'
                __applecal_parse_subcommand 0 'id=' 'title=' 'start=' 'end=' 'timezone=' 'location=' 'notes=' 'url=' 'all-day=' 'occurrence-start=' 'scope=' 'expected-revision=' 'repeat=' 'interval=' 'byday=' 'until=' 'count=' 'rrule=' 'clear-recurrence' 'alarm-minutes=+' 'format=' 'pretty=' 'h/help'
            case 'delete'
                __applecal_parse_subcommand 0 'id=' 'occurrence-start=' 'scope=' 'expected-revision=' 'format=' 'pretty=' 'h/help'
            end
        case 'completion'
            __applecal_parse_subcommand 0 'h/help'
            switch $unparsed_tokens[1]
            case 'bash'
                __applecal_parse_subcommand 0 'h/help'
            case 'zsh'
                __applecal_parse_subcommand 0 'h/help'
            case 'fish'
                __applecal_parse_subcommand 0 'h/help'
            end
        case 'schema'
            __applecal_parse_subcommand 0 'h/help'
        case 'help'
            __applecal_parse_subcommand -r 1 
        end
    end
end

function __applecal_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __applecal_parse_subcommand -S -a positional_count
    argparse -s r -- $argv
    set -l option_specs $argv[2..]

    set -a commands $unparsed_tokens[1]
    set -e unparsed_tokens[1]

    set positional_index 0

    while true
        argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
        set unparsed_tokens $argv
        set positional_index (math $positional_index + 1)

        for non_repeating_flag_or_option in $non_repeating_flags_or_options
            if set -ql _flag_$non_repeating_flag_or_option
                set non_repeating_flags_or_options_absent 1
                break
            end
        end

        if test (count $unparsed_tokens) -eq 0 -o \( -z "$_flag_r" -a "$positional_index" -gt "$positional_count" \)
            break
        end
        set -e unparsed_tokens[1]
    end
end

function __applecal_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf '%s\n' $subdirs
end

function __applecal_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION

    set -l tokens (__applecal_tokens -p)
    if test -z (__applecal_tokens -t)
        set -l index (count (__applecal_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'applecal' -f
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'doctor' -d 'Run environment and permission diagnostics.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'auth' -d 'Inspect and manage Calendar authorization.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'calendars' -d 'Inspect available calendars.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'events' -d 'Read and mutate calendar events.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'completion' -d 'Generate shell completion scripts.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'schema' -d 'Print CLI schema and command contract metadata.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal" 1' -fa 'help' -d 'Show subcommand help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal doctor" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal doctor" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal doctor" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal auth" 1' -fa 'status' -d 'Show current Calendar authorization status.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal auth" 1' -fa 'grant' -d 'Request Calendar access permission.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal auth" 1' -fa 'reset' -d 'Print safe remediation steps when TCC state is broken.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth status" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth status" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth status" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth grant" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth grant" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth grant" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth reset" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth reset" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal auth reset" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal calendars" 1' -fa 'list' -d 'List calendars available to the current user.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal calendars" 1' -fa 'get' -d 'Get one calendar by id or exact name.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars list" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars list" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars list" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars get" id' -l 'id' -d 'Calendar identifier.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars get" name' -l 'name' -d 'Calendar exact title.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars get" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars get" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal calendars get" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'list' -d 'List events in a date range.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'get' -d 'Get one event by identifier.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'search' -d 'Search events by text and optional filters.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'create' -d 'Create a new event.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'update' -d 'Update an existing event.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal events" 1' -fa 'delete' -d 'Delete an event or recurring occurrence scope.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list" from' -l 'from' -d 'Range start in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list" to' -l 'to' -d 'Range end in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list"' -l 'calendar' -d 'Calendar ids or names.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events list" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events get" id' -l 'id' -d 'Local event identifier.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events get" external-id' -l 'external-id' -d 'External event identifier fallback.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events get" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events get" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events get" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" query' -l 'query' -d 'Text query for title/location/notes.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" from' -l 'from' -d 'Range start in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" to' -l 'to' -d 'Range end in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search"' -l 'calendar' -d 'Calendar ids or names.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events search" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" calendar' -l 'calendar' -d 'Calendar id or exact name.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" title' -l 'title' -d 'Event title.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" start' -l 'start' -d 'Start date-time in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" end' -l 'end' -d 'End date-time in ISO-8601 or YYYY-MM-DD.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" timezone' -l 'timezone' -d 'Timezone identifier (e.g. Europe/Berlin).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" all-day' -l 'all-day' -d 'Create as all-day event.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" location' -l 'location' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" notes' -l 'notes' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" url' -l 'url' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" repeat' -l 'repeat' -d 'Recurrence frequency: daily|weekly|monthly|yearly.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" interval' -l 'interval' -d 'Recurrence interval.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" byday' -l 'byday' -d 'Comma-separated weekdays (mon,tue,...).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" until' -l 'until' -d 'Recurrence until (ISO date/time).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" count' -l 'count' -d 'Recurrence count.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" rrule' -l 'rrule' -d 'Advanced RRULE string.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create"' -l 'alarm-minutes' -d 'Alarm offsets in minutes relative to start, usually negative.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events create" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" id' -l 'id' -d 'Event identifier.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" title' -l 'title' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" start' -l 'start' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" end' -l 'end' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" timezone' -l 'timezone' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" location' -l 'location' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" notes' -l 'notes' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" url' -l 'url' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" all-day' -l 'all-day' -d 'Set true/false to toggle all-day mode.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" occurrence-start' -l 'occurrence-start' -d 'Occurrence start for recurring instance edits.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" scope' -l 'scope' -d 'Update scope: this, future, all.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" expected-revision' -l 'expected-revision' -d 'Expected current revision for optimistic concurrency.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" repeat' -l 'repeat' -d 'Recurrence frequency: daily|weekly|monthly|yearly.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" interval' -l 'interval' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" byday' -l 'byday' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" until' -l 'until' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" count' -l 'count' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" rrule' -l 'rrule' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" clear-recurrence' -l 'clear-recurrence'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update"' -l 'alarm-minutes' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events update" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" id' -l 'id' -d 'Event identifier.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" occurrence-start' -l 'occurrence-start' -d 'Occurrence start when scope is this/future.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" scope' -l 'scope' -d 'Delete scope: this, future, all.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" expected-revision' -l 'expected-revision' -d 'Expected current revision for optimistic concurrency.' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" format' -l 'format' -d 'Output format: json or table. Defaults to json for non-TTY, table for TTY.' -rfka 'json table'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" pretty' -l 'pretty' -d 'Pretty-print JSON output (true/false).' -rfka ''
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal events delete" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal completion" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal completion" 1' -fa 'bash' -d 'Generate completion script for Bash.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal completion" 1' -fa 'zsh' -d 'Generate completion script for Zsh.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_positional "applecal completion" 1' -fa 'fish' -d 'Generate completion script for Fish.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal completion bash" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal completion zsh" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal completion fish" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'applecal' -n '__applecal_should_offer_completions_for_flags_or_options "applecal schema" h help' -s 'h' -l 'help' -d 'Show help information.'
