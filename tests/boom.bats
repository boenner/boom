#!/usr/bin/env bats
# shellcheck disable=SC2076
# shellcheck disable=SC2230

# Use the BATSSHELL environment variable to run the same tests for other shells
# Defaults to the systems shell or bash if not found
shell="${BATSSHELL:-${SHELL:-/bin/bash}}"
export SHELL="${shell}"
# Make sure the users config is never loaded when boom is called without --config
export BOOMCONF="empty.json"
export BOOMPATH="../boom"

# Exit if not executed from the tests folder
if [ "$(git rev-parse --show-toplevel 2> /dev/null)/tests" != "$(pwd)" ] || [ ! -f ""${BOOMPATH}"" ]; then
    echo "Execute bats from the tests folder" >&2
    exit 1
fi

setup() {
    bats_require_minimum_version 1.5.0
    load '../node_modules/bats-support/load'
    load '../node_modules/bats-assert/load'
    PAAATH="${PATH}"
}

teardown() {
    # Remove the mock dependencies
    rm -f "./fzf"
    rm -f "./jq"
    rm -f "./awk"
    rm -f "./sed"
    rm -f "./output"
    rm -f "./input"
    # Reset PATH
    export PATH="${PAAATH}"
}

@test "does not run with sh" {
    run sh "${BOOMPATH}" --help
    assert_failure
    assert_output --partial 'tested with bash and zsh'
}

@test "runs with current shell" {
    run ${shell} "${BOOMPATH}" --help
    assert_success
}

@test "short parameter -c with non-existing config" {
    run "${shell}" "${BOOMPATH}" -c nope.json
    assert_failure
    assert_line --partial 'nope.json'
    assert_line --partial 'does not exist'
}

@test "long parameter --config with non-existing config" {
    run "${shell}" "${BOOMPATH}" --config nope.json
    assert_failure
    assert_line --partial 'nope.json'
    assert_line --partial 'does not exist'
}

@test "long parameter with assignment --config= and non-existing config" {
    run "${shell}" "${BOOMPATH}" --config="nope.json"
    assert_failure
    assert_line --partial 'nope.json'
    assert_line --partial 'does not exist'
}

@test "--help runs without config" {
    run "${shell}" "${BOOMPATH}" --help
    assert_success
    assert_output --partial 'Usage:'
}

@test "-h runs without config" {
    run "${shell}" "${BOOMPATH}" -h
    assert_success
    assert_output --partial 'Usage:'
}

@test "invalid json in config" {
    run "${shell}" "${BOOMPATH}" --config invalid.json
    assert_failure
    assert_line --partial 'invalid.json'
    assert_line --partial 'parse error: Unfinished JSON term at EOF at line 5, column 0'
}

@test "\$BOOMCONF environment variable" {
    export BOOMCONF="nope.json"
    run "${shell}" "${BOOMPATH}"
    assert_failure
    assert_line --partial 'nope.json'
    assert_line --partial 'does not exist'
}

@test "-v without config" {
    run "${shell}" "${BOOMPATH}" --config "nope.json" -v 2>&1
    assert_failure
    assert_line --partial "-f nope.json"
}

@test "--verbose without config" {
    run "${shell}" "${BOOMPATH}" --config "nope.json" --verbose 2>&1
    assert_failure
    assert_line --partial "-f nope.json"
}

@test "parameter does not exist" {
    run "${shell}" "${BOOMPATH}" --config "config.json" nope
    assert_failure
    assert_line --partial 'nope parameter/action does not exist'
}

@test "-l" {
    run "${shell}" "${BOOMPATH}" --config "config.json" -l
    assert_success
    assert_line --index 0 --regexp '^.*foobar.*echo "foobar".*$'
	assert_line --index 1 --regexp '^.*hello.*world.*echo "\$hello \$world" \(env\).*$'
	assert_line --index 2 --regexp '^.*hello.*moon.*echo "\$hello \$moon" \(env\).*$'
	assert_line --index 3 --regexp '^.*cat.*makes.*meow.*cat \(stdin\).*$'
	assert_line --index 4 --regexp '^.*cat.*makes.*meeoow.*cat \(stdin\).*$'
	assert_line --index 5 --regexp '^.*eilsel.*tsief.*sort \$SORT_OPTION \(env\) \(stdin\).*$'
	assert_line --index 6 --regexp '^.*unix.*timestamp.*echo -n "\$\(cat -\)" && echo -n '\'' 0 is '\'' && echo \"\$D... \(env\) \(stdin\)'
    assert_line --index 7 --regexp '^.*duplicate.*entry.*echo 2.*$'
}

