#!/usr/bin/env bats
# Unit tests for src/scripts/lib/parallel.sh.
# wait(1) only works on children of the calling shell, so the jobs are started
# and waited for inside one `bash -c` per test.
# shellcheck disable=SC2016,SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
}

teardown() {
    common_teardown
}

# Run a snippet with parallel.sh sourced.
run_with_parallel() {
    run --separate-stderr bash -c "source \"$LIB_DIR/parallel.sh\"; $1"
}

@test "parallel.sh also loads run.sh" {
    run_with_parallel 'declare -F ensure_temp_dir run_script parallel_wait_pids'
    assert_success
}

@test "parallel_run_best_effort runs the script in the background and prints its pid" {
    run_with_parallel '
        parallel_run_best_effort "$FIXTURES_DIR/record-args.sh" >"$SANDBOX/pid"
        pid="$(cat "$SANDBOX/pid")"
        [[ "$pid" =~ ^[0-9]+$ ]] || exit 9
        wait "$pid"'
    assert_success
    assert_stub_calls "record-args "
}

@test "parallel_run_best_effort hides the script's failure" {
    run_with_parallel '
        export FIXTURE_EXIT=4
        parallel_run_best_effort "$FIXTURES_DIR/record-args.sh" >"$SANDBOX/pid"
        wait "$(cat "$SANDBOX/pid")"'
    assert_success
}

@test "parallel_run_best_effort creates TEMP_DIR" {
    export TEMP_DIR="$SANDBOX/parallel-tmp"
    run_with_parallel '
        parallel_run_best_effort "$FIXTURES_DIR/record-args.sh" >"$SANDBOX/pid"
        wait "$(cat "$SANDBOX/pid")"'
    assert_success
    assert_dir_exists "$SANDBOX/parallel-tmp"
}

@test "parallel_wait_pids succeeds when every job succeeds" {
    run_with_parallel '
        bash -c "exit 0" & p1=$!
        bash -c "exit 0" & p2=$!
        parallel_wait_pids 0 "jobs" "$p1" "$p2"
        echo done'
    assert_success
    assert_output "done"
}

@test "parallel_wait_pids exits 1 with an ERROR for a failed job in strict mode" {
    run_with_parallel '
        bash -c "exit 3" & p1=$!
        parallel_wait_pids 0 "repo setup" "$p1"
        echo "not reached"'
    assert_failure 1
    assert_output ""
    # shellcheck disable=SC2154 # $stderr is set by run --separate-stderr
    [[ "$stderr" =~ ^ERROR:\ repo\ setup\ \(pid\ [0-9]+\)\ failed$ ]]
}

@test "parallel_wait_pids_best_effort warns about a failed job and keeps waiting" {
    run_with_parallel '
        bash -c "exit 3" & p1=$!
        bash -c "sleep 0; touch \"$SANDBOX/second-done\"" & p2=$!
        parallel_wait_pids_best_effort "async tasks" "$p1" "$p2"
        [[ -f "$SANDBOX/second-done" ]] && echo done'
    assert_success
    assert_output "done"
    [[ "$stderr" =~ ^WARNING:\ async\ tasks\ \(pid\ [0-9]+\)\ failed\ \(continuing\)$ ]]
}
