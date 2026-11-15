#!/bin/bash
# Fixture script: records "record-args <args>" in $STUB_CALL_LOG and exits
# with $FIXTURE_EXIT (default 0).
printf 'record-args %s\n' "$*" >>"${STUB_CALL_LOG:-/dev/null}"
exit "${FIXTURE_EXIT:-0}"