@test "--list" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --list
    assert_success
    assert_line --index 0 --regexp '^.*foobar.*echo "foobar".*$'
	assert_line --index 1 --regexp '^.*hello.*world.*echo "\$hello \$world" \(env\).*$'
	assert_line --index 2 --regexp '^.*hello.*moon.*echo "\$hello \$moon" \(env\).*$'
	assert_line --index 3 --regexp '^.*cat.*makes.*meow.*cat \(stdin\).*$'
	assert_line --index 4 --regexp '^.*cat.*makes.*meeoow.*cat \(stdin\).*$'
	assert_line --index 5 --regexp '^.*eilsel.*tsief.*sort \$SORT_OPTION \(env\) \(stdin\).*$'
	assert_line --index 6 --regexp '^.*unix.*timestamp.*echo -n "\$\(cat -\)" && echo -n '\'' 0 is '\'' && echo \"\$D... \(env\) \(stdin\)'
    assert_line --index 7 --regexp '^.*duplicate.*entry.*echo 2.*$'
}

@test "list with group" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --list --group group
    assert_success
    assert_line --index 0 --regexp '^.*group.*subgroup.*echo "foo".*$'
    assert_line --index 1 --regexp '^.*group.*echo "bar".*$'
}

@test "list with group and subgroup" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --list --group group --subgroup subgroup
    assert_success
    assert_line --index 0 --regexp '^.*group.*subgroup.*echo "foo".*$'
}

@test "--exec with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --exec
    assert_failure
    assert_line --partial '--exec parameter given without value'
}

@test "--group with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group
    assert_failure
    assert_line --partial '--group parameter given without value'
}

@test "--subgroup with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --subgroup
    assert_failure
    assert_line --partial '--subgroup parameter given without value'
}

@test "-x with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" -x
    assert_failure
    assert_line --partial 'x parameter given without value'
}

@test "-g with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" -g
    assert_failure
    assert_line --partial 'g parameter given without value'
}

@test "-s with missing param" {
    run "${shell}" "${BOOMPATH}" --config "config.json" -s
    assert_failure
    assert_line --partial 's parameter given without value'
}

@test "double action" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --list --exec foobar
    assert_failure
    assert_line --partial 'Only one action allowed'
}

@test "multi-character delimiter" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --delimiter "###"
    assert_failure
    assert_output --partial "The delimiter must be a single character"
}

@test "group does not exist" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group nope --exec world
    assert_failure
    assert_output --partial "command 'world' does not exist"
    assert_output --partial "missing the group/subgroup"
}

@test "subgroup does not exist" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group hello --subgroup nope --exec world
    assert_failure
    assert_output --partial "command 'world' does not exist"
    assert_output --partial "missing the group/subgroup"
}

@test "command does not exist" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group hello --exec nope
    assert_failure
    assert_output --partial "command 'nope' does not exist"
}

@test "direct command" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --exec foobar
    assert_success
    assert_output "foobar"
}

@test "first element of group" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group hello --exec world
    assert_success
    assert_output "hello world"
}

@test "second element of group" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group hello -x moon
    assert_success
    assert_output "hello moon"
}

@test "first element of subgroup" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group cat --subgroup makes --exec meow
    assert_success
    assert_output "meow"
}

@test "second element of subgroup" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group cat --subgroup makes --exec meeoow
    assert_success
    assert_output "meeoow"
}

@test "command with stdin" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group eilsel --exec tsief
    assert_success
    assert_output --stdin <<EOF
3
2
1
EOF
}

@test "subshell in env" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group unix --exec timestamp
    assert_success
    assert_output "unix timestamp 0 is Thu 01 Jan 1970"
}

@test "duplicate command" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group duplicate --exec entry
    assert_success
    assert_output "2"

}

@test "command with empty exec" {
    run "${shell}" "${BOOMPATH}" --config "empty-exec.json"
    assert_failure
    assert_line --partial "Failed to load commands from config file"
    assert_line --partial "Invalid configuration for command \"empty\""
}

@test "empty group" {
    run "${shell}" "${BOOMPATH}" --config "empty-group.json"
    assert_failure
    assert_line --partial "Failed to load commands from config file"
    assert_line --partial "Invalid element in config: empty: {}"
}

@test "spaces everywhere" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --group "space in group" --subgroup "space in subgroup" --exec "space in command"
    assert_success
    assert_output "whoa"
}

@test "duplicate command names in different levels" {
    run "${shell}" "${BOOMPATH}" --config "config.json" --exec bar
    assert_success
    assert_output "first bar"
    run "${shell}" "${BOOMPATH}" --config "config.json" --group foo --exec bar
    assert_success
    assert_output "second bar"
}

@test "fzf fails" {
    export PATH="./:$(pwd):${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
echo "random error" 1>&2
exit 2
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}" --config "config.json"
    assert_failure
    assert_line --partial "Failed to load commands into fzf"
}

@test "fzf interrupted" {
    export PATH="./:$(pwd):${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
exit 130
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}"
    assert_success
    refute_output
}

@test "fzf no match" {
    export PATH="./:$(pwd):${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
exit 1
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}"
    assert_success
    refute_output
}

@test "fzf with default delimiter" {
    export PATH="./:${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
delimiter=$'\u001F'
params=$@
stdin=$(cat)
if [[ ! "${params}" == *"--delimiter=${delimiter}"* ]]; then
    echo "Default delimiter was not given to fzf" 1>&2
    exit 1
fi
echo "${delimiter}${delimiter}foobar"
exit 0
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}" --config "config.json"
    assert_success
    assert_output "foobar"
}

@test "fzf with custom delimiter" {
    export PATH="./:${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
delimiter=$'#'
params=$@
stdin=$(cat)
echo $stdin > log
if [[ ! "${params}" == *"--delimiter=${delimiter}"* ]]; then
    echo "Custom delimiter was not given to fzf" 1>&2
    exit 1
fi
echo "${delimiter}${delimiter}foobar"
exit 0
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}" --config "config.json" --delimiter "#"
    assert_success
    assert_output "foobar"
}

@test "all details in fzf" {
    export PATH="./:${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "5000"
    exit 0
fi
delimiter=$'\u001F'
stdin=$(cat)
if ! echo "${stdin}" | grep -q "${delimiter}${delimiter}foobar ${delimiter}echo \"foobar\"${delimiter}${delimiter}" \
    || ! echo "${stdin}" | grep -q "hello ${delimiter}${delimiter}world" \
    || ! echo "${stdin}" | grep -q "hello ${delimiter}${delimiter}moon ${delimiter}echo \"\$hello \$moon\"${delimiter}{\"hello\":\"hello\",\"moon\":\"moon\"}${delimiter}" \
    || ! echo "${stdin}" | grep -q "cat ${delimiter}makes ${delimiter}meow" \
    || ! echo "${stdin}" | grep -q "cat ${delimiter}makes ${delimiter}meeoow" \
    || ! echo "${stdin}" | grep -q "eilsel ${delimiter}${delimiter}tsief" \
    || ! echo "${stdin}" | grep -q "unix ${delimiter}${delimiter}timestamp" \
    || ! echo "${stdin}" | grep -q "duplicate ${delimiter}${delimiter}entry" \
    || ! echo "${stdin}" | grep -q "space in group ${delimiter}space in subgroup ${delimiter}space in command" \
    || ! echo "${stdin}" | grep -q "${delimiter}${delimiter}bar" \
    || ! echo "${stdin}" | grep -q "foo ${delimiter}${delimiter}bar"; then
    echo "Not all commands from config.json given to fzf" 1>&2
    exit 1
fi
echo "${delimiter}${delimiter}foobar"
exit 0
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}" --config "config.json"
    assert_success
    assert_output "foobar"
}

@test "fzf version" {
    export PATH="./:${PATH}"
    cat << 'EOF' > "./fzf"
#!/bin/bash
echo "0.15.4 (fc12345)"
exit 0
EOF
    chmod +x "./fzf"
    run "${shell}" "${BOOMPATH}"
    assert_failure
    assert_output --partial "need at least fzf version 0.16.8"
}

@test "jq version" {
    export PATH="./:${PATH}"
    cat << 'EOF' > "./jq"
#!/bin/bash
if [[ "$*" =~ "--version" ]]; then
    echo "jq-1.3"
    exit 0
fi
exit 0
EOF
    chmod +x "./jq"
    run "${shell}" "${BOOMPATH}" --verbose
    assert_failure
    assert_output --partial "need at least jq version 1.5"
}

@test "spaces in env definition" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec space
    assert_success
    assert_output  "hello world"
}

@test "env starting with digit" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "env starting with digit"
    assert_failure
    assert_output --partial "Error in environment variable assignment for command"
}

@test "env containing space" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "env containing space"
    assert_failure
    assert_output --partial "Error in environment variable assignment for command"
}

@test "env is empty" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "env is empty"
    assert_failure
    assert_output --partial "Error in environment variable assignment for command"
}

@test "env containing hyphen" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "env containing hyphen"
    assert_failure
    assert_output --partial "Error in environment variable assignment for command"
}

@test "-V" {
    run "${shell}" "${BOOMPATH}" -V
    assert_success
    assert_output --regexp "[[:digit:]]\.[[:digit:]]\.[[:digit:]]"
}

@test "--version" {
    run "${shell}" "${BOOMPATH}" --version
    assert_success
    assert_output --regexp "[[:digit:]]\.[[:digit:]]\.[[:digit:]]"
}

@test "colors when output to terminal" {
    output=$(script -q -c ""${BOOMPATH}" --list --config config.json")
    status=$(grep -Pq '\033\[\d+[;m]' <<< "${output}")
    assert_success
}

@test "no colors when piped" {
    output=$(script -q -c ""${BOOMPATH}" --list --config config.json | cat")
    # Negate this so bats won't fail because the subshell fails.
    status=$(! grep -Pq '\033\[\d+[;m]' <<< "${output}")
    assert_success
}

@test "command with additional fields" {
    run "${shell}" "${BOOMPATH}" --config group-command-mix.json
    assert_failure
}

@test "piped commands" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec pipe
    assert_success
    assert_output "whoop"
}

@test "redirect out into file" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "redirect-stdout"
    assert_success
    assert_output "stdout"
}

@test "redirect in from file instead of stdin config" {
    echo "stdin" > "./input"
    run "${shell}" "${BOOMPATH}" --config config.json --exec "redirect-stdin"
    assert_success
    assert_output "stdin"
}

@test "wait for background task" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "background-task"
    assert_success
    assert_output "sleeping"
}

@test "stderr output is printed" {
    run --separate-stderr "${shell}" "${BOOMPATH}" --config config.json --exec stderr
    assert_success
    assert_output ""
}

@test "both stdout and stderr are printed" {
    run --separate-stderr "${shell}" "${BOOMPATH}" --config config.json --exec "stdout-stderr"
    assert_success
    assert_output "stdout"
    [ "${stderr}" = "stderr" ]
}

@test "exit code is preserved" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "exit-code"
    assert_failure
    [ "${status}" = "123" ]
}

@test "continues when first command failing" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "pipe-concat-fail-first"
    assert_failure
    assert_output "yeah"
}

@test "continues when second command failing" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "pipe-concat-fail-second"
    assert_failure
    assert_output "yeah"
}

@test "and operator stops on failure" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "and-concat-fail"
    assert_failure
    refute_output
}

@test "or operator continues on failure" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "or-concat-fail"
    assert_failure
    refute_output
}

@test "handles long output" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "long-output"
    assert_success
    assert_line "1"
    assert_line "1000"
}

@test "single and double quotes" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "all-the-quotes"
    assert_success
    assert_output "'single' and \"double\""
}

@test "unicode" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "unicode"
    assert_success
    assert_output "🤘"
}

@test "subgroup requires group" {
    run "${shell}" "${BOOMPATH}" --config config.json --subgroup makes --exec meow
    assert_failure
    assert_output --partial "You cannot specify a subgroup without a group"
}

@test "success with failing env command" {
    run "${shell}" "${BOOMPATH}" --config config.json --exec "env-fail"
    assert_success
    assert_output "yeah"
}
